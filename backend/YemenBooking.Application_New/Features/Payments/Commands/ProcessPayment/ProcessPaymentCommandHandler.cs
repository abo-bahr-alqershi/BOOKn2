using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Payments;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using System.Text.RegularExpressions;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Features.AuditLog.Services;
using System.Linq;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Payments.Commands.ProcessPayment;
using YemenBooking.Application.Features.Payments.DTOs;
using YemenBooking.Application.Features.Payments.Services;

namespace YemenBooking.Application.Features.Payments.Commands.ProcessPayment;

/// <summary>
/// معالج أمر معالجة الدفع
/// Handler for process payment command
/// </summary>
public class ProcessPaymentCommandHandler : IRequestHandler<ProcessPaymentCommand, ResultDto<ProcessPaymentResponse>>
{
    private readonly IPaymentService _paymentService;
    private readonly IBookingRepository _bookingRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly ILogger<ProcessPaymentCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ICurrencySettingsService _currencySettingsService;

    /// <summary>
    /// منشئ معالج أمر معالجة الدفع
    /// Constructor for process payment command handler
    /// </summary>
    /// <param name="paymentService">خدمة الدفع</param>
    /// <param name="bookingRepository">مستودع الحجوزات</param>
    /// <param name="paymentRepository">مستودع المدفوعات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public ProcessPaymentCommandHandler(
        IPaymentService paymentService,
        IBookingRepository bookingRepository,
        IPaymentRepository paymentRepository,
        ILogger<ProcessPaymentCommandHandler> logger,
        IAuditService auditService,
        ICurrentUserService currentUserService,
        ICurrencySettingsService currencySettingsService)
    {
        _paymentService = paymentService;
        _bookingRepository = bookingRepository;
        _paymentRepository = paymentRepository;
        _logger = logger;
        _auditService = auditService;
        _currentUserService = currentUserService;
        _currencySettingsService = currencySettingsService;
    }

    /// <summary>
    /// معالجة أمر معالجة الدفع
    /// Handle process payment command
    /// </summary>
    /// <param name="request">طلب معالجة الدفع</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<YemenBooking.Application.Features.Payments.DTOs.ProcessPaymentResponse>> Handle(ProcessPaymentCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء عملية معالجة الدفع للحجز: {BookingId}", request.BookingId);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // البحث عن الحجز
            var booking = await _bookingRepository.GetByIdAsync(request.BookingId, cancellationToken);
            if (booking == null)
            {
                _logger.LogWarning("لم يتم العثور على الحجز: {BookingId}", request.BookingId);
                return ResultDto<ProcessPaymentResponse>.Failed("الحجز غير موجود", "BOOKING_NOT_FOUND");
            }

            // التحقق من صحة المبلغ (عدد المنازل العشرية)
            if (decimal.Round(request.Amount.Amount, 2) != request.Amount.Amount)
            {
                return ResultDto<ProcessPaymentResponse>.Failed("عدد المنازل العشرية للمبلغ يجب ألا يتجاوز رقمين", "AMOUNT_PRECISION");
            }

            // التحقق من أن العملة مطابقة لعملة الحجز
            var paymentCurrency = request.Amount.Currency ?? booking.TotalPrice.Currency;
            if (!string.Equals(paymentCurrency, booking.TotalPrice.Currency, StringComparison.OrdinalIgnoreCase))
            {
                return ResultDto<ProcessPaymentResponse>.Failed($"العملة المستخدمة ({paymentCurrency}) يجب أن تطابق عملة الحجز ({booking.TotalPrice.Currency})", "CURRENCY_MISMATCH");
            }

            // التحقق من أن العملة مدعومة ضمن إعدادات النظام
            var currencies = await _currencySettingsService.GetCurrenciesAsync(cancellationToken);
            var isSupported = currencies.Any(c => string.Equals(c.Code, booking.TotalPrice.Currency, StringComparison.OrdinalIgnoreCase));
            if (!isSupported)
            {
                return ResultDto<ProcessPaymentResponse>.Failed("العملة غير مدعومة في إعدادات النظام", "UNSUPPORTED_CURRENCY");
            }

            // التحقق من حالة الحجز
            if (booking.Status != BookingStatus.Pending)
            {
                _logger.LogWarning("محاولة دفع لحجز غير في حالة الانتظار: {BookingId}, Status: {Status}", 
                    request.BookingId, booking.Status);
                return ResultDto<ProcessPaymentResponse>.Failed("الحجز غير قابل للدفع في الحالة الحالية", "BOOKING_NOT_PAYABLE");
            }

            // التحقق من تطابق المبلغ
            if (request.Amount.Amount != booking.TotalPrice.Amount)
            {
                _logger.LogWarning("مبلغ الدفع غير متطابق مع مبلغ الحجز. المطلوب: {BookingAmount}, المرسل: {PaymentAmount}", 
                    booking.TotalPrice, request.Amount.Amount);
                return ResultDto<ProcessPaymentResponse>.Failed("مبلغ الدفع غير متطابق مع مبلغ الحجز", "AMOUNT_MISMATCH");
            }

            // التحقق من عدم وجود دفعة ناجحة مسبقاً
            var allPayments = await _paymentRepository.GetAllAsync(cancellationToken);
            var existingPayment = allPayments?.FirstOrDefault(p => 
                p.BookingId == request.BookingId && 
                p.Status == Core.Enums.PaymentStatus.Successful);
            if (existingPayment != null)
            {
                _logger.LogWarning("يوجد دفعة ناجحة مسبقاً للحجز: {BookingId}", request.BookingId);
                return ResultDto<ProcessPaymentResponse>.Failed("تم دفع مبلغ هذا الحجز مسبقاً", "ALREADY_PAID");
            }

            // معالجة الدفع حسب طريقة الدفع
            var paymentResult = await ProcessPaymentByMethod(request, booking, cancellationToken);
            if (paymentResult == null)
            {
                _logger.LogError("فشل في معالجة الدفع للحجز: {BookingId}", request.BookingId);
                return ResultDto<ProcessPaymentResponse>.Failed("فشل في معالجة الدفع", "PAYMENT_PROCESSING_FAILED");
            }

            // حفظ معلومات الدفع في قاعدة البيانات
            if (!Enum.TryParse<PaymentMethodEnum>(request.PaymentMethod.ToString(), true, out var paymentMethodType))
            {
                _logger.LogError("طريقة الدفع غير صالحة");
                return ResultDto<ProcessPaymentResponse>.Failed("طريقة الدفع غير صالحة", "INVALID_PAYMENT_METHOD");
            }

            var payment = new YemenBooking.Core.Entities.Payment 
            {
                Id = Guid.NewGuid(),
                BookingId = request.BookingId,
                Amount = request.Amount,
                PaymentMethod = paymentMethodType, // استخدام PaymentMethodEnum مباشرة
                TransactionId = paymentResult.TransactionId ?? string.Empty,
                Status = paymentResult.Success ? Core.Enums.PaymentStatus.Successful : Core.Enums.PaymentStatus.Failed,
                ProcessedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow
            };
            var savedPayment = await _paymentRepository.AddAsync(payment, cancellationToken);

            if (paymentResult.Success)
            {
                // تحديث حالة الحجز إلى مدفوع
                booking.Status = BookingStatus.Confirmed;
                booking.UpdatedAt = DateTime.UtcNow;

                await _bookingRepository.UpdateAsync(booking, cancellationToken);

                _logger.LogInformation("تم إكمال الدفع بنجاح للحجز: {BookingId}, TransactionId: {TransactionId}", 
                    request.BookingId, paymentResult.TransactionId);

                // سجل تدقيق الدفع الناجح
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes = $"تم إتمام الدفع للحجز {request.BookingId} بنجاح بواسطة {performerName} (ID={performerId})";
                await _auditService.LogAuditAsync(
                    entityType: "Payment",
                    entityId: savedPayment.Id,
                    action: AuditAction.UPDATE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { PaymentId = savedPayment.Id, BookingId = request.BookingId, Amount = request.Amount.Amount, Method = request.PaymentMethod.ToString(), TransactionId = paymentResult.TransactionId }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);
            }
            else if (!paymentResult.Success)
            {
                _logger.LogWarning("فشل في الدفع للحجز: {BookingId}, Reason: {Message}", 
                    request.BookingId, paymentResult.Message);

                // سجل تدقيق الدفع الفاشل
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes = $"فشل الدفع للحجز {request.BookingId} بواسطة {performerName} (ID={performerId})";
                await _auditService.LogAuditAsync(
                    entityType: "Payment",
                    entityId: savedPayment.Id,
                    action: AuditAction.UPDATE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { PaymentId = savedPayment.Id, BookingId = request.BookingId, Amount = request.Amount.Amount, Method = request.PaymentMethod.ToString(), Error = paymentResult.Message }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);
            }

            return ResultDto<ProcessPaymentResponse>.Ok(paymentResult, paymentResult.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء معالجة الدفع للحجز: {BookingId}", request.BookingId);
            return ResultDto<ProcessPaymentResponse>.Failed($"حدث خطأ أثناء معالجة الدفع: {ex.Message}", "PAYMENT_ERROR");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate the input request
    /// </summary>
    /// <param name="request">طلب الدفع</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<ProcessPaymentResponse> ValidateRequest(ProcessPaymentCommand request)
    {
        if (request.BookingId == Guid.Empty)
        {
            return ResultDto<ProcessPaymentResponse>.Failed("معرف الحجز غير صالح", "INVALID_BOOKING_ID");
        }

        if (request.Amount == null || request.Amount.Amount <= 0)
        {
            return ResultDto<ProcessPaymentResponse>.Failed("مبلغ الدفع غير صالح", "INVALID_AMOUNT");
        }

        // التحقق من طريقة الدفع وبياناتها المطلوبة
        if (!Enum.TryParse<PaymentMethodEnum>(request.PaymentMethod.ToString(), true, out var paymentMethodType))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("طريقة الدفع غير صالحة", "INVALID_PAYMENT_METHOD");
        }

        switch (paymentMethodType)
        {
            case PaymentMethodEnum.CreditCard:
                if (request.CardDetails == null)
                {
                    return ResultDto<ProcessPaymentResponse>.Failed("تفاصيل البطاقة مطلوبة", "CARD_DETAILS_REQUIRED");
                }
                
                var cardValidation = ValidateCardDetails(request.CardDetails);
                if (!cardValidation.IsSuccess)
                {
                    return cardValidation;
                }
                break;

            // المحافظ الرقمية المتاحة في النظام
            case PaymentMethodEnum.JwaliWallet:
            case PaymentMethodEnum.CashWallet:
            case PaymentMethodEnum.OneCashWallet:
            case PaymentMethodEnum.FloskWallet:
            case PaymentMethodEnum.JaibWallet:
                if (string.IsNullOrWhiteSpace(request.WalletId))
                {
                    return ResultDto<ProcessPaymentResponse>.Failed("معرف المحفظة الإلكترونية مطلوب", "WALLET_ID_REQUIRED");
                }
                break;

            // طرق لا تحتاج تفاصيل إضافية
            case PaymentMethodEnum.Cash:
            case PaymentMethodEnum.Paypal:
                break;

            default:
                return ResultDto<ProcessPaymentResponse>.Failed("طريقة الدفع غير مدعومة", "UNSUPPORTED_PAYMENT_METHOD");
        }

        return ResultDto<ProcessPaymentResponse>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// التحقق من صحة تفاصيل البطاقة الائتمانية
    /// Validate credit card details
    /// </summary>
    /// <param name="cardDetails">تفاصيل البطاقة</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<ProcessPaymentResponse> ValidateCardDetails(CardDetails cardDetails)
    {
        // التحقق من رقم البطاقة
        if (string.IsNullOrWhiteSpace(cardDetails.CardNumber))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("رقم البطاقة مطلوب", "CARD_NUMBER_REQUIRED");
        }

        // إزالة المسافات والشرطات من رقم البطاقة
        var cleanCardNumber = cardDetails.CardNumber.Replace(" ", "").Replace("-", "");
        if (!Regex.IsMatch(cleanCardNumber, @"^\d{13,19}$"))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("رقم البطاقة غير صالح", "INVALID_CARD_NUMBER");
        }

        // التحقق من اسم حامل البطاقة
        if (string.IsNullOrWhiteSpace(cardDetails.CardholderName))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("اسم حامل البطاقة مطلوب", "CARDHOLDER_NAME_REQUIRED");
        }

        // التحقق من تاريخ انتهاء الصلاحية
        if (cardDetails.ExpiryMonth < 1 || cardDetails.ExpiryMonth > 12)
        {
            return ResultDto<ProcessPaymentResponse>.Failed("شهر انتهاء الصلاحية غير صالح", "INVALID_EXPIRY_MONTH");
        }

        var currentYear = DateTime.Now.Year;
        if (cardDetails.ExpiryYear < currentYear || cardDetails.ExpiryYear > currentYear + 20)
        {
            return ResultDto<ProcessPaymentResponse>.Failed("سنة انتهاء الصلاحية غير صالحة", "INVALID_EXPIRY_YEAR");
        }

        // التحقق من عدم انتهاء صلاحية البطاقة
        var expiryDate = new DateTime(cardDetails.ExpiryYear, cardDetails.ExpiryMonth, 1).AddMonths(1).AddDays(-1);
        if (expiryDate < DateTime.Now.Date)
        {
            return ResultDto<ProcessPaymentResponse>.Failed("البطاقة منتهية الصلاحية", "CARD_EXPIRED");
        }

        // التحقق من رمز الأمان CVV
        if (string.IsNullOrWhiteSpace(cardDetails.CVV))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("رمز الأمان CVV مطلوب", "CVV_REQUIRED");
        }

        if (!Regex.IsMatch(cardDetails.CVV, @"^\d{3,4}$"))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("رمز الأمان CVV غير صالح", "INVALID_CVV");
        }

        return ResultDto<ProcessPaymentResponse>.Ok(null, "تفاصيل البطاقة صحيحة");
    }

    /// <summary>
    /// معالجة الدفع حسب طريقة الدفع
    /// Process payment by payment method
    /// </summary>
    /// <param name="request">طلب الدفع</param>
    /// <param name="booking">الحجز</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة معالجة الدفع</returns>
    private async Task<ProcessPaymentResponse?> ProcessPaymentByMethod(
        ProcessPaymentCommand request, 
        dynamic booking, 
        CancellationToken cancellationToken)
    {
        if (!Enum.TryParse<PaymentMethodEnum>(request.PaymentMethod.ToString(), true, out var paymentMethodType))
        {
            _logger.LogError("طريقة الدفع غير صالحة");
            return null;
        }

        return paymentMethodType switch
        {
            PaymentMethodEnum.CreditCard => ConvertToProcessPaymentResponse(await _paymentService.ProcessPaymentAsync(
                request.BookingId,
                Guid.NewGuid(), // استخدام معرف مؤقت بدلاً من PaymentMethod.Id
                request.Amount.Amount,
                request.Amount.Currency ?? "YER")),

            // المحافظ الرقمية
            PaymentMethodEnum.JwaliWallet => ConvertToProcessPaymentResponse(await _paymentService.ProcessPaymentAsync(
                request.BookingId,
                Guid.NewGuid(),
                request.Amount.Amount,
                request.Amount.Currency ?? "YER")),
            PaymentMethodEnum.CashWallet => ConvertToProcessPaymentResponse(await _paymentService.ProcessPaymentAsync(
                request.BookingId,
                Guid.NewGuid(),
                request.Amount.Amount,
                request.Amount.Currency ?? "YER")),
            PaymentMethodEnum.OneCashWallet => ConvertToProcessPaymentResponse(await _paymentService.ProcessPaymentAsync(
                request.BookingId,
                Guid.NewGuid(),
                request.Amount.Amount,
                request.Amount.Currency ?? "YER")),
            PaymentMethodEnum.FloskWallet => ConvertToProcessPaymentResponse(await _paymentService.ProcessPaymentAsync(
                request.BookingId,
                Guid.NewGuid(),
                request.Amount.Amount,
                request.Amount.Currency ?? "YER")),
            PaymentMethodEnum.JaibWallet => ConvertToProcessPaymentResponse(await _paymentService.ProcessPaymentAsync(
                request.BookingId,
                Guid.NewGuid(),
                request.Amount.Amount,
                request.Amount.Currency ?? "YER")),

            // طرق أخرى مدعومة
            PaymentMethodEnum.Cash => ConvertToProcessPaymentResponse(await _paymentService.ProcessPaymentAsync(
                request.BookingId,
                Guid.NewGuid(),
                request.Amount.Amount,
                request.Amount.Currency ?? "YER")),

            PaymentMethodEnum.Paypal => ConvertToProcessPaymentResponse(await _paymentService.ProcessPaymentAsync(
                request.BookingId,
                Guid.NewGuid(),
                request.Amount.Amount,
                request.Amount.Currency ?? "YER")),

            _ => null
        };
    }

    /// <summary>
    /// تحويل PaymentResult إلى ProcessPaymentResponse
    /// </summary>
    private YemenBooking.Application.Features.Payments.DTOs.ProcessPaymentResponse? ConvertToProcessPaymentResponse(YemenBooking.Application.Features.Payments.Services.PaymentResult? paymentResult)
    {
        if (paymentResult == null)
            return null;

        return new YemenBooking.Application.Features.Payments.DTOs.ProcessPaymentResponse
        {
            TransactionId = paymentResult.TransactionId ?? string.Empty,
            Success = paymentResult.IsSuccess,
            Message = paymentResult.Message ?? string.Empty,
            ProcessedAmount = paymentResult.ProcessedAmount,
            Fees = paymentResult.Fees,
            Currency = "YER",
            ProcessedAt = paymentResult.ProcessedAt,
            PaymentStatusDto = paymentResult.IsSuccess ? "Completed" : "Failed"
        };
    }
}
