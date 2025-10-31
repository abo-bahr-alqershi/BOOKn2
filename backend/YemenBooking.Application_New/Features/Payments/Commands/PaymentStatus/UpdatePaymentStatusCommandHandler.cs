using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Payments;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Events;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Notifications;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Application.Features.Payments.Commands.PaymentEvents;

namespace YemenBooking.Application.Features.Payments.Commands.PaymentStatus;

/// <summary>
/// مُعالج أمر تحديث حالة الدفع
/// Payment status update command handler
/// 
/// يقوم بتحديث حالة الدفع ويشمل:
/// - التحقق من صحة البيانات المدخلة
/// - التحقق من وجود الدفع
/// - التحقق من صلاحيات المستخدم
/// - التحقق من قواعد الأعمال
/// - التحقق من انتقال الحالة
/// - تحديث الحالة
/// - إنشاء حدث التحديث
/// 
/// Updates payment status and includes:
/// - Input data validation
/// - Payment existence validation
/// - User authorization validation
/// - Business rules validation
/// - State transition validation
/// - Status update
/// - Update event creation
/// </summary>
public class UpdatePaymentStatusCommandHandler : IRequestHandler<UpdatePaymentStatusCommand, ResultDto<bool>>
{
    private readonly IPaymentRepository _paymentRepository;
    private readonly IBookingRepository _bookingRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IValidationService _validationService;
    private readonly IAuditService _auditService;
    private readonly INotificationService _notificationService;
    private readonly IEventPublisher _eventPublisher;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<UpdatePaymentStatusCommandHandler> _logger;
    private readonly IFinancialAccountingService _financialAccountingService;
    private readonly IUnitOfWork _unitOfWork;

    public UpdatePaymentStatusCommandHandler(
        IPaymentRepository paymentRepository,
        IBookingRepository bookingRepository,
        IUnitRepository unitRepository,
        IPropertyRepository propertyRepository,
        IValidationService validationService,
        IAuditService auditService,
        INotificationService notificationService,
        IEventPublisher eventPublisher,
        ICurrentUserService currentUserService,
        ILogger<UpdatePaymentStatusCommandHandler> logger,
        IFinancialAccountingService financialAccountingService,
        IUnitOfWork unitOfWork)
    {
        _paymentRepository = paymentRepository;
        _bookingRepository = bookingRepository;
        _unitRepository = unitRepository;
        _propertyRepository = propertyRepository;
        _validationService = validationService;
        _auditService = auditService;
        _notificationService = notificationService;
        _eventPublisher = eventPublisher;
        _currentUserService = currentUserService;
        _logger = logger;
        _financialAccountingService = financialAccountingService;
        _unitOfWork = unitOfWork;
    }

    /// <summary>
    /// معالجة أمر تحديث حالة الدفع
    /// Handle payment status update command
    /// </summary>
    /// <param name="request">طلب تحديث حالة الدفع / Payment status update request</param>
    /// <param name="cancellationToken">رمز الإلغاء / Cancellation token</param>
    /// <returns>نتيجة العملية / Operation result</returns>
    public async Task<ResultDto<bool>> Handle(UpdatePaymentStatusCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء معالجة أمر تحديث حالة الدفع / Starting update payment status for payment: {PaymentId}", request.PaymentId);

            // الخطوة 1: التحقق من صحة البيانات المدخلة
            // Step 1: Input data validation
            var inputValidationResult = await ValidateInputAsync(request, cancellationToken);
            if (!inputValidationResult.Success)
            {
                _logger.LogWarning("فشل التحقق من صحة البيانات المدخلة / Input validation failed: {Errors}", string.Join(", ", inputValidationResult.Errors));
                return ResultDto<bool>.Failed(inputValidationResult.Errors);
            }

            // الخطوة 2: التحقق من وجود الدفعة والحجز
            // Step 2: Payment and booking existence validation
            var payment = await _paymentRepository.GetByIdAsync(request.PaymentId, cancellationToken);
            if (payment == null)
            {
                _logger.LogWarning("الدفعة غير موجودة / Payment not found: {PaymentId}", request.PaymentId);
                return ResultDto<bool>.Failed("الدفعة غير موجودة / Payment not found");
            }

            var booking = await _bookingRepository.GetByIdAsync(payment.BookingId, cancellationToken);
            if (booking == null)
            {
                _logger.LogWarning("الحجز غير موجود / BookingDto not found: {BookingId}", payment.BookingId);
                return ResultDto<bool>.Failed("الحجز غير موجود / BookingDto not found");
            }

            // التحقق من تطابق العملة بين الدفعة والحجز
            if (!string.Equals(payment.Amount.Currency, booking.TotalPrice.Currency, StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning("عدم تطابق عملة الدفعة ({PaymentCurrency}) مع عملة الحجز ({BookingCurrency})", payment.Amount.Currency, booking.TotalPrice.Currency);
                return ResultDto<bool>.Failed($"عملة الدفعة ({payment.Amount.Currency}) لا تطابق عملة الحجز ({booking.TotalPrice.Currency})");
            }

            // الخطوة 3: التحقق من صلاحيات المستخدم
            // Step 3: User authorization validation
            var authorizationResult = await ValidateAuthorizationAsync(payment, booking, cancellationToken);
            if (!authorizationResult.Success)
            {
                _logger.LogWarning("فشل التحقق من الصلاحيات للمستخدم / Authorization failed for user: {UserId}", _currentUserService.UserId);
                return ResultDto<bool>.Failed(authorizationResult.Errors);
            }

            // الخطوة 4: التحقق من قواعد الأعمال
            // Step 4: Business rules validation
            var businessRulesResult = await ValidateBusinessRulesAsync(payment, request, cancellationToken);
            if (!businessRulesResult.Success)
            {
                _logger.LogWarning("فشل التحقق من قواعد الأعمال / Business rules validation failed: {Errors}", string.Join(", ", businessRulesResult.Errors));
                return ResultDto<bool>.Failed(businessRulesResult.Errors);
            }

            // الخطوة 5: التحقق من انتقال الحالة
            // Step 5: State transition validation
            var stateTransitionResult = await ValidateStateTransitionAsync(payment, request.NewStatus, cancellationToken);
            if (!stateTransitionResult.Success)
            {
                _logger.LogWarning("فشل التحقق من انتقال الحالة / State transition validation failed: {Errors}", string.Join(", ", stateTransitionResult.Errors));
                return ResultDto<bool>.Failed(stateTransitionResult.Errors);
            }

            // الخطوة 6-7: منطق خاص لحالة مرفوض ضمن ترانزاكشن مع قيد عكسي عند الحاجة
            if (request.NewStatus == YemenBooking.Core.Enums.PaymentStatus.Rejected)
            {
                await _unitOfWork.ExecuteInTransactionAsync(async () =>
                {
                    var previousStatus = payment.Status;
                    var updateResult = await UpdatePaymentStatusAsync(payment, request.NewStatus, cancellationToken);
                    if (!updateResult.Success)
                    {
                        _logger.LogError("فشل في تحديث حالة الدفعة / Update payment status failed: {Errors}", string.Join(", ", updateResult.Errors));
                        throw new InvalidOperationException("FAILED_TO_UPDATE_PAYMENT_STATUS");
                    }

                    await _unitOfWork.SaveChangesAsync(cancellationToken);

                    if (previousStatus == YemenBooking.Core.Enums.PaymentStatus.Successful)
                    {
                        var tx = await _financialAccountingService.RecordRefundTransactionAsync(
                            payment.BookingId,
                            payment.Amount.Amount,
                            "رفض دفعة",
                            _currentUserService.UserId);
                        if (tx == null)
                            throw new InvalidOperationException("FAILED_TO_RECORD_REJECTED_PAYMENT_TX");
                    }

                    await UpdateBookingStatusIfNeededAsync(payment, cancellationToken);
                }, cancellationToken);
            }
            else
            {
                var updateResult = await UpdatePaymentStatusAsync(payment, request.NewStatus, cancellationToken);
                if (!updateResult.Success)
                {
                    _logger.LogError("فشل في تحديث حالة الدفعة / Update payment status failed: {Errors}", string.Join(", ", updateResult.Errors));
                    return ResultDto<bool>.Failed(updateResult.Errors);
                }

                await UpdateBookingStatusIfNeededAsync(payment, cancellationToken);
            }

            // الخطوة 8: تسجيل العملية ونشر الأحداث
            // Step 8: Audit logging and event publishing
            await LogAuditAndPublishEventsAsync(payment, booking, request.NewStatus, cancellationToken);

            _logger.LogInformation("تم تحديث حالة الدفعة بنجاح / Payment status updated successfully: {PaymentId}", payment.Id);
            return ResultDto<bool>.Succeeded(true, "تم تحديث حالة الدفعة بنجاح / Payment status updated successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في معالجة أمر تحديث حالة الدفع / Error processing update payment status command: {PaymentId}", request.PaymentId);
            return ResultDto<bool>.Failed("حدث خطأ أثناء تحديث حالة الدفعة / An error occurred while updating payment status");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate input data
    /// </summary>
    private async Task<ResultDto<bool>> ValidateInputAsync(UpdatePaymentStatusCommand request, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        // التحقق من معرف الدفعة
        // Validate payment ID
        if (request.PaymentId == Guid.Empty)
        {
            errors.Add("معرف الدفعة مطلوب / Payment ID is required");
        }

        // التحقق من الحالة الجديدة
        // Validate new status
        if (!Enum.IsDefined(typeof(YemenBooking.Core.Enums.PaymentStatus), request.NewStatus))
        {
            errors.Add("الحالة الجديدة غير صحيحة / Invalid new status");
        }

        // التحقق من صحة البيانات باستخدام خدمة التحقق
        // Validate data using validation service
        var validationResult = await _validationService.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            errors.AddRange(validationResult.Errors.Select(e => e.Message));
        }

        return errors.Any() ? ResultDto<bool>.Failed(errors) : ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// التحقق من صلاحيات المستخدم
    /// Validate user authorization
    /// </summary>
    private async Task<ResultDto<bool>> ValidateAuthorizationAsync(Payment payment, YemenBooking.Core.Entities.Booking booking, CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var currentUserId = _currentUserService.UserId;
        var userRoles = _currentUserService.UserRoles;

        // المدير لديه صلاحية كاملة
        if (userRoles.Contains("Admin"))
        {
            return ResultDto<bool>.Succeeded(true);
        }

        // مالك الكيان
        var unit = await _unitRepository.GetByIdAsync(booking.UnitId, cancellationToken);
        if (unit != null)
        {
            var property = await _propertyRepository.GetByIdAsync(unit.PropertyId, cancellationToken);
            if (property != null && property.OwnerId == currentUserId)
                return ResultDto<bool>.Succeeded(true);
        }

        // الموظف المخول
        if (_currentUserService.Role != "Admin" && _currentUserService.Role != "Staff")
        {
            errors.Add("ليس لديك الصلاحية لتحديث حالة هذه الدفعة / You do not have permission to update this payment status");
        }

        if (_currentUserService.Role != "Admin" && !_currentUserService.IsStaffInProperty(unit?.PropertyId ?? Guid.Empty))
        {
            errors.Add("لست موظفًا في هذا الكيان / You are not a staff member of this property");
        }

        return errors.Any()
            ? ResultDto<bool>.Failed(errors)
            : ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// التحقق من قواعد الأعمال
    /// Validate business rules
    /// </summary>
    private async Task<ResultDto<bool>> ValidateBusinessRulesAsync(Payment payment, UpdatePaymentStatusCommand request, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        // التحقق من أن الحالة الجديدة مختلفة عن الحالة الحالية
        // Check that new status is different from current status
        if (payment.Status == request.NewStatus)
        {
            errors.Add("الحالة الجديدة يجب أن تكون مختلفة عن الحالة الحالية / New status must be different from current status");
        }

        // قواعد إضافية للتحقق من صحة البيانات
        // Additional business rules validation
        if (request.NewStatus == YemenBooking.Core.Enums.PaymentStatus.Refunded && request.RefundRecord == null)
        {
            errors.Add("لا يمكن تعيين الحالة إلى مستردة بدون سجل استرداد / Cannot set status to refunded without refund record");
        }

        return errors.Any() ? ResultDto<bool>.Failed(errors) : ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// التحقق من صحة انتقال الحالة
    /// Validate state transition
    /// </summary>
    private async Task<ResultDto<bool>> ValidateStateTransitionAsync(Payment payment, YemenBooking.Core.Enums.PaymentStatus newStatus, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        // التحقق من الانتقالات المسموح بها بناءً على الحالة الحالية
        // Check allowed transitions based on current status
        switch (payment.Status)
        {
            case YemenBooking.Core.Enums.PaymentStatus.Pending:
                if (newStatus != YemenBooking.Core.Enums.PaymentStatus.Successful && newStatus != YemenBooking.Core.Enums.PaymentStatus.Failed && newStatus != YemenBooking.Core.Enums.PaymentStatus.Voided && newStatus != YemenBooking.Core.Enums.PaymentStatus.Rejected)
                {
                    errors.Add($"لا يمكن الانتقال من الحالة {payment.Status} إلى {newStatus} / Cannot transition from {payment.Status} to {newStatus}");
                }
                break;

            case YemenBooking.Core.Enums.PaymentStatus.Successful:
                if (newStatus != YemenBooking.Core.Enums.PaymentStatus.Refunded && newStatus != YemenBooking.Core.Enums.PaymentStatus.PartiallyRefunded)
                {
                    errors.Add($"لا يمكن الانتقال من الحالة {payment.Status} إلى {newStatus} / Cannot transition from {payment.Status} to {newStatus}");
                }
                break;

            case YemenBooking.Core.Enums.PaymentStatus.Failed:
            case YemenBooking.Core.Enums.PaymentStatus.Voided:
            case YemenBooking.Core.Enums.PaymentStatus.Rejected:
            case YemenBooking.Core.Enums.PaymentStatus.PartiallyRefunded:
                errors.Add($"لا يمكن تغيير الحالة بعد الوصول إلى {payment.Status} / Cannot change status after reaching {payment.Status}");
                break;

            default:
                break;
        }

        return errors.Any() ? ResultDto<bool>.Failed(errors) : ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// تحديث حالة الدفع
    /// Update payment status
    /// </summary>
    private async Task<ResultDto<bool>> UpdatePaymentStatusAsync(Payment payment, YemenBooking.Core.Enums.PaymentStatus newStatus, CancellationToken cancellationToken)
    {
        try
        {
            // تحديث الحالة
            // Update status
            payment.Status = newStatus;
            payment.UpdatedAt = DateTime.UtcNow;

            // تحديث تاريخ المعالجة إذا تم تعيين الحالة إلى ناجحة
            // Update processed date if status is set to successful
            if (newStatus == YemenBooking.Core.Enums.PaymentStatus.Successful && payment.PaymentDate == default)
            {
                payment.PaymentDate = DateTime.UtcNow;
            }

            // حفظ التغييرات في قاعدة البيانات
            // Save changes to database
            await _paymentRepository.UpdateAsync(payment, cancellationToken);

            return ResultDto<bool>.Succeeded(true);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في تحديث حالة الدفعة / Error updating payment status: {PaymentId}", payment.Id);
            return ResultDto<bool>.Failed("حدث خطأ أثناء تحديث حالة الدفعة / An error occurred while updating payment status");
        }
    }

    /// <summary>
    /// تحديث حالة الحجز إذا لزم الأمر
    /// Update booking status if needed
    /// </summary>
    private async Task UpdateBookingStatusIfNeededAsync(Payment payment, CancellationToken cancellationToken)
    {
        // تحديث حالة الحجز بناءً على حالة الدفعة
        // Update booking status based on payment status
        var booking = await _bookingRepository.GetByIdAsync(payment.BookingId, cancellationToken);
        if (booking == null) return;

        var totalPaid = await _paymentRepository.GetTotalPaidAmountAsync(booking.Id, cancellationToken);

        if (payment.Status == YemenBooking.Core.Enums.PaymentStatus.Successful)
        {
            if (totalPaid >= booking.TotalPrice.Amount)
            {
                booking.Status = BookingStatus.Confirmed;
            }
            else
            {
                booking.Status = BookingStatus.Pending;
            }
        }
        else if (payment.Status == YemenBooking.Core.Enums.PaymentStatus.Refunded || payment.Status == YemenBooking.Core.Enums.PaymentStatus.PartiallyRefunded)
        {
            if (totalPaid < booking.TotalPrice.Amount)
            {
                booking.Status = BookingStatus.Pending;
            }
        }
        else if (payment.Status == YemenBooking.Core.Enums.PaymentStatus.Failed || payment.Status == YemenBooking.Core.Enums.PaymentStatus.Voided || payment.Status == YemenBooking.Core.Enums.PaymentStatus.Rejected)
        {
            booking.Status = BookingStatus.Pending;
        }

        booking.UpdatedAt = DateTime.UtcNow;
        await _bookingRepository.UpdateAsync(booking, cancellationToken);
    }

    /// <summary>
    /// تسجيل العملية ونشر الأحداث
    /// Log audit and publish events
    /// </summary>
    private async Task LogAuditAndPublishEventsAsync(Payment payment, YemenBooking.Core.Entities.Booking booking, YemenBooking.Core.Enums.PaymentStatus newStatus, CancellationToken cancellationToken)
    {
        // تسجيل العملية
        // Audit logging
        var notes = $"Payment status updated to {newStatus} for booking {booking.Id} by {_currentUserService.Username} (ID={_currentUserService.UserId})";
        await _auditService.LogAuditAsync(
            entityType: "Payment",
            entityId: payment.Id,
            action: YemenBooking.Core.Entities.AuditAction.UPDATE,
            oldValues: null,
            newValues: System.Text.Json.JsonSerializer.Serialize(new { NewStatus = newStatus, BookingId = booking.Id }),
            performedBy: _currentUserService.UserId,
            notes: notes,
            cancellationToken: cancellationToken);

        // نشر حدث تحديث حالة الدفعة
        // Publish payment status updated event
        await _eventPublisher.PublishAsync(new PaymentStatusUpdatedEvent
        {
            PaymentId = payment.Id,
            BookingId = booking.Id,
            PreviousStatus = payment.Status,
            NewStatus = newStatus,
            UpdatedAt = DateTime.UtcNow,
            UpdatedByUserId = _currentUserService.UserId,
            UpdateReason = null,
            Amount = payment.Amount.Amount,
            TransactionId = payment.TransactionId,
            Notes = null,
            EventId = Guid.NewGuid(),
            OccurredOn = DateTime.UtcNow,
            EventType = nameof(PaymentStatusUpdatedEvent),
            Version = 1,
            UserId = null,
            CorrelationId = booking.Id.ToString()
        }, cancellationToken);

        // إرسال إشعار للضيف إذا لزم الأمر
        // Send notification to guest if needed
        if (newStatus == YemenBooking.Core.Enums.PaymentStatus.Successful || newStatus == YemenBooking.Core.Enums.PaymentStatus.Failed || newStatus == YemenBooking.Core.Enums.PaymentStatus.Refunded)
        {
            var notificationType = newStatus == YemenBooking.Core.Enums.PaymentStatus.Successful ? NotificationType.PaymentProcessed :
                                   newStatus == YemenBooking.Core.Enums.PaymentStatus.Failed ? NotificationType.PaymentFailed :
                                   NotificationType.RefundProcessed;

            var title = newStatus == YemenBooking.Core.Enums.PaymentStatus.Successful ? "تم معالجة الدفع / Payment Processed" :
                        newStatus == YemenBooking.Core.Enums.PaymentStatus.Failed ? "فشل الدفع / Payment Failed" :
                        "تم معالجة الاسترداد / Refund Processed";

            var message = newStatus == YemenBooking.Core.Enums.PaymentStatus.Successful ? $"تم معالجة دفعتك بمبلغ {payment.Amount.Amount} {payment.Amount.Currency} بنجاح / Your payment of {payment.Amount.Amount} {payment.Amount.Currency} has been processed successfully" :
                          newStatus == YemenBooking.Core.Enums.PaymentStatus.Failed ? $"فشلت عملية الدفع بمبلغ {payment.Amount.Amount} {payment.Amount.Currency} / Your payment of {payment.Amount.Amount} {payment.Amount.Currency} has failed" :
                          $"تم معالجة استرداد بمبلغ {payment.Amount.Amount} {payment.Amount.Currency} بنجاح / Your refund of {payment.Amount.Amount} {payment.Amount.Currency} has been processed successfully";

            await _notificationService.SendAsync(new NotificationRequest
            {
                UserId = booking.UserId,
                Type = notificationType,
                Title = title,
                Message = message,
                Data = new { PaymentId = payment.Id, BookingId = booking.Id }
            }, cancellationToken);
        }
    }
}
