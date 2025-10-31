using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Accounting;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;

namespace YemenBooking.Application.Features.Accounting.Commands.Period
{
    /// <summary>
    /// معالج أمر إقفال الفترة المحاسبية
    /// Close accounting period command handler
    /// </summary>
    public class CloseAccountingPeriodCommandHandler : IRequestHandler<CloseAccountingPeriodCommand, ResultDto<bool>>
    {
        private readonly IFinancialAccountingService _financialAccountingService;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly IValidationService _validationService;
        private readonly ILogger<CloseAccountingPeriodCommandHandler> _logger;
        private readonly IUnitOfWork _unitOfWork;

        public CloseAccountingPeriodCommandHandler(
            IFinancialAccountingService financialAccountingService,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            IValidationService validationService,
            ILogger<CloseAccountingPeriodCommandHandler> logger,
            IUnitOfWork unitOfWork)
        {
            _financialAccountingService = financialAccountingService;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _validationService = validationService;
            _logger = logger;
            _unitOfWork = unitOfWork;
        }

        public async Task<ResultDto<bool>> Handle(CloseAccountingPeriodCommand request, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("بدء معالجة أمر إقفال الفترة المحاسبية {Month}/{Year}", request.Month, request.Year);

                // التحقق من صحة البيانات المدخلة
                var validation = await _validationService.ValidateAsync(request, cancellationToken);
                if (!validation.IsValid)
                {
                    return ResultDto<bool>.Failed(validation.Errors.Select(e => e.Message).ToArray());
                }

                // التحقق من الصلاحيات
                if (_currentUserService.Role != "Admin" && _currentUserService.Role != "Accountant")
                {
                    return ResultDto<bool>.Failed("ليس لديك الصلاحية لإقفال الفترة المحاسبية");
                }

                // التحقق من التاريخ
                if (request.Year < 2020 || request.Year > DateTime.UtcNow.Year)
                {
                    return ResultDto<bool>.Failed("السنة المالية غير صحيحة");
                }

                if (request.Month < 1 || request.Month > 12)
                {
                    return ResultDto<bool>.Failed("الشهر المالي غير صحيح");
                }

                // التحقق من أن الفترة قد انتهت
                var periodEnd = new DateTime(request.Year, request.Month, 1).AddMonths(1);
                if (periodEnd > DateTime.UtcNow && !request.ForceClose)
                {
                    return ResultDto<bool>.Failed("لا يمكن إقفال فترة لم تنته بعد");
                }

                // تنفيذ الإقفال
                var result = await _financialAccountingService.CloseAccountingPeriodAsync(
                    request.Year,
                    request.Month,
                    _currentUserService.UserId);

                if (!result)
                {
                    return ResultDto<bool>.Failed("فشل إقفال الفترة المحاسبية. تحقق من وجود معاملات غير مرحلة");
                }

                // تسجيل العملية في سجل التدقيق
                await _auditService.LogAuditAsync(
                    entityType: "AccountingPeriod",
                    entityId: Guid.NewGuid(),
                    action: AuditAction.CREATE,
                    oldValues: null,
                    newValues: System.Text.Json.JsonSerializer.Serialize(new 
                    { 
                        Year = request.Year,
                        Month = request.Month,
                        Notes = request.Notes,
                        ForceClose = request.ForceClose
                    }),
                    performedBy: _currentUserService.UserId,
                    notes: $"تم إقفال الفترة المحاسبية {request.Month}/{request.Year} بواسطة {_currentUserService.Username}",
                    cancellationToken: cancellationToken);

                await _unitOfWork.SaveChangesAsync(cancellationToken);

                _logger.LogInformation("تم إقفال الفترة المحاسبية {Month}/{Year} بنجاح", request.Month, request.Year);
                return ResultDto<bool>.Succeeded(true, $"تم إقفال الفترة المحاسبية {request.Month}/{request.Year} بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في إقفال الفترة المحاسبية {Month}/{Year}", request.Month, request.Year);
                return ResultDto<bool>.Failed("حدث خطأ أثناء إقفال الفترة المحاسبية");
            }
        }
    }
}
