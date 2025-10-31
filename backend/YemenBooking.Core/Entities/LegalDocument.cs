using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان المستند القانوني
/// Legal document entity
/// </summary>
public class LegalDocument
{
    /// <summary>
    /// معرف المستند
    /// Document ID
    /// </summary>
    [Key]
    public Guid Id { get; set; }

    /// <summary>
    /// نوع المستند القانوني
    /// Legal document type
    /// </summary>
    [Required]
    public LegalDocumentType Type { get; set; }

    /// <summary>
    /// اللغة
    /// Language
    /// </summary>
    [Required]
    [MaxLength(10)]
    public string Language { get; set; } = "ar";

    /// <summary>
    /// عنوان المستند
    /// Document title
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    /// <summary>
    /// محتوى المستند
    /// Document content
    /// </summary>
    [Required]
    public string Content { get; set; } = string.Empty;

    /// <summary>
    /// إصدار المستند
    /// Document version
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Version { get; set; } = "1.0";

    /// <summary>
    /// تاريخ النفاذ
    /// Effective date
    /// </summary>
    public DateTime EffectiveDate { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// هل المستند نشط
    /// Is document active
    /// </summary>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// تاريخ الإنشاء
    /// Creation date
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// تاريخ آخر تحديث
    /// Last update date
    /// </summary>
    public DateTime? UpdatedAt { get; set; }

    /// <summary>
    /// معرف المستخدم المنشئ
    /// Creator user ID
    /// </summary>
    public Guid? CreatedBy { get; set; }

    /// <summary>
    /// معرف المستخدم المحدث
    /// Updater user ID
    /// </summary>
    public Guid? UpdatedBy { get; set; }
}
