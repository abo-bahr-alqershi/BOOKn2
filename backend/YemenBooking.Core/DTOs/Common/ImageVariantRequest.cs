using System.Collections.Generic;

namespace YemenBooking.Application.DTOs;

/// <summary>
/// DTO لطلب إنشاء نسخ مختلفة من الصورة
/// Image variant request DTO
/// </summary>
public class ImageVariantRequest
{
    /// <summary>
    /// رابط الصورة الأصلية
    /// Original image URL
    /// </summary>
    public string ImageUrl { get; set; } = null!;

    /// <summary>
    /// قائمة بالأحجام المطلوبة للنسخ
    /// List of requested variant sizes
    /// </summary>
    public List<ImageVariantSize> Sizes { get; set; } = new();

    /// <summary>
    /// هل يجب إنشاء نسخة WebP لكل حجم
    /// Should generate WebP version for each size
    /// </summary>
    public bool GenerateWebP { get; set; } = false;
} 