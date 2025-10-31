namespace YemenBooking.Core.Enums;

/// <summary>
/// حالات المستخدم في النظام
/// User status in the system
/// </summary>
public enum UserStatus
{
    /// <summary>
    /// نشط - يمكن للمستخدم استخدام النظام بشكل طبيعي
    /// Active - User can use the system normally
    /// </summary>
    ACTIVE,
    
    /// <summary>
    /// غير نشط - المستخدم موجود لكن غير فعال
    /// Inactive - User exists but not active
    /// </summary>
    INACTIVE,
    
    /// <summary>
    /// معلق - منع مؤقت من استخدام النظام
    /// Suspended - Temporarily banned from using the system
    /// </summary>
    SUSPENDED,
    
    /// <summary>
    /// محظور - منع دائم من استخدام النظام
    /// Banned - Permanently banned from using the system
    /// </summary>
    BANNED,
    
    /// <summary>
    /// في انتظار التحقق - لم يتم التحقق من البريد الإلكتروني
    /// Pending Verification - Email not verified yet
    /// </summary>
    PENDING_VERIFICATION,
    
    /// <summary>
    /// محذوف - المستخدم محذوف من النظام
    /// Deleted - User is deleted from the system
    /// </summary>
    DELETED
}