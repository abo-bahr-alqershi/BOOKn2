using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Bookings.DTOs;
using YemenBooking.Application.Features.Payments;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Events;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Notifications;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Application.Features.Payments.Services;
using YemenBooking.Application.Features.Payments.Commands.PaymentEvents;
using AutoMapper;


namespace YemenBooking.Application.Features.Payments.Commands.VoidPayment;

/// <summary>
/// مُعالج أمر إبطال الدفع
/// Payment void command handler
/// 
/// يقوم بإبطال الدفع ويشمل:
/// - التحقق من صحة البيانات المدخلة
/// - التحقق من وجود الدفع
/// - التحقق من صلاحيات المستخدم
/// - التحقق من قواعد الأعمال
/// - التحقق من حالة الدفع
/// - إبطال الدفع
/// - إنشاء حدث الإبطال
/// 
/// Voids payment and includes:
/// - Input data validation
/// - Payment existence validation
/// - User authorization validation
/// - Business rules validation
/// - Payment state validation
/// - Payment voiding
/// - Void event creation
/// </summary>
public class VoidPaymentCommandHandler : IRequestHandler<VoidPaymentCommand, ResultDto<bool>>
{
    private readonly IPaymentRepository _paymentRepository;
    private readonly IBookingRepository _bookingRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly YemenBooking.Application.Features.Payments.Services.IPaymentGatewayService _paymentGatewayService;
    private readonly IValidationService _validationService;
    private readonly IAuditService _auditService;
    private readonly INotificationService _notificationService;
    private readonly IEventPublisher _eventPublisher;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<VoidPaymentCommandHandler> _logger;
    private readonly IFinancialAccountingService _financialAccountingService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;

    public VoidPaymentCommandHandler(
        IPaymentRepository paymentRepository,
        IBookingRepository bookingRepository,
        IUnitRepository unitRepository,
        IPropertyRepository propertyRepository,
        YemenBooking.Application.Features.Payments.Services.IPaymentGatewayService paymentGatewayService,
        IValidationService validationService,
        IAuditService auditService,
        INotificationService notificationService,
        IEventPublisher eventPublisher,
        ICurrentUserService currentUserService,
        ILogger<VoidPaymentCommandHandler> logger,
        IFinancialAccountingService financialAccountingService,
        IUnitOfWork unitOfWork,
        IMapper mapper)
    {
        _paymentRepository = paymentRepository;
        _bookingRepository = bookingRepository;
        _unitRepository = unitRepository;
        _propertyRepository = propertyRepository;
        _paymentGatewayService = paymentGatewayService;
        _validationService = validationService;
        _auditService = auditService;
        _notificationService = notificationService;
        _eventPublisher = eventPublisher;
        _currentUserService = currentUserService;
        _logger = logger;
        _financialAccountingService = financialAccountingService;
        _unitOfWork = unitOfWork;
        _mapper = mapper;
    }

    /// <summary>
    /// معالجة أمر إبطال الدفع
    /// Handle payment void command
    /// </summary>
    /// <param name="request">طلب إبطال الدفع / Payment void request</param>
    /// <param name="cancellationToken">رمز الإلغاء / Cancellation token</param>
    /// <returns>نتيجة العملية / Operation result</returns>
    public async Task<ResultDto<bool>> Handle(VoidPaymentCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء معالجة أمر إبطال الدفع / Starting void payment processing for payment: {PaymentId}", request.PaymentId);

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

            var bookingEntity = await _bookingRepository.GetByIdAsync(payment.BookingId, cancellationToken);
            if (bookingEntity == null)
            {
                _logger.LogWarning("الحجز غير موجود / BookingDto not found: {BookingId}", payment.BookingId);
                return ResultDto<bool>.Failed("الحجز غير موجود / BookingDto not found");
            }

            // Map Booking entity to BookingDto
            var booking = _mapper.Map<BookingDto>(bookingEntity);

            // Verify currency consistency between payment and booking
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
            var businessRulesResult = await ValidateBusinessRulesAsync(payment, cancellationToken);
            if (!businessRulesResult.Success)
            {
                _logger.LogWarning("فشل التحقق من قواعد الأعمال / Business rules validation failed: {Errors}", string.Join(", ", businessRulesResult.Errors));
                return ResultDto<bool>.Failed(businessRulesResult.Errors);
            }

            // الخطوة 5: التحقق من حالة الدفعة
            // Step 5: Payment state validation
            var stateValidationResult = await ValidatePaymentStateAsync(payment, cancellationToken);
            if (!stateValidationResult.Success)
            {
                _logger.LogWarning("فشل التحقق من حالة الدفعة / Payment state validation failed: {Errors}", string.Join(", ", stateValidationResult.Errors));
                return ResultDto<bool>.Failed(stateValidationResult.Errors);
            }

            // الخطوة 6: معالجة الإبطال
            // Step 6: Process void
            var voidResult = await ProcessVoidAsync(payment, cancellationToken);
            if (!voidResult.Success)
            {
                _logger.LogError("فشل في معالجة إبطال الدفعة / Void processing failed: {Errors}", string.Join(", ", voidResult.Errors));
                return ResultDto<bool>.Failed(voidResult.Errors);
            }

            // الخطوة 7: تحديث حالة الحجز إذا لزم الأمر
            // Step 7: Update booking status if needed
            await UpdateBookingStatusIfNeededAsync(payment, cancellationToken);

            // الخطوة 8: تسجيل العملية ونشر الأحداث
            // Step 8: Audit logging and event publishing
            await LogAuditAndPublishEventsAsync(payment, booking, cancellationToken);

            _logger.LogInformation("تم إبطال الدفعة بنجاح / Payment voided successfully: {PaymentId}", payment.Id);
            return ResultDto<bool>.Succeeded(true, "تم إبطال الدفعة بنجاح / Payment voided successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في معالجة أمر إبطال الدفع / Error processing void payment command: {PaymentId}", request.PaymentId);
            return ResultDto<bool>.Failed("حدث خطأ أثناء إبطال الدفعة / An error occurred while voiding payment");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate input data
    /// </summary>
    private async Task<ResultDto<bool>> ValidateInputAsync(VoidPaymentCommand request, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        // التحقق من معرف الدفعة
        // Validate payment ID
        if (request.PaymentId == Guid.Empty)
        {
            errors.Add("معرف الدفعة مطلوب / Payment ID is required");
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
    private async Task<ResultDto<bool>> ValidateAuthorizationAsync(Payment payment, BookingDto booking, CancellationToken cancellationToken)
    {
        var userRoles = _currentUserService.UserRoles;
        // Only Admin can void payments. Owners are not permitted to perform void operations.
        if (userRoles.Contains("Admin"))
        {
            return ResultDto<bool>.Succeeded(true);
        }

        return ResultDto<bool>.Failed("غير مسموح لغير المدير بإبطال الدفعات / Only Admin can void payments");
    }

    /// <summary>
    /// التحقق من قواعد الأعمال
    /// Validate business rules
    /// </summary>
    private async Task<ResultDto<bool>> ValidateBusinessRulesAsync(Payment payment, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        // التحقق من عدم وجود إبطال سابق لنفس الدفعة
        // Check for previous void for the same payment
        if (payment.Status == Core.Enums.PaymentStatus.Voided)
        {
            errors.Add("الدفعة تم إبطالها مسبقًا / Payment has already been voided");
        }

        // التحقق من أن الدفعة لم يتم استردادها
        // Check that payment has not been refunded
        if (payment.Status == Core.Enums.PaymentStatus.Refunded || payment.Status == Core.Enums.PaymentStatus.PartiallyRefunded)
        {
            errors.Add("لا يمكن إبطال دفعة تم استردادها / Cannot void a refunded payment");
        }

        return errors.Any() ? ResultDto<bool>.Failed(errors) : ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// التحقق من حالة الدفع
    /// Validate payment state
    /// </summary>
    private async Task<ResultDto<bool>> ValidatePaymentStateAsync(Payment payment, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        // التحقق من أن الدفعة في حالة تسمح بالإبطال
        // Check that payment is in a state that allows void
        if (payment.Status != Core.Enums.PaymentStatus.Pending && payment.Status != Core.Enums.PaymentStatus.Successful)
        {
            errors.Add($"لا يمكن إبطال الدفعة في الحالة الحالية: {payment.Status} / Cannot void payment in current status: {payment.Status}");
        }

        return errors.Any() ? ResultDto<bool>.Failed(errors) : ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// إبطال الدفع
    /// Void payment
    /// </summary>
    private async Task<ResultDto<bool>> ProcessVoidAsync(Payment payment, CancellationToken cancellationToken)
    {
        try
        {
            // محاولة إبطال الدفعة عبر بوابة الدفع إذا كانت ناجحة
            // Attempt to void payment through gateway if it was successful
            if (payment.Status == YemenBooking.Core.Enums.PaymentStatus.Successful)
            {
                var gatewayResult = await _paymentGatewayService.CancelTransactionAsync(payment.TransactionId, cancellationToken);
                if (!gatewayResult)
                {
                    return ResultDto<bool>.Failed("فشل في إبطال الدفعة / Void payment failed");
                }
            }

            // تنفيذ تحديث حالة الدفعة والقيد المحاسبي ضمن ترانزاكشن واحدة
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                // تحديث حالة الدفعة إلى مبطلة
                payment.Status = YemenBooking.Core.Enums.PaymentStatus.Voided;
                payment.UpdatedAt = DateTime.UtcNow;

                await _paymentRepository.UpdateAsync(payment, cancellationToken);

                // تسجيل القيد المحاسبي: عكس قيد الدفعة الأصلي
                var booking = await _bookingRepository.GetByIdAsync(payment.BookingId, cancellationToken);
                if (booking != null)
                {
                    var tx = await _financialAccountingService.RecordRefundTransactionAsync(
                        payment.BookingId,
                        payment.Amount.Amount,
                        "إلغاء دفعة",
                        _currentUserService.UserId);
                    if (tx == null)
                        throw new InvalidOperationException("FAILED_TO_RECORD_VOID_PAYMENT_TX");
                }
            }, cancellationToken);

            return ResultDto<bool>.Succeeded(true);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في معالجة إبطال الدفعة / Error processing void for payment: {PaymentId}", payment.Id);
            return ResultDto<bool>.Failed("حدث خطأ أثناء إبطال الدفعة / An error occurred while voiding payment");
        }
    }

    /// <summary>
    /// تحديث حالة الحجز بعد إبطال الدفع
    /// Update booking status after payment void
    /// </summary>
    private async Task UpdateBookingStatusIfNeededAsync(Payment payment, CancellationToken cancellationToken)
    {
        // تحديث حالة الحجز بناءً على حالة الدفعة
        // Update booking status based on payment status
        var booking = await _bookingRepository.GetByIdAsync(payment.BookingId, cancellationToken);
        if (booking == null) return;

        var totalPaid = await _paymentRepository.GetTotalPaidAmountAsync(booking.Id, cancellationToken);

        if (totalPaid < booking.TotalPrice.Amount)
        {
            booking.Status = BookingStatus.Pending;
            booking.UpdatedAt = DateTime.UtcNow;
            await _bookingRepository.UpdateAsync(booking, cancellationToken);
        }
    }

    /// <summary>
    /// تسجيل العملية ونشر الأحداث
    /// Log audit and publish events
    /// </summary>
    private async Task LogAuditAndPublishEventsAsync(Payment payment, BookingDto booking, CancellationToken cancellationToken)
    {
        // تسجيل العملية
        // Audit logging
        var notes = $"Payment voided for booking {booking.Id} by {_currentUserService.Username} (ID={_currentUserService.UserId})";
        await _auditService.LogAuditAsync(
            entityType: "Payment",
            entityId: payment.Id,
            action: AuditAction.UPDATE,
            oldValues: null,
            newValues: System.Text.Json.JsonSerializer.Serialize(new { Voided = true, BookingId = booking.Id }),
            performedBy: _currentUserService.UserId,
            notes: notes,
            cancellationToken: cancellationToken);

        // نشر حدث إبطال الدفعة
        // Publish payment voided event
        await _eventPublisher.PublishAsync(new YemenBooking.Application.Features.Payments.Commands.PaymentEvents.PaymentVoidedEvent
        {
            PaymentId = payment.Id,
            BookingId = booking.Id,
            AttemptedAt = DateTime.UtcNow,
            AttemptedAmount = payment.Amount,
            Method = payment.PaymentMethod.ToString(),
            FailureReason = string.Empty,
            ErrorCode = null,
            UserId = _currentUserService.UserId
        }, cancellationToken);

        // إرسال إشعار للضيف
        // Send notification to guest
        await _notificationService.SendAsync(new NotificationRequest
        {
            UserId = booking.UserId,
            Type = NotificationType.PaymentVoided,
            Title = "تم إبطال الدفع / Payment Voided",
            Message = $"تم إبطال دفعتك بمبلغ {payment.Amount.Amount} {payment.Amount.Currency} / Your payment of {payment.Amount.Amount} {payment.Amount.Currency} has been voided",
            Data = new { PaymentId = payment.Id, BookingId = booking.Id }
        }, cancellationToken);
    }
}

