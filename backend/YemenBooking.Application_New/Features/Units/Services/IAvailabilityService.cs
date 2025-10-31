using YemenBooking.Application.Features.Units.Commands.BulkOperations;

namespace YemenBooking.Application.Features.Units.Services;

/// <summary>
/// واجهة خدمة التوفر
/// Availability service interface
/// </summary>
public interface IAvailabilityService
{
    /// <summary>
    /// التحقق من توفر الوحدة لفترة زمنية محددة مع خيار استثناء حجز قائم
    /// Check unit availability for the given period with an optional booking exclusion
    /// </summary>
    Task<bool> CheckAvailabilityAsync(Guid unitId, DateTime checkIn, DateTime checkOut, Guid? excludeBookingId = null);

    /// <summary>
    /// حجز الفترة الخاصة بحجز جديد
    /// Block the specified period for a booking
    /// </summary>
    Task BlockForBookingAsync(Guid unitId, Guid bookingId, DateTime checkIn, DateTime checkOut);

    /// <summary>
    /// تحرير الحجز واسترجاع التوفر
    /// Release the booking block and restore availability
    /// </summary>
    Task ReleaseBookingAsync(Guid bookingId);

    /// <summary>
    /// الحصول على التقويم الشهري للتوفر
    /// Retrieve the monthly availability calendar for a unit
    /// </summary>
    Task<Dictionary<DateTime, string>> GetMonthlyCalendarAsync(Guid unitId, int year, int month);

    /// <summary>
    /// تطبيق تحديثات توفر مجمعة
    /// Apply bulk availability updates for a unit
    /// </summary>
    Task ApplyBulkAvailabilityAsync(Guid unitId, List<AvailabilityPeriodDto> periods);

    /// <summary>
    /// الحصول على الوحدات المتاحة في عقار خلال فترة محددة
    /// Get available unit identifiers for a property within the given period
    /// </summary>
    Task<IEnumerable<Guid>> GetAvailableUnitsInPropertyAsync(
        Guid propertyId,
        DateTime checkIn,
        DateTime checkOut,
        int guestCount,
        CancellationToken cancellationToken = default);
}