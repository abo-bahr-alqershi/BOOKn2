namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

/// <summary>
/// صورة لسجل "عقار في قسم" فقط
/// </summary>
[Display(Name = "صورة عقار في قسم")]
public class PropertyInSectionImage : BaseEntity<Guid>
{
    [Display(Name = "المفتاح المؤقت")]
    public string? TempKey { get; set; }

    [Display(Name = "معرف عقار في قسم")]
    public Guid? PropertyInSectionId { get; set; }

    [Display(Name = "عقار في قسم")]
    public virtual PropertyInSection? PropertyInSection { get; set; }

    // Common fields
    [Display(Name = "اسم الصورة")]
    public string Name { get; set; } = string.Empty;

    [Display(Name = "رابط الصورة")]
    public string Url { get; set; } = string.Empty;

    [Display(Name = "الحجم بالبايت")]
    public long SizeBytes { get; set; }

    [Display(Name = "النوع")]
    public string Type { get; set; } = string.Empty;

    [Display(Name = "الفئة")]
    public ImageCategory Category { get; set; }

    [Display(Name = "عنوان")]
    public string Caption { get; set; } = string.Empty;

    [Display(Name = "بديل")]
    public string AltText { get; set; } = string.Empty;

    [Display(Name = "أحجام/مصغرات")]
    public string? Sizes { get; set; }

    [Display(Name = "صورة رئيسية")]
    public bool IsMainImage { get; set; }

    [Display(Name = "ترتيب")]
    public int DisplayOrder { get; set; }

    [Display(Name = "تاريخ الرفع")]
    public DateTime UploadedAt { get; set; }

    [Display(Name = "الحالة")]
    public ImageStatus Status { get; set; }

    // Media extras
    [Display(Name = "نوع الوسائط")]
    public string MediaType { get; set; } = "image";

    [Display(Name = "مدة الفيديو")]
    public int? DurationSeconds { get; set; }

    [Display(Name = "مصغّرة الفيديو")]
    public string? VideoThumbnailUrl { get; set; }

    [Display(Name = "وسوم")]
    public string Tags { get; set; } = string.Empty;
}

