namespace YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Infrastructure.Services;

/// <summary>
/// DTO لنتيجة التصدير
/// Export result DTO
/// </summary>
public class ExportResultDto
{
    /// <summary>
    /// معرف التصدير
    /// Export ID
    /// </summary>
    public Guid ExportId { get; set; }
    
    /// <summary>
    /// اسم الملف
    /// File name
    /// </summary>
    public string FileName { get; set; } = null!;
    
    /// <summary>
    /// رابط تحميل الملف
    /// File download URL
    /// </summary>
    public string DownloadUrl { get; set; } = null!;
    
    /// <summary>
    /// تنسيق الملف
    /// File format
    /// </summary>
    public string FileFormat { get; set; } = null!; // Excel, PDF, CSV
    
    /// <summary>
    /// حجم الملف بالبايت
    /// File size in bytes
    /// </summary>
    public long FileSizeBytes { get; set; }
    
    /// <summary>
    /// حجم الملف مقروء
    /// Human readable file size
    /// </summary>
    public string FileSizeReadable { get; set; } = null!;
    
    /// <summary>
    /// نوع المحتوى
    /// Content type
    /// </summary>
    public string ContentType { get; set; } = null!;
    
    /// <summary>
    /// تاريخ الإنشاء
    /// Creation date
    /// </summary>
    public DateTime CreatedAt { get; set; }
    
    /// <summary>
    /// تاريخ انتهاء الصلاحية
    /// Expiry date
    /// </summary>
    public DateTime ExpiryDate { get; set; }
    
    /// <summary>
    /// معرف المستخدم الطالب للتصدير
    /// Requested by user ID
    /// </summary>
    public Guid RequestedBy { get; set; }
    
    /// <summary>
    /// اسم المستخدم الطالب للتصدير
    /// Requested by user name
    /// </summary>
    public string RequestedByName { get; set; } = null!;
    
    /// <summary>
    /// عدد السجلات المصدرة
    /// Exported records count
    /// </summary>
    public int RecordsCount { get; set; }
    
    /// <summary>
    /// الحقول المصدرة
    /// Exported fields
    /// </summary>
    public IEnumerable<string> ExportedFields { get; set; } = new List<string>();
    
    /// <summary>
    /// معايير التصفية المطبقة
    /// Applied filters
    /// </summary>
    public Dictionary<string, object>? AppliedFilters { get; set; }
    
    /// <summary>
    /// حالة التصدير
    /// Export status
    /// </summary>
    public string Status { get; set; } = "COMPLETED"; // PROCESSING, COMPLETED, FAILED, EXPIRED
    
    /// <summary>
    /// رسالة الحالة
    /// Status message
    /// </summary>
    public string? StatusMessage { get; set; }
    
    /// <summary>
    /// مدة معالجة التصدير
    /// Processing duration
    /// </summary>
    public TimeSpan ProcessingDuration { get; set; }
    
    /// <summary>
    /// معلومات إضافية عن التصدير
    /// Additional export metadata
    /// </summary>
    public ExportMetadataDto? Metadata { get; set; }
    
    /// <summary>
    /// تحذيرات التصدير
    /// Export warnings
    /// </summary>
    public IEnumerable<string>? Warnings { get; set; }
    
    /// <summary>
    /// هل يمكن إعادة تشغيل التصدير
    /// Can retry export
    /// </summary>
    public bool CanRetry { get; set; } = false;
    
    /// <summary>
    /// إعدادات الحماية
    /// Security settings
    /// </summary>
    public ExportSecurityDto? Security { get; set; }
}

/// <summary>
/// DTO لبيانات التصدير الوصفية
/// Export metadata DTO
/// </summary>
public class ExportMetadataDto
{
    /// <summary>
    /// إصدار نظام التصدير
    /// Export system version
    /// </summary>
    public string ExportSystemVersion { get; set; } = null!;
    
    /// <summary>
    /// إصدار قالب التصدير
    /// Export template version
    /// </summary>
    public string? TemplateVersion { get; set; }
    
    /// <summary>
    /// المنطقة الزمنية المستخدمة
    /// Timezone used
    /// </summary>
    public string Timezone { get; set; } = "UTC";
    
    /// <summary>
    /// الترميز المستخدم
    /// Encoding used
    /// </summary>
    public string Encoding { get; set; } = "UTF-8";
    
    /// <summary>
    /// اللغة المستخدمة
    /// Language used
    /// </summary>
    public string Language { get; set; } = "ar";
    
    /// <summary>
    /// العملة المستخدمة في التصدير
    /// Currency used in export
    /// </summary>
    public string? Currency { get; set; }
    
    /// <summary>
    /// تنسيق التاريخ المستخدم
    /// Date format used
    /// </summary>
    public string DateFormat { get; set; } = "yyyy-MM-dd";
    
    /// <summary>
    /// تنسيق الوقت المستخدم
    /// Time format used
    /// </summary>
    public string TimeFormat { get; set; } = "HH:mm:ss";
    
    /// <summary>
    /// الفاصل العشري المستخدم
    /// Decimal separator used
    /// </summary>
    public string DecimalSeparator { get; set; } = ".";
    
    /// <summary>
    /// فاصل الآلاف المستخدم
    /// Thousands separator used
    /// </summary>
    public string ThousandsSeparator { get; set; } = ",";
    
    /// <summary>
    /// معلومات إضافية مخصصة
    /// Custom additional information
    /// </summary>
    public Dictionary<string, object>? CustomMetadata { get; set; }
    
    /// <summary>
    /// مصدر البيانات
    /// Data source
    /// </summary>
    public string DataSource { get; set; } = null!;
    
    /// <summary>
    /// إصدار قاعدة البيانات وقت التصدير
    /// Database version at export time
    /// </summary>
    public string? DatabaseVersion { get; set; }
    
    /// <summary>
    /// نقطة زمنية للبيانات
    /// Data snapshot timestamp
    /// </summary>
    public DateTime DataSnapshotAt { get; set; }
}

/// <summary>
/// DTO لإعدادات أمان التصدير
/// Export security DTO
/// </summary>
public class ExportSecurityDto
{
    /// <summary>
    /// هل الملف محمي بكلمة مرور
    /// Is file password protected
    /// </summary>
    public bool IsPasswordProtected { get; set; } = false;
    
    /// <summary>
    /// مستوى التشفير
    /// Encryption level
    /// </summary>
    public string? EncryptionLevel { get; set; }
    
    /// <summary>
    /// نوع التشفير المستخدم
    /// Encryption type used
    /// </summary>
    public string? EncryptionType { get; set; }
    
    /// <summary>
    /// هل يحتوي على بيانات حساسة
    /// Contains sensitive data
    /// </summary>
    public bool ContainsSensitiveData { get; set; } = false;
    
    /// <summary>
    /// مستوى الخصوصية
    /// Privacy level
    /// </summary>
    public string PrivacyLevel { get; set; } = "PUBLIC"; // PUBLIC, INTERNAL, CONFIDENTIAL, RESTRICTED
    
    /// <summary>
    /// قيود الوصول
    /// Access restrictions
    /// </summary>
    public IEnumerable<string>? AccessRestrictions { get; set; }
    
    /// <summary>
    /// البيانات المحذوفة أو المقنعة
    /// Redacted or masked data
    /// </summary>
    public IEnumerable<string>? RedactedFields { get; set; }
    
    /// <summary>
    /// سياسة الاحتفاظ بالملف
    /// File retention policy
    /// </summary>
    public string? RetentionPolicy { get; set; }
    
    /// <summary>
    /// عدد مرات التحميل المسموحة
    /// Allowed download count
    /// </summary>
    public int? AllowedDownloads { get; set; }
    
    /// <summary>
    /// عدد مرات التحميل الحالي
    /// Current download count
    /// </summary>
    public int CurrentDownloadCount { get; set; } = 0;
}

/// <summary>
/// DTO لطلب التصدير
/// Export request DTO
/// </summary>
public class ExportRequestDto
{
    /// <summary>
    /// تنسيق التصدير
    /// Export format
    /// </summary>
    public string Format { get; set; } = "Excel"; // Excel, PDF, CSV, JSON
    
    /// <summary>
    /// الحقول المطلوب تصديرها
    /// Fields to export
    /// </summary>
    public IEnumerable<string>? Fields { get; set; }
    
    /// <summary>
    /// معايير التصفية
    /// Filter criteria
    /// </summary>
    public Dictionary<string, object>? Filters { get; set; }
    
    /// <summary>
    /// معايير الترتيب
    /// Sort criteria
    /// </summary>
    public IEnumerable<SortCriterionDto>? SortCriteria { get; set; }
    
    /// <summary>
    /// الحد الأقصى لعدد السجلات
    /// Maximum records limit
    /// </summary>
    public int? MaxRecords { get; set; }
    
    /// <summary>
    /// تضمين العناوين
    /// Include headers
    /// </summary>
    public bool IncludeHeaders { get; set; } = true;
    
    /// <summary>
    /// تضمين الصور
    /// Include images
    /// </summary>
    public bool IncludeImages { get; set; } = false;
    
    /// <summary>
    /// تضمين البيانات الوصفية
    /// Include metadata
    /// </summary>
    public bool IncludeMetadata { get; set; } = true;
    
    /// <summary>
    /// كلمة مرور الحماية
    /// Protection password
    /// </summary>
    public string? Password { get; set; }
    
    /// <summary>
    /// اللغة المطلوبة
    /// Required language
    /// </summary>
    public string Language { get; set; } = "ar";
    
    /// <summary>
    /// المنطقة الزمنية
    /// Timezone
    /// </summary>
    public string Timezone { get; set; } = "Asia/Aden";
    
    /// <summary>
    /// العملة المطلوبة
    /// Required currency
    /// </summary>
    public string? Currency { get; set; }
    
    /// <summary>
    /// إعدادات مخصصة للتصدير
    /// Custom export settings
    /// </summary>
    public Dictionary<string, object>? CustomSettings { get; set; }
    
    /// <summary>
    /// قالب التصدير المخصص
    /// Custom export template
    /// </summary>
    public string? CustomTemplate { get; set; }
    
    /// <summary>
    /// ملاحظات إضافية
    /// Additional notes
    /// </summary>
    public string? Notes { get; set; }
}

/// <summary>
/// DTO لمعيار الترتيب
/// Sort criterion DTO
/// </summary>
public class SortCriterionDto
{
    /// <summary>
    /// اسم الحقل
    /// Field name
    /// </summary>
    public string FieldName { get; set; } = null!;
    
    /// <summary>
    /// اتجاه الترتيب
    /// Sort direction
    /// </summary>
    public string Direction { get; set; } = "ASC"; // ASC, DESC
    
    /// <summary>
    /// أولوية الترتيب
    /// Sort priority
    /// </summary>
    public int Priority { get; set; } = 0;
}

/// <summary>
/// طلب التصدير
/// Export request
/// </summary>
public class ExportRequest
{
    /// <summary>
    /// البيانات المراد تصديرها
    /// Data to export
    /// </summary>
    public object Data { get; set; } = null!;

    /// <summary>
    /// التنسيق المطلوب
    /// Required format
    /// </summary>
    public string Format { get; set; } = "Excel";

    /// <summary>
    /// اسم الملف
    /// File name
    /// </summary>
    public string FileName { get; set; } = null!;

    /// <summary>
    /// تضمين العناوين
    /// Include headers
    /// </summary>
    public bool IncludeHeaders { get; set; } = true;

    /// <summary>
    /// الأعمدة المختارة
    /// Selected columns
    /// </summary>
    public string[]? Columns { get; set; }

    /// <summary>
    /// خصائص إضافية
    /// Additional properties
    /// </summary>
    public Dictionary<string, object>? PropertyDto { get; set; }
}