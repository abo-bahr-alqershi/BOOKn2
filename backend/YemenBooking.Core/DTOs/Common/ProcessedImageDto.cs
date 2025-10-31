using System;

namespace YemenBooking.Application.DTOs;

/// <summary>
/// DTO للصور المعالجة بعد الرفع والتعديل
/// Processed image DTO after upload and modification
/// </summary>
public class ProcessedImageDto
{
    /// <summary>
    /// معرف الصورة (إذا كانت موجودة بالفعل)
    /// Image ID (if already exists)
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// اسم الملف الأصلي
    /// Original file name
    /// </summary>
    public string OriginalFileName { get; set; } = null!;

    /// <summary>
    /// اسم الملف المخزن
    /// Stored file name
    /// </summary>
    public string StoredFileName { get; set; } = null!;

    /// <summary>
    /// رابط الصورة الرئيسية
    /// Main image URL
    /// </summary>
    public string ImageUrl { get; set; } = null!;

    /// <summary>
    /// رابط الصورة المصغرة
    /// Thumbnail URL
    /// </summary>
    public string? ThumbnailUrl { get; set; }

    /// <summary>
    /// رابط نسخة WebP
    /// WebP URL
    /// </summary>
    public string? WebPUrl { get; set; }

    /// <summary>
    /// حجم الملف بالبايت
    /// File size in bytes
    /// </summary>
    public long FileSize { get; set; }

    /// <summary>
    /// عرض الصورة بالبكسل
    /// Image width in pixels
    /// </summary>
    public int Width { get; set; }

    /// <summary>
    /// ارتفاع الصورة بالبكسل
    /// Image height in pixels
    /// </summary>
    public int Height { get; set; }

    /// <summary>
    /// نوع الصورة (مثل "ROOM", "HOTEL", "USER")
    /// Image type (e.g., "ROOM", "HOTEL", "USER")
    /// </summary>
    public string ImageType { get; set; } = "ROOM";

    /// <summary>
    /// تعليق على الصورة
    /// Image caption
    /// </summary>
    public string? Caption { get; set; }

    /// <summary>
    /// نص بديل للصورة
    /// Image alt text
    /// </summary>
    public string? AltText { get; set; }

    /// <summary>
    /// ترتيب العرض
    /// Display order
    /// </summary>
    public int DisplayOrder { get; set; }

    /// <summary>
    /// هل هي الصورة الرئيسية
    /// Is primary image
    /// </summary>
    public bool IsPrimary { get; set; }
} 