namespace YemenBooking.Core.Enums;

/// <summary>
/// تعداد حالات الحجز
/// Booking Status enumeration
/// </summary>
public enum BookingStatus
{
    /// <summary>
    /// مؤكد
    /// Confirmed
    /// </summary>
    Confirmed,
    
    /// <summary>
    /// معلق
    /// Pending
    /// </summary>
    Pending,
    
    /// <summary>
    /// ملغى
    /// Cancelled
    /// </summary>
    Cancelled,
    
    /// <summary>
    /// مكتمل
    /// Completed
    /// </summary>
    Completed,
    
    /// <summary>
    /// تسجيل الوصول
    /// Checked-in
    /// </summary>
    CheckedIn
} 