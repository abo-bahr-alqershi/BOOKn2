using System;
using System.Collections.Generic;

namespace YemenBooking.Application.DTOs;

/// <summary>
/// DTO لطلب معالجة الصورة
/// Image processing request DTO
/// </summary>
public class ImageProcessingRequest
{
    /// <summary>
    /// رابط الصورة الأصلية
    /// Original image URL
    /// </summary>
    public string ImageUrl { get; set; } = null!;

    /// <summary>
    /// هل يجب إنشاء صورة مصغرة
    /// Should generate thumbnail
    /// </summary>
    public bool GenerateThumbnail { get; set; } = false;

    /// <summary>
    /// حجم الصورة المصغرة (إذا تم إنشاؤها)
    /// Thumbnail size (if generated)
    /// </summary>
    public ImageVariantSize? ThumbnailSize { get; set; }

    /// <summary>
    /// هل يجب تحسين جودة الصورة
    /// Should optimize image quality
    /// </summary>
    public bool OptimizeQuality { get; set; } = false;

    /// <summary>
    /// جودة الصورة المحسنة (1-100)
    /// Quality of optimized image (1-100)
    /// </summary>
    public int? Quality { get; set; }

    /// <summary>
    /// هل يجب إنشاء نسخة WebP
    /// Should generate WebP version
    /// </summary>
    public bool GenerateWebP { get; set; } = false;
} 