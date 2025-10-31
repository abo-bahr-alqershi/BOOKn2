namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

/// <summary>
/// صورة خاصة بكيان القسم فقط
/// Dedicated image entity for Section
/// </summary>
[Display(Name = "صورة قسم")]
public class SectionImage : BaseEntity<Guid>
{
    [Display(Name = "المفتاح المؤقت")]
    public string? TempKey { get; set; }

    [Display(Name = "معرف القسم")]
    public Guid? SectionId { get; set; }

    [Display(Name = "القسم")]
    public virtual Section? Section { get; set; }

    // Common media fields (mirrors PropertyImage where applicable)
    [Display(Name = "اسم الصورة")]
    public string Name { get; set; } = string.Empty;

    [Display(Name = "رابط الصورة")]
    public string Url { get; set; } = string.Empty;

    [Display(Name = "حجم الصورة بالبايت")]
    public long SizeBytes { get; set; }

    [Display(Name = "نوع الصورة")]
    public string Type { get; set; } = string.Empty;

    [Display(Name = "فئة الصورة")]
    public ImageCategory Category { get; set; }

    [Display(Name = "تسمية توضيحية")]
    public string Caption { get; set; } = string.Empty;

    [Display(Name = "نص بديل")]
    public string AltText { get; set; } = string.Empty;

    /// <summary>
    /// أحجام الصورة (قد يُخزن رابط مصغّر أو JSON)
    /// </summary>
    [Display(Name = "أحجام الصورة")]
    public string? Sizes { get; set; }

    [Display(Name = "هل هي الصورة الرئيسية")]
    public bool IsMainImage { get; set; }

    [Display(Name = "ترتيب العرض")]
    public int DisplayOrder { get; set; }

    [Display(Name = "تاريخ الرفع")]
    public DateTime UploadedAt { get; set; }

    [Display(Name = "حالة المعالجة")]
    public ImageStatus Status { get; set; }

    // Media extras
    [Display(Name = "نوع الوسائط")]
    public string MediaType { get; set; } = "image";

    [Display(Name = "مدة الفيديو بالثواني")]
    public int? DurationSeconds { get; set; }

    [Display(Name = "مصغّرة الفيديو")]
    public string? VideoThumbnailUrl { get; set; }

    [Display(Name = "وسوم")]
    public string Tags { get; set; } = string.Empty;
}

