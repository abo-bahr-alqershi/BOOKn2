using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع خدمات الحجز
/// Booking service repository interface
/// </summary>
public interface IBookingServiceRepository : IRepository<BookingService>
{
    /// <summary>
    /// إضافة خدمة إلى الحجز
    /// Add service to booking
    /// </summary>
    Task<BookingService> AddServiceToBookingAsync(BookingService bookingService, CancellationToken cancellationToken = default);

    /// <summary>
    /// إزالة خدمة من الحجز
    /// Remove service from booking
    /// </summary>
    Task<bool> RemoveServiceFromBookingAsync(Guid bookingId, Guid serviceId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على خدمات الحجز
    /// Get booking services
    /// </summary>
    Task<IEnumerable<BookingService>> GetBookingServicesAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث خدمة الحجز
    /// Update booking service
    /// </summary>
    Task<BookingService> UpdateBookingServiceAsync(BookingService bookingService, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على خدمة الحجز بواسطة المعرف
    /// Get booking service by id
    /// </summary>
    Task<BookingService?> GetBookingServiceByIdAsync(Guid bookingServiceId, CancellationToken cancellationToken = default);
}
