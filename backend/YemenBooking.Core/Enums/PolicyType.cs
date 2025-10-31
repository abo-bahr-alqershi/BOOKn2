namespace YemenBooking.Core.Enums;

/// <summary>
/// تعداد أنواع السياسات
/// Policy Types enumeration
/// </summary>
public enum PolicyType
{
    /// <summary>
    /// إلغاء
    /// Cancellation
    /// </summary>
    Cancellation,
    
    /// <summary>
    /// دخول
    /// Check-in
    /// </summary>
    CheckIn,
    
    /// <summary>
    /// أطفال
    /// Children
    /// </summary>
    Children,
    
    /// <summary>
    /// حيوانات
    /// Pets
    /// </summary>
    Pets,
    
    /// <summary>
    /// سياسة الدفع
    /// Payment policy
    /// </summary>
    Payment,
    
    /// <summary>
    /// سياسة التعديل
    /// Modification policy
    /// </summary>
    Modification
} 