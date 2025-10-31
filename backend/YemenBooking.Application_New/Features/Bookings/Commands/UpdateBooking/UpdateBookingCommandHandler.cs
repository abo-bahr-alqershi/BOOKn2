using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Bookings;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Events;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Application.Features.AuditLog.Services;
using System.Linq;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Core.Notifications;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Application.Features.Pricing;
using YemenBooking.Application.Features.Units.Services;

namespace YemenBooking.Application.Features.Bookings.Commands.UpdateBooking;

/// <summary>
/// معالج أمر تحديث الحجز
/// Update booking command handler
/// </summary>
public class UpdateBookingCommandHandler : IRequestHandler<UpdateBookingCommand, ResultDto<bool>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IAvailabilityService _availabilityService;
    private readonly IPricingService _pricingService;
    private readonly IValidationService _validationService;
    private readonly IAuditService _auditService;
    private readonly IEventPublisher _eventPublisher;
    private readonly ILogger<UpdateBookingCommandHandler> _logger;
    private readonly INotificationService _notificationService;

    public UpdateBookingCommandHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IAvailabilityService availabilityService,
        IPricingService pricingService,
        IValidationService validationService,
        IAuditService auditService,
        IEventPublisher eventPublisher,
        ILogger<UpdateBookingCommandHandler> logger,
        INotificationService notificationService)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _availabilityService = availabilityService;
        _pricingService = pricingService;
        _validationService = validationService;
        _auditService = auditService;
        _eventPublisher = eventPublisher;
        _logger = logger;
        _notificationService = notificationService;
    }

    public async Task<ResultDto<bool>> Handle(UpdateBookingCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء معالجة أمر تحديث الحجز {BookingId}", request.BookingId);

            // Normalize any provided user-local dates to UTC
            if (request.CheckIn.HasValue)
            {
                request.CheckIn = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckIn.Value);
            }
            if (request.CheckOut.HasValue)
            {
                request.CheckOut = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckOut.Value);
            }

            // التحقق من وجود الحجز
            var booking = await _unitOfWork.Repository<Booking>().GetByIdAsync(request.BookingId, cancellationToken);
            if (booking == null)
            {
                _logger.LogWarning("الحجز غير موجود: {BookingId}", request.BookingId);
                return ResultDto<bool>.Failure("الحجز غير موجود.");
            }

            // التحقق من الصلاحيات
            var authorizationValidation = await ValidateAuthorizationAsync(booking, cancellationToken);
            if (!authorizationValidation.IsSuccess)
            {
                return authorizationValidation;
            }

            // التحقق من حالة الكيان
            var stateValidation = ValidateBookingState(booking);
            if (!stateValidation.IsSuccess)
            {
                return stateValidation;
            }

            // التحقق من صحة المدخلات
            var validationResult = await ValidateInputAsync(request, booking, cancellationToken);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // التحقق من قواعد العمل
            var businessRulesValidation = await ValidateBusinessRulesAsync(request, booking, cancellationToken);
            if (!businessRulesValidation.IsSuccess)
            {
                return businessRulesValidation;
            }

            // التحقق من توافر الوحدة للفترة الجديدة
            if (request.CheckIn.HasValue || request.CheckOut.HasValue)
            {
                var newCheckIn = request.CheckIn ?? booking.CheckIn;
                var newCheckOut = request.CheckOut ?? booking.CheckOut;
                // استثناء الحجز الحالي من الفحص
                var isAvailable = await _availabilityService.CheckAvailabilityAsync(
                    booking.UnitId,
                    newCheckIn,
                    newCheckOut,
                    booking.Id);
                if (!isAvailable)
                {
                    return ResultDto<bool>.Failed("لا يمكن تحديث الحجز؛ الوحدة غير متاحة للفترة الجديدة");
                }
            }

            // حفظ القيم القديمة للمقارنة
            var originalCheckIn = booking.CheckIn;
            var originalCheckOut = booking.CheckOut;
            var originalGuestsCount = booking.GuestsCount;
            var originalTotalPrice = booking.TotalPrice;

            // تحديث البيانات
            if (request.CheckIn.HasValue)
                booking.CheckIn = request.CheckIn.Value;

            if (request.CheckOut.HasValue)
                booking.CheckOut = request.CheckOut.Value;

            if (request.GuestsCount.HasValue)
                booking.GuestsCount = request.GuestsCount.Value;

            // إعادة حساب السعر إذا تغيرت التواريخ أو عدد الضيوف
            if (request.CheckIn.HasValue || request.CheckOut.HasValue || request.GuestsCount.HasValue)
            {
                var priceAmount = await _pricingService.CalculatePriceAsync(
                    booking.UnitId,
                    request.CheckIn ?? booking.CheckIn,
                    request.CheckOut ?? booking.CheckOut);
                booking.TotalPrice = Money.Yer(priceAmount);
            }

            booking.UpdatedAt = DateTime.UtcNow;

            // حفظ التغييرات
            await _unitOfWork.Repository<Booking>().UpdateAsync(booking, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // تحديث سجل الإتاحة للحجز إذا تغيرت التواريخ
            var blocksToUpdate = await _unitOfWork.Repository<UnitAvailability>()
                .FindAsync(u => u.BookingId == booking.Id, cancellationToken);
            foreach (var block in blocksToUpdate)
            {
                block.StartDate = booking.CheckIn;
                block.EndDate = booking.CheckOut;
                block.UpdatedAt = DateTime.UtcNow;
                await _unitOfWork.Repository<UnitAvailability>().UpdateAsync(block, cancellationToken);
            }
            // حفظ تغييرات الإتاحة المرتبطة بالحجز
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            // تسجيل تحديث كتلة الإتاحة في سجل التدقيق
            await _auditService.LogAuditAsync(
                entityType: nameof(UnitAvailability),
                entityId: booking.Id,
                action: AuditAction.UPDATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { booking.CheckIn, booking.CheckOut }),
                performedBy: _currentUserService.UserId,
                notes: $"تم تحديث فترة الإتاحة للحجز {booking.Id} إلى {booking.CheckIn:yyyy-MM-dd} - {booking.CheckOut:yyyy-MM-dd} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            // تسجيل العملية في سجل التدقيق
            var changes = BuildChangesList(originalCheckIn, originalCheckOut, originalGuestsCount, originalTotalPrice, booking);
            await _auditService.LogAuditAsync(
                entityType: nameof(Booking),
                entityId: booking.Id,
                action: AuditAction.UPDATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { Changes = changes }),
                performedBy: _currentUserService.UserId,
                notes: $"تم تحديث الحجز: {string.Join(", ", changes)} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            // إرسال حدث تحديث الحجز
            await _eventPublisher.PublishAsync(new BookingUpdatedEvent
            {
                BookingId = booking.Id,
                UserId = booking.UserId,
                UnitId = booking.UnitId,
                UpdatedAt = booking.UpdatedAt,
                UpdatedBy = _currentUserService.UserId,
                UpdatedFields = changes.ToArray(),
                OccurredAt = DateTime.UtcNow,
                EventId = Guid.NewGuid(),
                OccurredOn = DateTime.UtcNow,
                EventType = nameof(BookingUpdatedEvent),
                Version = 1,
                CorrelationId = null,
                NewCheckIn = request.CheckIn,
                NewCheckOut = request.CheckOut,
                NewGuestsCount = request.GuestsCount,
                NewTotalPrice = booking.TotalPrice,
                NewStatus = booking.Status.ToString()
            }, cancellationToken);

            // إرسال إشعار للضيف بتحديث الحجز
            await _notificationService.SendAsync(new NotificationRequest
            {
                UserId = booking.UserId,
                Type = NotificationType.BookingUpdated,
                Title = "تم تحديث حجزك / Your booking has been updated",
                Message = $"تم تحديث تفاصيل حجزك رقم {booking.Id} / Your booking {booking.Id} details have been updated",
                Data = new { BookingId = booking.Id }
            }, cancellationToken);

            _logger.LogInformation("تم تحديث الحجز {BookingId} بنجاح", booking.Id);

            return ResultDto<bool>.Succeeded(true, "تم تحديث الحجز بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في تحديث الحجز {BookingId}", request.BookingId);
            return ResultDto<bool>.Failed("حدث خطأ أثناء تحديث الحجز");
        }
    }

    /// <summary>
    /// التحقق من الصلاحيات
    /// Authorization validation
    /// </summary>
    private async Task<ResultDto<bool>> ValidateAuthorizationAsync(Booking booking, CancellationToken cancellationToken)
    {
        var currentUserId = _currentUserService.UserId;

        // التحقق من أن المستخدم صاحب الحجز أو مالك الكيان أو مسؤول
        if (currentUserId == booking.UserId)
        {
            return ResultDto<bool>.Succeeded(true);
        }

        // التحقق من أن المستخدم مسؤول
        if (_currentUserService.Role == "Admin")
        {
            return ResultDto<bool>.Succeeded(true);
        }

        // التحقق من كون المستخدم موظف في الكيان
        var unit = await _unitOfWork.Repository<Core.Entities.Unit>().GetByIdAsync(booking.UnitId, cancellationToken);
        var property = await _unitOfWork.Repository<Property>().GetByIdAsync(unit.PropertyId, cancellationToken);
        
        if (property.OwnerId == currentUserId)
        {
            return ResultDto<bool>.Succeeded(true);
        }

        // التحقق من كون المستخدم موظف في الكيان
        if (_currentUserService.IsStaffInProperty(property.Id))
        {
            return ResultDto<bool>.Succeeded(true);
        }

        return ResultDto<bool>.Failed("ليس لديك صلاحية لتحديث هذا الحجز");
    }

    /// <summary>
    /// التحقق من حالة الحجز
    /// BookingDto state validation
    /// </summary>
    private ResultDto<bool> ValidateBookingState(Booking booking)
    {
        // التحقق من حالة الحجز
        if (booking.Status != BookingStatus.Pending && booking.Status != BookingStatus.Confirmed)
        {
            return ResultDto<bool>.Failed("لا يمكن تحديث حجز ليس في حالة انتظار أو تأكيد");
        }

        return ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// التحقق من صحة المدخلات
    /// Input validation
    /// </summary>
    private async Task<ResultDto<bool>> ValidateInputAsync(UpdateBookingCommand request, Booking booking, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        // تحديد التواريخ النهائية
        var checkIn = request.CheckIn ?? booking.CheckIn;
        var checkOut = request.CheckOut ?? booking.CheckOut;
        var guestsCount = request.GuestsCount ?? booking.GuestsCount;

        // التحقق من صحة التواريخ
        if (checkIn >= checkOut)
            errors.Add("تاريخ المغادرة يجب أن يكون بعد تاريخ الوصول");

        var userToday = (await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow)).Date;
        var checkInLocal = (await _currentUserService.ConvertFromUtcToUserLocalAsync(checkIn)).Date;
        if (checkInLocal < userToday && request.CheckIn.HasValue)
            errors.Add("تاريخ الوصول يجب أن يكون في المستقبل");

        // التحقق من عدد الضيوف
        if (guestsCount <= 0)
            errors.Add("عدد الضيوف يجب أن يكون أكبر من صفر");

        // التحقق من أن المستخدم لديه الصلاحية لتحديث الحجز
        if (_currentUserService.Role != "Admin" && _currentUserService.Role != "Staff" && _currentUserService.UserId != booking.UserId)
        {
            errors.Add("ليس لديك الصلاحية لتحديث هذا الحجز / You do not have permission to update this booking");
        }

        // التحقق من أن المستخدم هو موظف في الكيان إذا لم يكن المالك أو المسؤول
        if (_currentUserService.Role != "Admin" && _currentUserService.Role != "Staff" && !_currentUserService.IsStaffInProperty(booking.Unit.PropertyId))
        {
            errors.Add("لست موظفًا في هذا الكيان / You are not a staff member of this property");
        }

        var validationResult = await _validationService.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            errors.AddRange(validationResult.Errors.Select(e => e.Message));
        }

        if (errors.Any())
        {
            return ResultDto<bool>.Failed(errors, "بيانات غير صحيحة");
        }

        return ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// التحقق من قواعد العمل
    /// Business rules validation
    /// </summary>
    private async Task<ResultDto<bool>> ValidateBusinessRulesAsync(UpdateBookingCommand request, Booking booking, CancellationToken cancellationToken)
    {
        // التحقق من توفر الوحدة إذا تغيرت التواريخ
        if (request.CheckIn.HasValue || request.CheckOut.HasValue)
        {
            var checkIn = request.CheckIn ?? booking.CheckIn;
            var checkOut = request.CheckOut ?? booking.CheckOut;

            // التحقق من توفر الوحدة في الفترة الجديدة (استثناء الحجز الحالي)
            var isAvailable = await _availabilityService.CheckAvailabilityAsync(
                booking.UnitId,
                checkIn,
                checkOut,
                booking.Id);

            // استبعاد الحجز الحالي من التحقق من التداخل
            var overlappingBookings = await _unitOfWork.Repository<Booking>().FindAsync(
                b => b.Id != booking.Id && b.UnitId == booking.UnitId && b.CheckIn < checkOut && b.CheckOut > checkIn,
                cancellationToken);

            if (!isAvailable || overlappingBookings.Any())
            {
                return ResultDto<bool>.Failed("الوحدة غير متوفرة في الفترة الجديدة");
            }
        }

        // التحقق من سعة الوحدة
        if (request.GuestsCount.HasValue)
        {
            var unit = await _unitOfWork.Repository<Core.Entities.Unit>().GetByIdAsync(booking.UnitId, cancellationToken);
            if (request.GuestsCount.Value > unit.MaxCapacity)
            {
                return ResultDto<bool>.Failed($"عدد الضيوف يتجاوز السعة القصوى للوحدة ({unit.MaxCapacity})");
            }
        }

        // التحقق من سياسة التعديل للكيان
        var property = await GetPropertyFromBookingAsync(booking, cancellationToken);
        var modificationPolicy = await GetPropertyModificationPolicyAsync(property.Id, cancellationToken);
        
        if (modificationPolicy != null)
        {
            var timeToCheckIn = booking.CheckIn - DateTime.UtcNow;
            if (timeToCheckIn.TotalHours < modificationPolicy.MinHoursBeforeCheckIn)
            {
                return ResultDto<bool>.Failed($"لا يمكن تعديل الحجز قبل {modificationPolicy.MinHoursBeforeCheckIn} ساعة من الوصول");
            }
        }

        return ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// بناء قائمة التغييرات
    /// Build changes list
    /// </summary>
    private List<string> BuildChangesList(DateTime originalCheckIn, DateTime originalCheckOut, 
        int originalGuestsCount, Core.ValueObjects.Money originalTotalPrice, Core.Entities.Booking booking)
    {
        var changes = new List<string>();

        if (originalCheckIn != booking.CheckIn)
            changes.Add($"تاريخ الوصول من {originalCheckIn:yyyy-MM-dd} إلى {booking.CheckIn:yyyy-MM-dd}");

        if (originalCheckOut != booking.CheckOut)
            changes.Add($"تاريخ المغادرة من {originalCheckOut:yyyy-MM-dd} إلى {booking.CheckOut:yyyy-MM-dd}");

        if (originalGuestsCount != booking.GuestsCount)
            changes.Add($"عدد الضيوف من {originalGuestsCount} إلى {booking.GuestsCount}");

        if (originalTotalPrice.Amount != booking.TotalPrice.Amount)
            changes.Add($"السعر الإجمالي من {originalTotalPrice} إلى {booking.TotalPrice}");

        return changes;
    }

    /// <summary>
    /// الحصول على الكيان من الحجز
    /// Get property from booking
    /// </summary>
    private async Task<Property> GetPropertyFromBookingAsync(Booking booking, CancellationToken cancellationToken)
    {
        var unit = await _unitOfWork.Repository<YemenBooking.Core.Entities.Unit>().GetByIdAsync(booking.UnitId, cancellationToken);
        return await _unitOfWork.Repository<Property>().GetByIdAsync(unit.PropertyId, cancellationToken);
    }

    /// <summary>
    /// الحصول على سياسة التعديل للكيان
    /// Get property modification policy
    /// </summary>
    private async Task<PropertyPolicy> GetPropertyModificationPolicyAsync(Guid propertyId, CancellationToken cancellationToken)
    {
        return await _unitOfWork.Repository<PropertyPolicy>()
            .FirstOrDefaultAsync(p => p.PropertyId == propertyId && p.Type == PolicyType.Modification, cancellationToken);
    }
}

/// <summary>
/// حدث تحديث الحجز
/// Booking updated event
/// </summary>
public class BookingUpdatedEvent : IBookingUpdatedEvent
{
    public Guid BookingId { get; set; }
    public Guid? UserId { get; set; }
    public Guid UnitId { get; set; }
    public DateTime UpdatedAt { get; set; }
    public Guid UpdatedBy { get; set; }
    public string[] UpdatedFields { get; set; }
    public DateTime OccurredAt { get; set; } = DateTime.UtcNow;
    public Guid EventId { get; set; } = Guid.NewGuid();
    public DateTime OccurredOn { get; set; } = DateTime.UtcNow;
    public string EventType { get; set; } = nameof(BookingUpdatedEvent);
    public int Version { get; set; } = 1;
    public string CorrelationId { get; set; }
    public DateTime? NewCheckIn { get; set; }
    public DateTime? NewCheckOut { get; set; }
    public int? NewGuestsCount { get; set; }
    public Money? NewTotalPrice { get; set; }
    public string NewStatus { get; set; }

}
