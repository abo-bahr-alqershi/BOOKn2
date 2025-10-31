namespace YemenBooking.Application.DTOs;

/// <summary>
/// DTO لحجم نسخة الصورة
/// Image variant size DTO
/// </summary>
public class ImageVariantSize
{
    /// <summary>
    /// اسم النسخة (مثل "Small", "Medium", "Large")
    /// Variant name (e.g., "Small", "Medium", "Large")
    /// </summary>
    public string Name { get; set; } = null!;

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
} 