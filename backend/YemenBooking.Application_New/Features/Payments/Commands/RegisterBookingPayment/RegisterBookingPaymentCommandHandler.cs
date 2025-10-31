using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Events;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Notifications;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Application.Features.Payments.Commands.PaymentEvents;
using YemenBooking.Application.Features.Payments.DTOs;

namespace YemenBooking.Application.Features.Payments.Commands.RegisterBookingPayment;

/// <summary>
/// مُعالج أمر تسجيل دفعة الحجز
/// Handler for registering booking payment command
/// </summary>
public class RegisterBookingPaymentCommandHandler : IRequestHandler<RegisterBookingPaymentCommand, ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>>
{
    private readonly IBookingRepository _bookingRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<RegisterBookingPaymentCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly INotificationService _notificationService;
    private readonly IEventPublisher _eventPublisher;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IFinancialAccountingService _financialAccountingService;
    private readonly ICurrencySettingsService _currencySettingsService;

    public RegisterBookingPaymentCommandHandler(
        IBookingRepository bookingRepository,
        IPaymentRepository paymentRepository,
        IUnitRepository unitRepository,
        IPropertyRepository propertyRepository,
        IAuditService auditService,
        INotificationService notificationService,
        IEventPublisher eventPublisher,
        ICurrentUserService currentUserService,
        ILogger<RegisterBookingPaymentCommandHandler> logger,
        IUnitOfWork unitOfWork,
        IFinancialAccountingService financialAccountingService,
        ICurrencySettingsService currencySettingsService)
    {
        _bookingRepository = bookingRepository;
        _paymentRepository = paymentRepository;
        _unitRepository = unitRepository;
        _propertyRepository = propertyRepository;
        _auditService = auditService;
        _notificationService = notificationService;
        _eventPublisher = eventPublisher;
        _currentUserService = currentUserService;
        _logger = logger;
        _unitOfWork = unitOfWork;
        _financialAccountingService = financialAccountingService;
        _currencySettingsService = currencySettingsService;
    }

    public async Task<ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>> Handle(RegisterBookingPaymentCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء تسجيل دفعة للحجز / Starting payment registration for booking: {BookingId}", request.BookingId);

            // التحقق من صحة البيانات المدخلة
            // Validate input data
            var validationResult = ValidateInput(request);
            if (!validationResult.Success)
            {
                _logger.LogWarning("فشل التحقق من صحة البيانات / Input validation failed: {Errors}", string.Join(", ", validationResult.Errors));
                return ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>.Failed(validationResult.Errors);
            }

            // التحقق من وجود الحجز
            // Check booking existence
            var booking = await _bookingRepository.GetByIdAsync(request.BookingId, cancellationToken);
            if (booking == null)
            {
                _logger.LogWarning("الحجز غير موجود / BookingDto not found: {BookingId}", request.BookingId);
                return ResultDto<PaymentDto>.Failed("الحجز غير موجود / BookingDto not found");
            }

            // التحقق من صلاحيات المستخدم
            // Check user permissions
            var authResult = await ValidateAuthorizationAsync(booking, cancellationToken);
            if (!authResult.Success)
            {
                _logger.LogWarning("فشل التحقق من الصلاحيات للمستخدم / Authorization failed for user: {UserId}", _currentUserService.UserId);
                return ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>.Failed(authResult.Errors);
            }

            // لغير المدير: منع طرق الدفع غير النقدية للمالك
            if (_currentUserService.Role == "Owner" && request.PaymentMethod != PaymentMethodEnum.Cash)
            {
                return ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>.Failed(
                    "غير مسموح لمالك العقار بتسجيل دفعات إلا عن طريق النقد فقط / Owners can only register CASH payments");
            }

            // التحقق من حالة الحجز
            // Check booking status
            var statusResult = ValidateBookingStatus(booking);
            if (!statusResult.Success)
            {
                _logger.LogWarning("حالة الحجز غير مناسبة للدفع / BookingDto status not suitable for payment: {Status}", booking.Status);
                return ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>.Failed(statusResult.Errors);
            }

            // التحقق من المبلغ المدفوع
            // Validate payment amount
            var totalPaid = await _paymentRepository.GetTotalPaidAmountAsync(booking.Id, cancellationToken);
            var remainingAmount = booking.TotalPrice.Amount - totalPaid;
            
            if (request.Amount.Amount <= 0)
            {
                return ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>.Failed("المبلغ يجب أن يكون أكبر من الصفر / Amount must be greater than zero");
            }

            if (decimal.Round(request.Amount.Amount, 2) != request.Amount.Amount)
            {
                return ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>.Failed("عدد المنازل العشرية للمبلغ يجب ألا يتجاوز رقمين / Amount must have at most 2 decimal places");
            }

            if (request.Amount.Amount > remainingAmount)
            {
                return ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>.Failed($"المبلغ المدفوع ({request.Amount.Amount}) يتجاوز المبلغ المتبقي ({remainingAmount}) / Payment amount ({request.Amount.Amount}) exceeds remaining amount ({remainingAmount})");
            }

            // التحقق من تطابق العملة مع عملة الحجز
            // Validate currency matches booking currency
            var paymentCurrency = request.Amount.Currency ?? booking.TotalPrice.Currency;
            if (!string.Equals(paymentCurrency, booking.TotalPrice.Currency, StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning("محاولة دفع بعملة {PaymentCurrency} بينما عملة الحجز هي {BookingCurrency} / Attempted payment with currency {PaymentCurrency} while booking currency is {BookingCurrency}", 
                    paymentCurrency, booking.TotalPrice.Currency);
                return ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>.Failed($"العملة المستخدمة ({paymentCurrency}) يجب أن تكون نفس عملة الحجز ({booking.TotalPrice.Currency}) / Payment currency ({paymentCurrency}) must match booking currency ({booking.TotalPrice.Currency})");
            }

            var currencies = await _currencySettingsService.GetCurrenciesAsync(cancellationToken);
            var isSupported = currencies.Any(c => string.Equals(c.Code, booking.TotalPrice.Currency, StringComparison.OrdinalIgnoreCase));
            if (!isSupported)
            {
                return ResultDto<PaymentDto>.Failed("العملة غير مدعومة في إعدادات النظام / Currency is not supported by system settings");
            }

            // إنشاء سجل الدفعة
            // Create payment record
            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                BookingId = booking.Id,
                Amount = new Money(request.Amount.Amount, booking.TotalPrice.Currency),
                PaymentMethod = request.PaymentMethod,
                TransactionId = string.IsNullOrEmpty(request.TransactionId) 
                    ? $"MANUAL-{DateTime.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid():N}" 
                    : request.TransactionId,
                Status = Core.Enums.PaymentStatus.Successful,
                PaymentDate = request.PaymentDate ?? DateTime.UtcNow,
                ProcessedBy = _currentUserService.UserId,
                ProcessedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            // تنفيذ حفظ الدفعة وتحديث حالة الحجز وتسجيل القيد المحاسبي ضمن ترانزاكشن واحدة
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                await _paymentRepository.AddAsync(payment, cancellationToken);

                // تحديث حالة الحجز إذا لزم الأمر
                var newTotalPaid = totalPaid + request.Amount.Amount;
                if (newTotalPaid >= booking.TotalPrice.Amount)
                {
                    if (booking.Status == BookingStatus.Pending)
                    {
                        booking.Status = BookingStatus.Confirmed;
                        booking.UpdatedAt = DateTime.UtcNow;
                        await _bookingRepository.UpdateAsync(booking, cancellationToken);
                    }
                }

                await _unitOfWork.SaveChangesAsync(cancellationToken);

                var tx = await _financialAccountingService.RecordPaymentTransactionAsync(
                    payment.Id,
                    _currentUserService.UserId);
                if (tx == null)
                    throw new InvalidOperationException("FAILED_TO_RECORD_REGISTER_PAYMENT_TX");
            }, cancellationToken);

            // تسجيل العملية
            // Audit logging
            await LogAuditAsync(payment, booking, cancellationToken);

            // إرسال الإشعارات
            // Send notifications
            await SendNotificationsAsync(payment, booking, cancellationToken);

            // نشر الأحداث
            // Publish events
            await PublishEventsAsync(payment, booking, cancellationToken);

            // إعداد DTO للإرجاع
            // Prepare DTO for return
            var paymentDto = new YemenBooking.Application.Features.Payments.DTOs.PaymentDto
            {
                Id = payment.Id,
                BookingId = payment.BookingId,
                Amount = payment.Amount.Amount,
                AmountMoney = new MoneyDto
                {
                    Amount = payment.Amount.Amount,
                    Currency = payment.Amount.Currency,
                    ExchangeRate = 1
                },
                Method = request.PaymentMethod,
                Currency = payment.Amount.Currency,
                TransactionId = payment.TransactionId,
                Status = payment.Status,
                PaymentDate = payment.PaymentDate,
                ProcessedBy = payment.ProcessedBy,
                ProcessedByName = _currentUserService.Username,
                Notes = request.Notes
            };

            _logger.LogInformation("تم تسجيل الدفعة بنجاح / Payment registered successfully. PaymentId: {PaymentId}, BookingId: {BookingId}", payment.Id, booking.Id);
            
            return ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>.Succeeded(paymentDto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في تسجيل دفعة الحجز / Error registering booking payment: {BookingId}", request.BookingId);
            return ResultDto<YemenBooking.Application.Features.Payments.DTOs.PaymentDto>.Failed("حدث خطأ أثناء تسجيل الدفعة / An error occurred while registering payment");
        }
    }

    private ResultDto<bool> ValidateInput(RegisterBookingPaymentCommand request)
    {
        var errors = new List<string>();

        if (request.BookingId == Guid.Empty)
        {
            errors.Add("معرف الحجز مطلوب / Booking ID is required");
        }

        if (request.Amount == null || request.Amount.Amount <= 0)
        {
            errors.Add("المبلغ يجب أن يكون أكبر من الصفر / Amount must be greater than zero");
        }

        if (!Enum.IsDefined(typeof(PaymentMethodEnum), request.PaymentMethod))
        {
            errors.Add("طريقة الدفع غير صحيحة / Invalid payment method");
        }

        return errors.Any() 
            ? ResultDto<bool>.Failed(errors) 
            : ResultDto<bool>.Succeeded(true);
    }

    private async Task<ResultDto<bool>> ValidateAuthorizationAsync(YemenBooking.Core.Entities.Booking booking, CancellationToken cancellationToken)
    {
        var currentUserId = _currentUserService.UserId;
        var userRoles = _currentUserService.UserRoles;

        // المدير والموظف لديهم صلاحية كاملة
        // Admin and staff have full access
        if (userRoles.Contains("Admin") || userRoles.Contains("Staff"))
        {
            return ResultDto<bool>.Succeeded(true);
        }

        // مالك العقار يمكنه تسجيل دفعات للحجوزات في عقاراته
        // Property owner can register payments for bookings in their properties
        if (userRoles.Contains("Owner"))
        {
            var unit = await _unitRepository.GetByIdAsync(booking.UnitId, cancellationToken);
            if (unit != null)
            {
                var property = await _propertyRepository.GetByIdAsync(unit.PropertyId, cancellationToken);
                if (property != null && property.OwnerId == currentUserId)
                {
                    return ResultDto<bool>.Succeeded(true);
                }
            }
        }

        return ResultDto<bool>.Failed("ليس لديك صلاحية لتسجيل دفعة لهذا الحجز / You don't have permission to register payment for this booking");
    }

    private ResultDto<bool> ValidateBookingStatus(YemenBooking.Core.Entities.Booking booking)
    {
        var errors = new List<string>();

        // التحقق من أن الحجز في حالة تسمح بالدفع
        // Check that booking is in a state that allows payment
        var validStatuses = new[] { 
            BookingStatus.Pending, 
            BookingStatus.Confirmed, 
            BookingStatus.CheckedIn 
        };

        if (!validStatuses.Contains(booking.Status))
        {
            errors.Add($"لا يمكن تسجيل دفعة للحجز في الحالة: {booking.Status} / Cannot register payment for booking in status: {booking.Status}");
        }

        // التحقق من أن الحجز لم يتم إلغاؤه
        // Check that booking is not cancelled
        if (booking.Status == BookingStatus.Cancelled)
        {
            errors.Add("لا يمكن تسجيل دفعة للحجز الملغى / Cannot register payment for cancelled booking");
        }

        return errors.Any() 
            ? ResultDto<bool>.Failed(errors) 
            : ResultDto<bool>.Succeeded(true);
    }

    private async Task LogAuditAsync(Payment payment, YemenBooking.Core.Entities.Booking booking, CancellationToken cancellationToken)
    {
        var notes = $"تسجيل دفعة بمبلغ {payment.Amount.Amount} {payment.Amount.Currency} للحجز {booking.Id} بواسطة {_currentUserService.Username} / Registered payment of {payment.Amount.Amount} {payment.Amount.Currency} for booking {booking.Id} by {_currentUserService.Username}";
        
        await _auditService.LogAuditAsync(
            entityType: "Payment",
            entityId: payment.Id,
            action: AuditAction.CREATE,
            oldValues: null,
            newValues: System.Text.Json.JsonSerializer.Serialize(new 
            { 
                Amount = payment.Amount.Amount, 
                Currency = payment.Amount.Currency, 
                BookingId = booking.Id,
                Method = payment.PaymentMethod.ToString(),
                TransactionId = payment.TransactionId
            }),
            performedBy: _currentUserService.UserId,
            notes: notes,
            cancellationToken: cancellationToken);
    }

    private async Task SendNotificationsAsync(Payment payment, YemenBooking.Core.Entities.Booking booking, CancellationToken cancellationToken)
    {
        // إرسال إشعار للضيف
        // Send notification to guest
        await _notificationService.SendAsync(new NotificationRequest
        {
            UserId = booking.UserId,
            Type = NotificationType.PaymentProcessed,
            Title = "تم تسجيل دفعة / Payment Registered",
            Message = $"تم تسجيل دفعة بمبلغ {payment.Amount.Amount} {payment.Amount.Currency} لحجزك رقم #{booking.Id.ToString().Substring(0, 8)} / Payment of {payment.Amount.Amount} {payment.Amount.Currency} has been registered for your booking #{booking.Id.ToString().Substring(0, 8)}",
            Data = new { PaymentId = payment.Id, BookingId = booking.Id }
        }, cancellationToken);
    }

    private async Task PublishEventsAsync(Payment payment, YemenBooking.Core.Entities.Booking booking, CancellationToken cancellationToken)
    {
        // نشر حدث تسجيل الدفعة
        // Publish payment registered event
        var paymentEvent = new PaymentProcessedEvent
        {
            PaymentId = payment.Id,
            BookingId = booking.Id,
            Amount = payment.Amount,
            Method = payment.PaymentMethod.ToString(),
            TransactionId = payment.TransactionId,
            Status = payment.Status.ToString(),
            ProcessedAt = payment.PaymentDate,
            Currency = payment.Amount.Currency,
            UserId = payment.ProcessedBy
        };

        await _eventPublisher.PublishAsync(paymentEvent, cancellationToken);
    }
}
