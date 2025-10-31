using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان سجل التدقيق
/// Audit log entity
/// </summary>
[Display(Name = "كيان سجل التدقيق")]
public class AuditLog : BaseEntity<Guid>
{
    /// <summary>
    /// نوع الكيان
    /// Entity type
    /// </summary>
    [Display(Name = "نوع الكيان")]
    public string EntityType { get; set; } = null!;

    /// <summary>
    /// معرف الكيان
    /// Entity ID
    /// </summary>
    [Display(Name = "معرف الكيان")]
    public Guid? EntityId { get; set; }

    /// <summary>
    /// الإجراء المتخذ
    /// Action performed
    /// </summary>
    [Display(Name = "الإجراء المتخذ")]
    public AuditAction Action { get; set; }

    /// <summary>
    /// القيم السابقة (JSON)
    /// Previous values (JSON)
    /// </summary>
    [Display(Name = "القيم السابقة")]
    public string? OldValues { get; set; }

    /// <summary>
    /// القيم الجديدة (JSON)
    /// New values (JSON)
    /// </summary>
    [Display(Name = "القيم الجديدة")]
    public string? NewValues { get; set; }

    /// <summary>
    /// معرف المستخدم الذي قام بالعملية
    /// User who performed the action
    /// </summary>
    [Display(Name = "معرف المستخدم الذي قام بالعملية")]
    public Guid? PerformedBy { get; set; }

    /// <summary>
    /// اسم المستخدم
    /// Username
    /// </summary>
    [Display(Name = "اسم المستخدم")]
    public string? Username { get; set; }

    /// <summary>
    /// عنوان IP
    /// IP Address
    /// </summary>
    [Display(Name = "عنوان IP")]
    public string? IpAddress { get; set; }

    /// <summary>
    /// وكيل المستخدم
    /// User agent
    /// </summary>
    [Display(Name = "وكيل المستخدم")]
    public string? UserAgent { get; set; }

    /// <summary>
    /// ملاحظات إضافية
    /// Additional notes
    /// </summary>
    [Display(Name = "ملاحظات إضافية")]
    public string? Notes { get; set; }

    /// <summary>
    /// معلومات إضافية (JSON)
    /// Additional metadata (JSON)
    /// </summary>
    [Display(Name = "معلومات إضافية")]
    public string? Metadata { get; set; }

    /// <summary>
    /// حالة العملية
    /// Operation status
    /// </summary>
    [Display(Name = "حالة العملية")]
    public bool IsSuccessful { get; set; } = true;

    /// <summary>
    /// رسالة الخطأ في حالة الفشل
    /// Error message if failed
    /// </summary>
    [Display(Name = "رسالة الخطأ في حالة الفشل")]
    public string? ErrorMessage { get; set; }

    /// <summary>
    /// مدة العملية بالمللي ثانية
    /// Operation duration in milliseconds
    /// </summary>
    [Display(Name = "مدة العملية بالمللي ثانية")]
    public long? DurationMs { get; set; }

    /// <summary>
    /// معرف الجلسة
    /// Session ID
    /// </summary>
    [Display(Name = "معرف الجلسة")]
    public string? SessionId { get; set; }

    /// <summary>
    /// معرف الطلب
    /// Request ID
    /// </summary>
    [Display(Name = "معرف الطلب")]
    public string? RequestId { get; set; }

    /// <summary>
    /// المصدر
    /// Source
    /// </summary>
    [Display(Name = "المصدر")]
    public string? Source { get; set; }

    /// <summary>
    /// المستخدم الذي قام بالعملية
    /// User who performed the action
    /// </summary>
    [Display(Name = "المستخدم الذي قام بالعملية")]
    public virtual User? PerformedByUser { get; set; }

    // Helper Methods

    /// <summary>
    /// إضافة معلومات إضافية
    /// Add metadata
    /// </summary>
    public void AddMetadata(string key, object value)
    {
        var metadata = string.IsNullOrEmpty(Metadata) 
            ? new Dictionary<string, object>() 
            : System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(Metadata) ?? new Dictionary<string, object>();
        
        metadata[key] = value;
        Metadata = System.Text.Json.JsonSerializer.Serialize(metadata);
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// الحصول على المعلومات الإضافية
    /// Get metadata
    /// </summary>
    public Dictionary<string, object>? GetMetadata()
    {
        if (string.IsNullOrEmpty(Metadata))
            return null;

        try
        {
            return System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(Metadata);
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// الحصول على القيم السابقة
    /// Get previous values
    /// </summary>
    public Dictionary<string, object>? GetOldValues()
    {
        if (string.IsNullOrEmpty(OldValues))
            return null;

        try
        {
            return System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(OldValues);
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// الحصول على القيم الجديدة
    /// Get new values
    /// </summary>
    public Dictionary<string, object>? GetNewValues()
    {
        if (string.IsNullOrEmpty(NewValues))
            return null;

        try
        {
            return System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(NewValues);
        }
        catch
        {
            return null;
        }
    }

    /// <summary>
    /// هل العملية فاشلة
    /// Is operation failed
    /// </summary>
    public bool IsFailed => !IsSuccessful;

    /// <summary>
    /// هل العملية استغرقت وقتاً طويلاً
    /// Is operation slow
    /// </summary>
    public bool IsSlowOperation => DurationMs.HasValue && DurationMs.Value > 5000; // أكثر من 5 ثوان
}


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