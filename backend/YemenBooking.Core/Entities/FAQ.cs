using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان الأسئلة الشائعة
/// FAQ entity
/// </summary>
public class FAQ
{
    /// <summary>
    /// معرف السؤال
    /// FAQ ID
    /// </summary>
    [Key]
    public Guid Id { get; set; }

    /// <summary>
    /// السؤال
    /// Question
    /// </summary>
    [Required]
    [MaxLength(500)]
    public string Question { get; set; } = string.Empty;

    /// <summary>
    /// الإجابة
    /// Answer
    /// </summary>
    [Required]
    public string Answer { get; set; } = string.Empty;

    /// <summary>
    /// فئة السؤال
    /// Question category
    /// </summary>
    [MaxLength(100)]
    public string? Category { get; set; }

    /// <summary>
    /// اللغة
    /// Language
    /// </summary>
    [Required]
    [MaxLength(10)]
    public string Language { get; set; } = "ar";

    /// <summary>
    /// ترتيب العرض
    /// Display order
    /// </summary>
    public int DisplayOrder { get; set; }

    /// <summary>
    /// هل السؤال نشط
    /// Is FAQ active
    /// </summary>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// عدد المشاهدات
    /// View count
    /// </summary>
    public int ViewCount { get; set; } = 0;

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
