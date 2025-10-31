using YemenBooking.Core.Entities;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع الحجوزات
/// Booking repository interface
/// </summary>
public interface IBookingRepository : IRepository<Booking>
{
    /// <summary>
    /// إنشاء حجز جديد
    /// Create new booking
    /// </summary>
    Task<Booking> CreateBookingAsync(Booking booking, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على حجز بواسطة المعرف
    /// Get booking by id
    /// </summary>
    Task<Booking?> GetBookingByIdAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الحجز مع الخدمات
    /// Get booking with services
    /// </summary>
    Task<Booking?> GetBookingWithServicesAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الحجز مع المدفوعات
    /// Get booking with payments
    /// </summary>
    Task<Booking?> GetBookingWithPaymentsAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث الحجز
    /// Update booking
    /// </summary>
    Task<Booking> UpdateBookingAsync(Booking booking, CancellationToken cancellationToken = default);

    /// <summary>
    /// تأكيد الحجز
    /// Confirm booking
    /// </summary>
    Task<bool> ConfirmBookingAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// إلغاء الحجز
    /// Cancel booking
    /// </summary>
    Task<bool> CancelBookingAsync(Guid bookingId, string reason, CancellationToken cancellationToken = default);

    /// <summary>
    /// إكمال الحجز
    /// Complete booking
    /// </summary>
    Task<bool> CompleteBookingAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود حجوزات نشطة
    /// Check active bookings
    /// </summary>
    Task<bool> CheckActiveBookingsAsync(Guid unitId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الحجوزات المتضاربة مع الفترة
    /// Get bookings that conflict with given period
    /// </summary>
    Task<IEnumerable<Booking>> GetConflictingBookingsAsync(Guid unitId, DateTime checkIn, DateTime checkOut, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على حجوزات المستخدم
    /// Get bookings by user
    /// </summary>
    Task<IEnumerable<Booking>> GetBookingsByUserAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على حجوزات الكيان
    /// Get bookings by property
    /// </summary>
    Task<IEnumerable<Booking>> GetBookingsByPropertyAsync(Guid propertyId, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على حجوزات الوحدة
    /// Get bookings by unit
    /// </summary>
    Task<IEnumerable<Booking>> GetBookingsByUnitAsync(Guid unitId, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الحجوزات حسب الحالة
    /// Get bookings by status
    /// </summary>
    Task<IEnumerable<Booking>> GetBookingsByStatusAsync(BookingStatus status, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الحجوزات في فترة زمنية
    /// Get bookings by date range
    /// </summary>
    Task<IEnumerable<Booking>> GetBookingsByDateRangeAsync(DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على خدمات الحجز
    /// Get booking services
    /// </summary>
    Task<IEnumerable<BookingService>> GetBookingServicesAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// إضافة خدمة للحجز
    /// Add service to booking
    /// </summary>
    Task<bool> AddServiceToBookingAsync(Guid bookingId, Guid serviceId, int quantity = 1, CancellationToken cancellationToken = default);

    /// <summary>
    /// إزالة خدمة من الحجز
    /// Remove service from booking
    /// </summary>
    Task<bool> RemoveServiceFromBookingAsync(Guid bookingId, Guid serviceId, CancellationToken cancellationToken = default);

    /// <summary>
    /// إعادة حساب السعر
    /// Recalculate price
    /// </summary>
    Task<decimal> RecalculatePriceAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// إجمالي عدد الحجوزات ضمن فترة محددة (اختياريًا حسب الكيان)
    /// Get total bookings count for date range and optional property
    /// </summary>
    Task<int> GetTotalBookingsCountAsync(Guid? propertyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default);

    /// <summary>
    /// إجمالي الإيرادات ضمن فترة محددة (اختياريًا حسب الكيان)
    /// Get total revenue for date range and optional property
    /// </summary>
    Task<decimal> GetTotalRevenueAsync(Guid? propertyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الحجوزات القادمة (Check-ins) الخاصة بالكيان خلال الأيام القادمة
    /// Get upcoming check-ins for a property within specified days
    /// </summary>
    Task<IEnumerable<Booking>> GetUpcomingCheckInsAsync(Guid propertyId, int days, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على تاريخ أول حجز لكل مستخدم
    /// Get first booking date for each user
    /// </summary>
    Task<Dictionary<Guid, DateTime>> GetFirstBookingDateForUsersAsync(IEnumerable<Guid> userIds, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على إجمالي عمولة المنصة ضمن نطاق زمني
    /// Get total platform commission within a date range
    /// </summary>
    Task<decimal> GetTotalCommissionAsync(DateTime startDate, DateTime endDate, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على ملخص أسباب الإلغاء ضمن نطاق زمني
    /// Get summary of cancellation reasons within a date range
    /// </summary>
    Task<IEnumerable<CancellationReasonSummary>> GetCancellationReasonsSummaryAsync(DateTime startDate, DateTime endDate, CancellationToken cancellationToken = default);
}
