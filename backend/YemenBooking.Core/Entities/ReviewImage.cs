namespace YemenBooking.Core.Entities;

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

/// <summary>
/// كيان صورة التقييم
/// Review Image entity
/// </summary>
[Display(Name = "كيان صورة التقييم")]
public class ReviewImage : BaseEntity<Guid>
{
    /// <summary>
    /// معرف التقييم المرتبط
    /// Identifier of the related review
    /// </summary>
    [Display(Name = "معرف التقييم المرتبط")]
    public Guid ReviewId { get; set; }

    /// <summary>
    /// اسم الملف
    /// File name
    /// </summary>
    [Display(Name = "اسم الملف")]
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// مسار الصورة
    /// Image URL or path
    /// </summary>
    [Display(Name = "مسار الصورة")]
    public string Url { get; set; } = string.Empty;

    /// <summary>
    /// حجم الملف بالبايت
    /// File size in bytes
    /// </summary>
    [Display(Name = "حجم الملف بالبايت")]
    public long SizeBytes { get; set; }

    /// <summary>
    /// نوع المحتوى
    /// Content type or file type
    /// </summary>
    [Display(Name = "نوع المحتوى")]
    public string Type { get; set; } = string.Empty;

    /// <summary>
    /// فئة الصورة
    /// Image category
    /// </summary>
    [Display(Name = "فئة الصورة")]
    public ImageCategory Category { get; set; }

    /// <summary>
    /// تعليق توضيحي للصورة
    /// Image caption
    /// </summary>
    [Display(Name = "تعليق توضيحي للصورة")]
    public string Caption { get; set; } = string.Empty;

    /// <summary>
    /// نص بديل للصورة
    /// Alt text for the image
    /// </summary>
    [Display(Name = "نص بديل للصورة")]
    public string AltText { get; set; } = string.Empty;

    /// <summary>
    /// وسوم الصورة (JSON)
    /// Tags of the image in JSON
    /// </summary>
    [Display(Name = "وسوم الصورة")]
    public string Tags { get; set; } = string.Empty;

    /// <summary>
    /// هل هي الصورة الرئيسية
    /// Is main image
    /// </summary>
    [Display(Name = "هل هي الصورة الرئيسية")]
    public bool IsMain { get; set; } = false;

    /// <summary>
    /// ترتيب العرض
    /// Display order
    /// </summary>
    [Display(Name = "ترتيب العرض")]
    public int DisplayOrder { get; set; } = 0;

    /// <summary>
    /// تاريخ الرفع
    /// Upload date
    /// </summary>
    [Display(Name = "تاريخ الرفع")]
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// حالة الموافقة
    /// Approval status of the image
    /// </summary>
    [Display(Name = "حالة الموافقة")]
    public ImageStatus Status { get; set; } = ImageStatus.Pending;

    /// <summary>
    /// الكيان التابع للتقييم
    /// Navigation property to the review
    /// </summary>
    [Display(Name = "الكيان التابع للتقييم")]
    public virtual Review Review { get; set; }
} 