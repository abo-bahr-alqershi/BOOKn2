using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Units.Commands.ReserveUnit;

/// <summary>
/// أمر الحجز المؤقت للوحدة للعميل
/// Command to temporarily reserve unit for client
/// </summary>
public class ClientReserveUnitCommand : IRequest<ResultDto<ClientUnitReservationResponse>>
{
    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid UnitId { get; set; }

    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// تاريخ بداية الحجز
    /// Check-in date
    /// </summary>
    public DateTime CheckInDate { get; set; }

    /// <summary>
    /// تاريخ نهاية الحجز
    /// Check-out date
    /// </summary>
    public DateTime CheckOutDate { get; set; }

    /// <summary>
    /// عدد البالغين
    /// Number of adults
    /// </summary>
    public int Adults { get; set; } = 1;

    /// <summary>
    /// عدد الأطفال
    /// Number of children
    /// </summary>
    public int Children { get; set; } = 0;

    /// <summary>
    /// مدة الحجز المؤقت بالدقائق (افتراضي 15 دقيقة)
    /// Reservation duration in minutes (default 15 minutes)
    /// </summary>
    public int ReservationDurationMinutes { get; set; } = 15;

    /// <summary>
    /// معرف الجلسة
    /// Session ID
    /// </summary>
    public string? SessionId { get; set; }

    /// <summary>
    /// ملاحظات خاصة
    /// Special notes
    /// </summary>
    public string? SpecialNotes { get; set; }
}

/// <summary>
/// استجابة الحجز المؤقت للوحدة
/// Unit reservation response
/// </summary>
public class ClientUnitReservationResponse
{
    /// <summary>
    /// معرف الحجز المؤقت
    /// Reservation ID
    /// </summary>
    public Guid ReservationId { get; set; }

    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid UnitId { get; set; }

    /// <summary>
    /// اسم الوحدة
    /// Unit name
    /// </summary>
    public string UnitName { get; set; } = string.Empty;

    /// <summary>
    /// تاريخ انتهاء الحجز المؤقت
    /// Reservation expiry date
    /// </summary>
    public DateTime ExpiresAt { get; set; }

    /// <summary>
    /// السعر الإجمالي
    /// Total price
    /// </summary>
    public decimal TotalPrice { get; set; }

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = "YER";

    /// <summary>
    /// رمز الحجز المؤقت
    /// Reservation token
    /// </summary>
    public string ReservationToken { get; set; } = string.Empty;

    /// <summary>
    /// حالة الحجز المؤقت
    /// Reservation status
    /// </summary>
    public string Status { get; set; } = "Active";

    /// <summary>
    /// وقت الإنشاء
    /// Created time
    /// </summary>
    public DateTime CreatedAt { get; set; }
}