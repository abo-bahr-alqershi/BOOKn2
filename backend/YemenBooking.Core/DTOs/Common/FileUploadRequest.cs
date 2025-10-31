using System;

namespace YemenBooking.Application.DTOs;

/// <summary>
/// DTO لطلب تحميل ملف
/// File upload request DTO
/// </summary>
public class FileUploadRequest
{
    /// <summary>
    /// اسم الملف (بما في ذلك الامتداد)
    /// File name (including extension)
    /// </summary>
    public string FileName { get; set; } = null!;

    /// <summary>
    /// محتوى الملف كتيار بايت
    /// File content as byte stream
    /// </summary>
    public byte[] FileContent { get; set; } = null!;

    /// <summary>
    /// نوع محتوى الملف (MIME type)
    /// File content type (MIME type)
    /// </summary>
    public string ContentType { get; set; } = null!;

    /// <summary>
    /// المسار داخل مساحة التخزين (اختياري)
    /// Storage path (optional)
    /// </summary>
    public string? StoragePath { get; set; }

    /// <summary>
    /// هل يجب إنشاء صورة مصغرة
    /// Should generate thumbnail
    /// </summary>
    public bool GenerateThumbnail { get; set; } = false;

    /// <summary>
    /// هل يجب تحسين الصورة (ضغط، إلخ)
    /// Should optimize image (compression, etc.)
    /// </summary>
    public bool OptimizeImage { get; set; } = false;

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