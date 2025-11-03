// using YemenBooking.Core.Entities;

// namespace YemenBooking.Core.Interfaces.Repositories;

// /// <summary>
// /// واجهة مستودع توفر الوحدات
// /// Unit availability repository interface
// /// </summary>
// public interface IUnitAvailabilityRepository : IRepository<UnitAvailability>
// {
//     /// <summary>
//     /// تحديث توفر الوحدة
//     /// Update unit availability
//     /// </summary>
//     Task<bool> UpdateAvailabilityAsync(
//         Guid unitId,
//         DateTime fromDate,
//         DateTime toDate,
//         bool isAvailable,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// الحصول على توفر الوحدة
//     /// Get unit availability
//     /// </summary>
//     Task<IDictionary<DateTime, bool>> GetUnitAvailabilityAsync(
//         Guid unitId,
//         DateTime fromDate,
//         DateTime toDate,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// التحقق من توفر الوحدة
//     /// Check unit availability
//     /// </summary>
//     Task<bool> IsUnitAvailableAsync(
//         Guid unitId,
//         DateTime checkIn,
//         DateTime checkOut,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// حجز فترة للوحدة
//     /// Block unit period
//     /// </summary>
//     Task<bool> BlockUnitPeriodAsync(
//         Guid unitId,
//         DateTime fromDate,
//         DateTime toDate,
//         string reason,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// إلغاء حجز فترة للوحدة
//     /// Unblock unit period
//     /// </summary>
//     Task<bool> UnblockUnitPeriodAsync(
//         Guid unitId,
//         DateTime fromDate,
//         DateTime toDate,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// التحقق من تداخل الفترات
//     /// Check for date range overlap
//     /// </summary>
//     Task<bool> HasOverlapAsync(
//         Guid unitId,
//         DateTime fromDate,
//         DateTime toDate,
//         Guid? excludeAvailabilityId = null,
//         CancellationToken cancellationToken = default);
// }

using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Core.Interfaces.Repositories;

public interface IUnitAvailabilityRepository : IRepository<UnitAvailability>
{
    Task<IEnumerable<UnitAvailability>> GetByUnitIdAsync(Guid unitId, DateTime? startDate = null, DateTime? endDate = null);
    Task<IEnumerable<UnitAvailability>> GetByDateRangeAsync(Guid unitId, DateTime startDate, DateTime endDate);
    Task<bool> IsUnitAvailableAsync(Guid unitId, DateTime startDate, DateTime endDate, Guid? excludeBookingId = null);
    Task<IEnumerable<UnitAvailability>> GetBlockedPeriodsAsync(Guid unitId, int year, int month);
    Task BulkCreateAsync(IEnumerable<UnitAvailability> availabilities);
    Task BulkUpdateAsync(IEnumerable<UnitAvailability> availabilities);
    Task DeleteRangeAsync(Guid unitId, DateTime startDate, DateTime endDate);
    Task<Dictionary<DateTime, string>> GetAvailabilityCalendarAsync(Guid unitId, int year, int month);

    /// <summary>
    /// احسب فترات الإتاحة القابلة للحجز ضمن نافذة زمنية محددة بدمج الجدولة والحجوزات
    /// Compute bookable availability ranges between start and end, merging schedules and bookings
    /// </summary>
    Task<List<(DateTime Start, DateTime End)>> ComputeAvailableRangesAsync(
        Guid unitId,
        DateTime startDate,
        DateTime endDate,
        CancellationToken cancellationToken = default);
}