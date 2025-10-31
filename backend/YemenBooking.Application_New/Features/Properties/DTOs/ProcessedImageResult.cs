using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace YemenBooking.Application.Features.Properties.DTOs
{
/// <summary>
/// فئة نتيجة معالجة الصورة - تستخدم من CreatePropertyImageCommandHandler
/// Processed image result class - uses from CreatePropertyImageCommandHandler
/// </summary>
public class ProcessedImageResult
{
    /// <summary>
    /// رابط الصورة المعالجة
    /// Processed image URL
    /// </summary>
    public string ProcessedUrl { get; set; } = string.Empty;

    /// <summary>
    /// رابط الصورة المصغرة
    /// Thumbnail URL
    /// </summary>
    public string ThumbnailUrl { get; set; } = string.Empty;

    /// <summary>
    /// حجم الملف بالبايت
    /// File size in bytes
    /// </summary>
    public long FileSize { get; set; }

    /// <summary>
    /// أبعاد الصورة
    /// Image dimensions
    /// </summary>
    public string Dimensions { get; set; } = string.Empty;

    /// <summary>
    /// نوع الملف
    /// MIME type
    /// </summary>
    public string MimeType { get; set; } = string.Empty;
}

}