using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
// using YemenBooking.Application.Features.Statistics; // مؤقتاً حتى يتم إنشاء هذا المجلد
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Bookings.Queries.GetUserBookingSummarySummary;

/// <summary>
/// استعلام الحصول على ملخص حجوزات المستخدم حسب الفترة
/// Query to get user booking summary by period
/// </summary>
public class GetUserBookingSummaryQuery : IRequest<ResultDto<UserBookingSummaryDto>>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// السنة (اختياري)
    /// </summary>
    public int? Year { get; set; }
}

/// <summary>
/// بيانات ملخص حجوزات المستخدم
/// </summary>
public class UserBookingSummaryDto
{
    /// <summary>
    /// ملخص الحجوزات الشهرية
    /// </summary>
    public List<MonthlyBookingSummaryDto> MonthlyBookings { get; set; } = new();
    
    /// <summary>
    /// أكثر الكيانات حجزًا
    /// </summary>
    public List<PropertyBookingFrequencyDto> TopBookedProperties { get; set; } = new();
    
    /// <summary>
    /// أكثر المدن زيارة
    /// </summary>
    public List<CityVisitFrequencyDto> TopVisitedCities { get; set; } = new();
}

/// <summary>
/// ملخص الحجوزات الشهرية
/// </summary>
public class MonthlyBookingSummaryDto
{
    /// <summary>
    /// الشهر
    /// </summary>
    public int Month { get; set; }
    
    /// <summary>
    /// السنة
    /// </summary>
    public int Year { get; set; }
    
    /// <summary>
    /// عدد الحجوزات
    /// </summary>
    public int BookingsCount { get; set; }
    
    /// <summary>
    /// المبلغ المنفق
    /// </summary>
    public decimal AmountSpent { get; set; }
}

/// <summary>
/// تكرار حجز كيان
/// </summary>
public class PropertyBookingFrequencyDto
{
    /// <summary>
    /// اسم الكيان
    /// </summary>
    public string PropertyName { get; set; } = string.Empty;
    
    /// <summary>
    /// المدينة
    /// </summary>
    public string City { get; set; } = string.Empty;
    
    /// <summary>
    /// عدد مرات الحجز
    /// </summary>
    public int BookingsCount { get; set; }
}

/// <summary>
/// تكرار زيارة مدينة
/// </summary>
public class CityVisitFrequencyDto
{
    /// <summary>
    /// اسم المدينة
    /// </summary>
    public string CityName { get; set; } = string.Empty;
    
    /// <summary>
    /// عدد الزيارات
    /// </summary>
    public int VisitsCount { get; set; }
}