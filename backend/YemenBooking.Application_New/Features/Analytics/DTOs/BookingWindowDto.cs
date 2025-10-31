using System;

namespace YemenBooking.Application.Features.Analytics.DTOs;

/// <summary>
/// بيانات تحليل نافذة الحجز
/// BookingDto window analysis data
/// </summary>
public class BookingWindowDto
{
    /// <summary>
    /// متوسط فترة الحجز بالأيام
    /// Average lead time in days
    /// </summary>
    public double AverageLeadTimeInDays { get; set; }

    /// <summary>
    /// عدد الحجوزات في اللحظة الأخيرة
    /// Bookings last minute count
    /// </summary>
    public int BookingsLastMinute { get; set; }
} 