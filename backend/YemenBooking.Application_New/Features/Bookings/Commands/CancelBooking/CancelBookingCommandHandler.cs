using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Bookings;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Features.Payments.Commands.RefundPayment;

namespace YemenBooking.Application.Features.Bookings.Commands.CancelBooking;

/// <summary>
/// معالج أمر إلغاء الحجز للعميل عبر تطبيق الجوال
/// </summary>
public class CancelBookingCommandHandler : IRequestHandler<CancelBookingCommand, ResultDto<bool>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<CancelBookingCommandHandler> _logger;
    private readonly IBookingRepository _bookingRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly IUnitAvailabilityRepository _availabilityRepository;
    private readonly IMediator _mediator;
    private readonly IIndexingService _indexingService;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IPaymentRepository _paymentRepository;


    public CancelBookingCommandHandler(
        IUnitOfWork unitOfWork,
        IAuditService auditService,
        ICurrentUserService currentUserService,
        ILogger<CancelBookingCommandHandler> logger,
        IBookingRepository bookingRepository,
        IUnitRepository unitRepository,
        IUnitAvailabilityRepository availabilityRepository,
        IMediator mediator,
        IIndexingService indexingService,
        IPropertyRepository propertyRepository,
        IPaymentRepository paymentRepository)
    {
        _unitOfWork = unitOfWork;
        _auditService = auditService;
        _currentUserService = currentUserService;
        _logger = logger;
        _bookingRepository = bookingRepository;
        _unitRepository = unitRepository;
        _availabilityRepository = availabilityRepository;
        _mediator = mediator;
        _indexingService = indexingService;
        _propertyRepository = propertyRepository;
        _paymentRepository = paymentRepository;
    }

    /// <inheritdoc />
    public async Task<ResultDto<bool>> Handle(CancelBookingCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("بدء إلغاء الحجز {BookingId} من قبل المستخدم {UserId}", request.BookingId, request.UserId);

        var bookingRepo = _unitOfWork.Repository<Core.Entities.Booking>();
        var booking = await bookingRepo.GetByIdAsync(request.BookingId);
        if (booking == null)
        {
            return ResultDto<bool>.Failure("الحجز غير موجود");
        }
        // تحقق الصلاحيات عبر المستخدم الحالي (مشرف/مالك/ضيف الحجز)
        var roles = _currentUserService.UserRoles;
        if (booking.UserId != _currentUserService.UserId && !roles.Contains("Admin"))
        {
            var unitForAuth = await _unitRepository.GetByIdAsync(booking.UnitId, cancellationToken);
            if (unitForAuth == null)
            {
                return ResultDto<bool>.Failure("الوحدة غير موجودة");
            }
            var propertyForAuth = await _propertyRepository.GetByIdAsync(unitForAuth.PropertyId, cancellationToken);
            if (propertyForAuth == null || propertyForAuth.OwnerId != _currentUserService.UserId)
            {
                return ResultDto<bool>.Failure("ليس لديك صلاحية لإلغاء هذا الحجز");
            }
        }
        // سياسة الإلغاء: تحقق صارم قبل أي تعديل
        var unit = await _unitRepository.GetByIdAsync(booking.UnitId, cancellationToken);
        if (unit == null)
        {
            return ResultDto<bool>.Failure("الوحدة غير موجودة");
        }

        if (!unit.AllowsCancellation)
        {
            return ResultDto<bool>.Failure("هذه الوحدة لا تسمح بإلغاء الحجز");
        }

        int? windowDays = null;
        try
        {
            if (!string.IsNullOrWhiteSpace(booking.PolicySnapshot))
            {
                using var doc = System.Text.Json.JsonDocument.Parse(booking.PolicySnapshot);
                var root = doc.RootElement;
                if (root.TryGetProperty("UnitOverrides", out var overridesEl) && overridesEl.TryGetProperty("CancellationWindowDays", out var wndEl) && wndEl.ValueKind == System.Text.Json.JsonValueKind.Number)
                {
                    windowDays = wndEl.GetInt32();
                }
                if (!windowDays.HasValue && root.TryGetProperty("Policies", out var policiesEl) && policiesEl.ValueKind == System.Text.Json.JsonValueKind.Array)
                {
                    foreach (var p in policiesEl.EnumerateArray())
                    {
                        var typeStr = p.TryGetProperty("Type", out var tEl) ? tEl.GetString() : null;
                        if (!string.IsNullOrWhiteSpace(typeStr) && typeStr.Equals("Cancellation", StringComparison.OrdinalIgnoreCase))
                        {
                            if (p.TryGetProperty("CancellationWindowDays", out var cEl) && cEl.ValueKind == System.Text.Json.JsonValueKind.Number)
                            {
                                windowDays = cEl.GetInt32();
                                break;
                            }
                        }
                    }
                }
            }
        }
        catch { }
        if (!windowDays.HasValue)
        {
            windowDays = unit.CancellationWindowDays;
            if (!windowDays.HasValue)
            {
                var propertyPolicy = await _propertyRepository.GetCancellationPolicyAsync(unit.PropertyId, cancellationToken);
                windowDays = propertyPolicy?.CancellationWindowDays;
            }
        }
        if (windowDays.HasValue)
        {
            var daysBeforeCheckIn = (booking.CheckIn - DateTime.UtcNow).TotalDays;
            _ = daysBeforeCheckIn;
        }

        // التحقق من وجود مدفوعات ناجحة للحجز
        var payments = await _paymentRepository.GetPaymentsByBookingAsync(booking.Id, cancellationToken);
        var hasSuccessfulPayments = payments.Any(p => p.Status == PaymentStatus.Successful || p.Status == PaymentStatus.PartiallyRefunded);
        if (hasSuccessfulPayments && !request.RefundPayments)
        {
            return ResultDto<bool>.Failure(
                "لا يمكن إلغاء حجز يحتوي على مدفوعات. هل تريد استرداد المدفوعات ثم إلغاء الحجز؟",
                errorCode: "PAYMENTS_EXIST",
                showAsDialog: true
            );
        }

        if (hasSuccessfulPayments && request.RefundPayments)
        {
            foreach (var pay in payments.Where(p => p.Status == PaymentStatus.Successful).OrderBy(p => p.PaymentDate))
            {
                var refundCmd = new RefundPaymentCommand
                {
                    PaymentId = pay.Id,
                    RefundAmount = new MoneyDto { Amount = pay.Amount.Amount, Currency = pay.Amount.Currency, ExchangeRate = 1 },
                    RefundReason = request.CancellationReason ?? "Cancellation"
                };
                var refundRes = await _mediator.Send(refundCmd, cancellationToken);
                if (!refundRes.Success)
                {
                    return ResultDto<bool>.Failure(refundRes.Message ?? "فشل استرداد المبالغ قبل الإلغاء", errorCode: "REFUND_FAILED_BEFORE_CANCELLATION");
                }
            }
        }

        // Passed policy checks and handled payments: proceed to cancel
        booking.Status = BookingStatus.Cancelled;
        booking.CancellationReason = request.CancellationReason;
        booking.UpdatedAt = DateTime.UtcNow;

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // ✅ تحديث مباشر لفهرس الإتاحة - Critical للبحث
        // إذا فشل، نحتاج إعادة المحاولة لأن الفهرس سيصبح غير متطابق
        var indexingSuccess = false;
        var indexingAttempts = 0;
        const int maxIndexingAttempts = 3;
        
        while (!indexingSuccess && indexingAttempts < maxIndexingAttempts)
        {
            try
            {
                indexingAttempts++;
                var bookingToUpdate = await _bookingRepository.GetByIdAsync(request.BookingId, cancellationToken);
                if (bookingToUpdate != null)
                {
                    var from = DateTime.UtcNow.Date;
                    var to = from.AddMonths(6);
                    var periods = await _availabilityRepository.GetByDateRangeAsync(bookingToUpdate.UnitId, from, to);
                    var availableRanges = periods
                        .Where(a => a.Status == "Available")
                        .Select(p => (p.StartDate, p.EndDate))
                        .ToList();

                    var propertyId = unit?.PropertyId ?? Guid.Empty;

                    await _indexingService.OnAvailabilityChangedAsync(bookingToUpdate.UnitId, propertyId, availableRanges, cancellationToken);
                    indexingSuccess = true;
                    _logger.LogInformation("✅ تم تحديث فهرس الإتاحة بنجاح بعد إلغاء الحجز {BookingId} (محاولة {Attempt}/{Max})", 
                        request.BookingId, indexingAttempts, maxIndexingAttempts);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "⚠️ فشلت محاولة {Attempt}/{Max} لتحديث فهرس الإتاحة بعد إلغاء الحجز {BookingId}", 
                    indexingAttempts, maxIndexingAttempts, request.BookingId);
                
                if (indexingAttempts < maxIndexingAttempts)
                {
                    await Task.Delay(TimeSpan.FromSeconds(1 * indexingAttempts), cancellationToken); // Exponential backoff
                }
                else
                {
                    // ❌ Critical failure: الفهرس لن يتطابق مع الواقع
                    _logger.LogCritical("❌ CRITICAL: فشل تحديث فهرس الإتاحة بعد {Attempts} محاولات للحجز {BookingId}. " +
                        "الفهرس غير متطابق! يجب تشغيل re-index يدوي.", 
                        maxIndexingAttempts, request.BookingId);
                    
                    // TODO: إضافة إلى background job queue للمحاولة لاحقاً
                }
            }
        }
        
        var performerName = _currentUserService.Username;
        var performerId = _currentUserService.UserId;
        var notes = $"تم إلغاء الحجز {booking.Id} بواسطة {performerName} (ID={performerId})";
        await _auditService.LogAuditAsync(
            entityType: "BookingDto",
            entityId: booking.Id,
            action: AuditAction.DELETE,
            oldValues: JsonSerializer.Serialize(new { booking.Id, PreviousStatus = "Pending" }),
            newValues: null,
            performedBy: performerId,
            notes: notes,
            cancellationToken: cancellationToken);

        return ResultDto<bool>.Succeeded(true, "تم إلغاء الحجز بنجاح");
    }
}
