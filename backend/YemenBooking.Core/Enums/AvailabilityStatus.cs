namespace YemenBooking.Core.Enums;

/// <summary>
/// تعداد حالات الإتاحة
/// Availability Status enumeration
/// </summary>
public static class AvailabilityStatus
{
    /// <summary>
    /// متاح
    /// Available
    /// </summary>
    public const string Available = "Available";
    
    /// <summary>
    /// محجوز
    /// Booked
    /// </summary>
    public const string Booked = "Booked";
    
    /// <summary>
    /// محظور
    /// Blocked
    /// </summary>
    public const string Blocked = "Blocked";
    
    /// <summary>
    /// صيانة
    /// Maintenance
    /// </summary>
    public const string Maintenance = "Maintenance";
    
    /// <summary>
    /// استخدام المالك
    /// Owner Use
    /// </summary>
    public const string OwnerUse = "OwnerUse";
    
    /// <summary>
    /// التحقق من صحة الحالة
    /// Validate status value
    /// </summary>
    public static bool IsValidStatus(string status)
    {
        return status == Available || 
               status == Booked || 
               status == Blocked || 
               status == Maintenance || 
               status == OwnerUse;
    }
    
    /// <summary>
    /// الحصول على جميع الحالات
    /// Get all statuses
    /// </summary>
    public static string[] GetAllStatuses()
    {
        return new[] { Available, Booked, Blocked, Maintenance, OwnerUse };
    }
}
