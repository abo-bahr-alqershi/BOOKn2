using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Application_New.Core.Enums;

/// <summary>
/// إجراء التدقيق
/// Audit action
/// </summary>
public enum AuditAction
{
    /// <summary>
    /// إنشاء
    /// Create
    /// </summary>
    [Display(Name = "إنشاء")]
    CREATE,
    
    /// <summary>
    /// تحديث
    /// Update
    /// </summary>
    [Display(Name = "تحديث")]
    UPDATE,
    
    /// <summary>
    /// حذف
    /// Delete
    /// </summary>
    [Display(Name = "حذف")]
    DELETE,
    
    /// <summary>
    /// حذف ناعم
    /// Soft delete
    /// </summary>
    [Display(Name = "حذف ناعم")]
    SOFT_DELETE,
    
    /// <summary>
    /// عرض
    /// View
    /// </summary>
    [Display(Name = "عرض")]
    VIEW,
    
    /// <summary>
    /// تسجيل دخول
    /// Login
    /// </summary>
    LOGIN,
    
    /// <summary>
    /// تسجيل خروج
    /// Logout
    /// </summary>
    LOGOUT,
    
    /// <summary>
    /// تغيير كلمة المرور
    /// Password change
    /// </summary>
    PASSWORD_CHANGE,
    
    /// <summary>
    /// إعادة تعيين كلمة المرور
    /// Password reset
    /// </summary>
    PASSWORD_RESET,
    
    /// <summary>
    /// تفعيل
    /// Activate
    /// </summary>
    ACTIVATE,
    
    /// <summary>
    /// إلغاء التفعيل
    /// Deactivate
    /// </summary>
    DEACTIVATE,
    
    /// <summary>
    /// موافقة
    /// Approve
    /// </summary>
    APPROVE,
    
    /// <summary>
    /// رفض
    /// Reject
    /// </summary>
    REJECT,
    
    /// <summary>
    /// تعليق
    /// Suspend
    /// </summary>
    SUSPEND,
    
    /// <summary>
    /// استيراد
    /// Import
    /// </summary>
    IMPORT,
    
    /// <summary>
    /// تصدير
    /// Export
    /// </summary>
    EXPORT
}
