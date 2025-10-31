using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Accounting;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Persistence.Repositories;
using YemenBooking.Core.Notifications;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Notifications.Services;

namespace YemenBooking.Application.Features.Accounting.Commands.Payouts
{
    /// <summary>
    /// معالج أمر تحويل مستحقات الملاك
    /// Process owner payouts command handler
    /// </summary>
    public class ProcessOwnerPayoutsCommandHandler : IRequestHandler<ProcessOwnerPayoutsCommand, ResultDto<ProcessOwnerPayoutsResult>>
    {
        private readonly IFinancialAccountingService _financialAccountingService;
        private readonly IFinancialTransactionRepository _transactionRepository;
        private readonly IUserRepository _userRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly INotificationService _notificationService;
        private readonly IValidationService _validationService;
        private readonly ILogger<ProcessOwnerPayoutsCommandHandler> _logger;
        private readonly IUnitOfWork _unitOfWork;

        public ProcessOwnerPayoutsCommandHandler(
            IFinancialAccountingService financialAccountingService,
            IFinancialTransactionRepository transactionRepository,
            IUserRepository userRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            INotificationService notificationService,
            IValidationService validationService,
            ILogger<ProcessOwnerPayoutsCommandHandler> logger,
            IUnitOfWork unitOfWork)
        {
            _financialAccountingService = financialAccountingService;
            _transactionRepository = transactionRepository;
            _userRepository = userRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _notificationService = notificationService;
            _validationService = validationService;
            _logger = logger;
            _unitOfWork = unitOfWork;
        }

        public async Task<ResultDto<ProcessOwnerPayoutsResult>> Handle(
            ProcessOwnerPayoutsCommand request, 
            CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("بدء معالجة أمر تحويل مستحقات الملاك");

                // التحقق من صحة البيانات المدخلة
                var validation = await _validationService.ValidateAsync(request, cancellationToken);
                if (!validation.IsValid)
                {
                    return ResultDto<ProcessOwnerPayoutsResult>.Failed(
                        validation.Errors.Select(e => e.Message).ToArray());
                }

                // التحقق من الصلاحيات
                if (_currentUserService.Role != "Admin" && 
                    _currentUserService.Role != "Accountant" && 
                    _currentUserService.Role != "Finance")
                {
                    return ResultDto<ProcessOwnerPayoutsResult>.Failed(
                        "ليس لديك الصلاحية لتنفيذ تحويلات الملاك");
                }

                var result = new ProcessOwnerPayoutsResult();

                // الحصول على قائمة الملاك
                var owners = await GetOwnersForPayoutAsync(request.OwnerIds, cancellationToken);

                foreach (var owner in owners)
                {
                    try
                    {
                        // حساب المبلغ المستحق للمالك
                        var payableAmount = await CalculateOwnerPayableAmountAsync(
                            owner.Id, 
                            request.IncludePendingTransactions, 
                            cancellationToken);

                        // التحقق من الحد الأدنى
                        if (payableAmount < request.MinimumAmountThreshold)
                        {
                            _logger.LogInformation(
                                "المالك {OwnerName} لديه مبلغ {Amount} أقل من الحد الأدنى {Threshold}",
                                owner.Name, payableAmount, request.MinimumAmountThreshold);
                            continue;
                        }

                        var payoutDetail = new OwnerPayoutDetail
                        {
                            OwnerId = owner.Id,
                            OwnerName = owner.Name,
                            Amount = payableAmount,
                            Status = "معلق"
                        };

                        if (!request.PreviewOnly)
                        {
                            // تنفيذ التحويل الفعلي
                            var transaction = await ProcessOwnerPayoutAsync(
                                owner, 
                                payableAmount, 
                                request.Notes, 
                                cancellationToken);

                            if (transaction != null)
                            {
                                payoutDetail.TransactionNumber = transaction.TransactionNumber;
                                payoutDetail.Status = "مكتمل";
                                result.PayoutsProcessed++;
                                result.TotalAmountTransferred += payableAmount;

                                // إرسال إشعار للمالك
                                await SendOwnerNotificationAsync(owner, payableAmount, cancellationToken);
                            }
                            else
                            {
                                payoutDetail.Status = "فشل";
                                payoutDetail.ErrorMessage = "فشل في إنشاء معاملة التحويل";
                                result.Errors.Add($"فشل تحويل المالك {owner.Name}");
                            }
                        }
                        else
                        {
                            payoutDetail.Status = "معاينة";
                            result.TotalAmountTransferred += payableAmount;
                        }

                        result.PayoutDetails.Add(payoutDetail);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "خطأ في معالجة تحويل المالك {OwnerId}", owner.Id);
                        result.Errors.Add($"خطأ في معالجة تحويل المالك {owner.Name}: {ex.Message}");

                        result.PayoutDetails.Add(new OwnerPayoutDetail
                        {
                            OwnerId = owner.Id,
                            OwnerName = owner.Name,
                            Status = "خطأ",
                            ErrorMessage = ex.Message
                        });
                    }
                }

                if (!request.PreviewOnly)
                {
                    // حفظ التغييرات
                    await _unitOfWork.SaveChangesAsync(cancellationToken);

                    // تسجيل العملية في سجل التدقيق
                    await _auditService.LogAuditAsync(
                        entityType: "OwnerPayouts",
                        entityId: Guid.NewGuid(),
                        action: AuditAction.CREATE,
                        oldValues: null,
                        newValues: System.Text.Json.JsonSerializer.Serialize(new
                        {
                            PayoutsProcessed = result.PayoutsProcessed,
                            TotalAmount = result.TotalAmountTransferred,
                            OwnerCount = result.PayoutDetails.Count,
                            Notes = request.Notes
                        }),
                        performedBy: _currentUserService.UserId,
                        notes: $"تم معالجة {result.PayoutsProcessed} تحويل بإجمالي {result.TotalAmountTransferred} YER",
                        cancellationToken: cancellationToken);
                }

                _logger.LogInformation(
                    "تمت معالجة تحويلات الملاك: {PayoutsProcessed} تحويل بإجمالي {TotalAmount} YER",
                    result.PayoutsProcessed, result.TotalAmountTransferred);

                var message = request.PreviewOnly 
                    ? $"معاينة: {result.PayoutDetails.Count} تحويل بإجمالي {result.TotalAmountTransferred} YER"
                    : $"تم معالجة {result.PayoutsProcessed} تحويل بإجمالي {result.TotalAmountTransferred} YER";

                return ResultDto<ProcessOwnerPayoutsResult>.Succeeded(result, message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في معالجة أمر تحويلات الملاك");
                return ResultDto<ProcessOwnerPayoutsResult>.Failed(
                    "حدث خطأ أثناء معالجة تحويلات الملاك");
            }
        }

        private async Task<List<User>> GetOwnersForPayoutAsync(
            List<Guid> specificOwnerIds, 
            CancellationToken cancellationToken)
        {
            if (specificOwnerIds != null && specificOwnerIds.Any())
            {
                var owners = new List<User>();
                var allUsers = await _userRepository.GetAllAsync(cancellationToken);
                var properties = await _propertyRepository.GetAllAsync(cancellationToken);
                var ownerIds = properties.Select(p => p.OwnerId).Distinct();
                var ownersList = allUsers.Where(u => ownerIds.Contains(u.Id)).ToList();
                foreach (var owner in ownersList)
                {
                    owners.Add(owner);
                }
                return owners;
            }
            else
            {
                // الحصول على جميع الملاك النشطين
                // الحصول على جميع الملاك النشطين
                var allUsers = await _userRepository.GetAllAsync(cancellationToken);
                var allProperties = await _propertyRepository.GetAllAsync(cancellationToken);
                var allOwnerIds = allProperties.Select(p => p.OwnerId).Distinct();
                return allUsers.Where(u => allOwnerIds.Contains(u.Id)).ToList();
            }
        }

        private async Task<decimal> CalculateOwnerPayableAmountAsync(
            Guid ownerId, 
            bool includePending, 
            CancellationToken cancellationToken)
        {
            // الحصول على جميع المعاملات المستحقة للمالك
            var transactions = await _transactionRepository.GetByUserIdAsync(ownerId);
            
            // فلترة المعاملات حسب الحالة
            var eligibleTransactions = includePending 
                ? transactions.Where(t => t.SecondPartyUserId == ownerId)
                : transactions.Where(t => t.SecondPartyUserId == ownerId && t.IsPosted);

            // حساب الرصيد المستحق
            decimal totalCredit = eligibleTransactions
                .Where(t => t.CreditAccountId != null)
                .Sum(t => t.Amount);

            decimal totalDebit = eligibleTransactions
                .Where(t => t.DebitAccountId != null)
                .Sum(t => t.Amount);

            return totalCredit - totalDebit;
        }

        private async Task<FinancialTransaction> ProcessOwnerPayoutAsync(
            User owner,
            decimal amount,
            string notes,
            CancellationToken cancellationToken)
        {
            try
            {
                // استخدام الخدمة المحاسبية لتسجيل التحويل
                var transaction = await _financialAccountingService.RecordOwnerPayoutAsync(
                    await GetOwnerPrimaryPropertyIdAsync(owner.Id, cancellationToken),
                    owner.Id,
                    amount,
                    notes ?? $"تحويل مستحقات دورية للمالك {owner.Name}",
                    _currentUserService.UserId);

                return transaction;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "فشل في معالجة تحويل المالك {OwnerId}", owner.Id);
                return null;
            }
        }

        private async Task<Guid> GetOwnerPrimaryPropertyIdAsync(
            Guid ownerId, 
            CancellationToken cancellationToken)
        {
            var allProperties = await _propertyRepository.GetAllAsync(cancellationToken);
            var ownerProperties = allProperties.Where(p => p.OwnerId == ownerId).ToList();
            return ownerProperties.FirstOrDefault()?.Id ?? Guid.Empty;
        }

        private async Task SendOwnerNotificationAsync(
            User owner, 
            decimal amount, 
            CancellationToken cancellationToken)
        {
            try
            {
                await _notificationService.SendAsync(new NotificationRequest
                {
                    UserId = owner.Id,
                    Type = NotificationType.PaymentProcessed,
                    Title = "تم تحويل مستحقاتك / Your payment has been processed",
                    Message = $"تم تحويل مبلغ {amount} YER إلى حسابك / Amount of {amount} YER has been transferred to your account",
                    Data = new 
                    { 
                        Amount = amount,
                        Currency = "YER",
                        Date = DateTime.UtcNow
                    }
                }, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل إرسال إشعار للمالك {OwnerId}", owner.Id);
            }
        }
    }
}
