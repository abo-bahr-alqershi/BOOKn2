using System;

namespace YemenBooking.Application.Features.Users.DTOs;

/// <summary>
/// DTO إحصائيات المستخدم
/// User statistics DTO
/// </summary>
public class UserStatisticsDto
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// تاريخ العضوية (إنشاء الحساب)
    /// Member since date
    /// </summary>
    public DateTime MemberSince
    {
        get => RegistrationDate;
        set => RegistrationDate = value;
    }

    /// <summary>
    /// إجمالي عدد الحجوزات
    /// Total bookings count
    /// </summary>
    public int TotalBookings { get; set; }

    /// <summary>
    /// عدد الحجوزات المكتملة
    /// Completed bookings count
    /// </summary>
    public int CompletedBookings { get; set; }

    /// <summary>
    /// عدد الحجوزات الملغاة
    /// Cancelled bookings count
    /// </summary>
    public int CancelledBookings { get; set; }

    /// <summary>
    /// عدد الحجوزات النشطة
    /// Active bookings count
    /// </summary>
    public int ActiveBookings { get; set; }

    /// <summary>
    /// إجمالي عدد المراجعات
    /// Total reviews count
    /// </summary>
    public int TotalReviews { get; set; }

    /// <summary>
    /// عدد المراجعات المكتوبة
    /// Reviews written
    /// </summary>
    public int ReviewsWritten { get; set; }

    /// <summary>
    /// متوسط تقييم المستخدم
    /// Average user rating
    /// </summary>
    public decimal AverageRating { get; set; }

    /// <summary>
    /// عدد المفضلات
    /// Favorites count
    /// </summary>
    public int FavoritesCount { get; set; }

    /// <summary>
    /// عدد العقارات المفضلة
    /// Favorite properties count
    /// </summary>
    public int FavoritePropertiesCount
    {
        get => FavoritesCount;
        set => FavoritesCount = value;
    }

    /// <summary>
    /// إجمالي المبلغ المدفوع
    /// Total amount spent
    /// </summary>
    public decimal TotalAmountSpent { get; set; }

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = "USD";

    /// <summary>
    /// إجمالي المبلغ المنفق
    /// Total spent amount
    /// </summary>
    public decimal TotalSpent
    {
        get => TotalAmountSpent;
        set => TotalAmountSpent = value;
    }

    /// <summary>
    /// إجمالي المبلغ الموفَر من الخصومات
    /// Total saved amount
    /// </summary>
    public decimal TotalSaved { get; set; }

    /// <summary>
    /// نقاط الولاء
    /// Loyalty points
    /// </summary>
    public int LoyaltyPoints { get; set; }

    /// <summary>
    /// مستوى الولاء
    /// Loyalty level
    /// </summary>
    public string LoyaltyLevel { get; set; } = "Bronze";

    /// <summary>
    /// عدد الإحالات
    /// Referrals count
    /// </summary>
    public int ReferralsCount { get; set; }

    /// <summary>
    /// تاريخ التسجيل
    /// Registration date
    /// </summary>
    public DateTime RegistrationDate { get; set; }

    /// <summary>
    /// تاريخ آخر حجز
    /// Last booking date
    /// </summary>
    public DateTime? LastBookingDate { get; set; }

    /// <summary>
    /// عدد أيام العضوية
    /// Membership days
    /// </summary>
    public int MembershipDays { get; set; }

    /// <summary>
    /// معدل الحجوزات الشهرية
    /// Monthly booking rate
    /// </summary>
    public decimal MonthlyBookingRate { get; set; }

    /// <summary>
    /// عدد المدن التي زارها المستخدم
    /// Cities visited
    /// </summary>
    public int CitiesVisited { get; set; }

    /// <summary>
    /// النسبة المئوية لإكمال الحجوزات
    /// BookingDto completion rate
    /// </summary>
    public decimal BookingCompletionRate { get; set; }

    /// <summary>
    /// النسبة المئوية لإلغاء الحجوزات
    /// BookingDto cancellation rate
    /// </summary>
    public decimal BookingCancellationRate { get; set; }

    /// <summary>
    /// متوسط قيمة الحجز
    /// Average booking value
    /// </summary>
    public decimal AverageBookingValue { get; set; }

    /// <summary>
    /// أكثر نوع عقار محجوز
    /// Most booked property type
    /// </summary>
    public string? MostBookedPropertyType { get; set; }

    /// <summary>
    /// أكثر مدينة محجوزة
    /// Most booked city
    /// </summary>
    public string? MostBookedCity { get; set; }
}
