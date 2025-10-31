using System;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// إعدادات معالجة الصورة
    /// Image processing settings DTO matching front-end ImageProcessingSettings
    /// </summary>
    public class ImageProcessingSettingsDto
    {
        /// <summary>
        /// جودة الضغط (1-100)
        /// Compression quality
        /// </summary>
        public int Quality { get; set; }

        /// <summary>
        /// الحد الأقصى للعرض
        /// Max width
        /// </summary>
        public int MaxWidth { get; set; }

        /// <summary>
        /// الحد الأقصى للارتفاع
        /// Max height
        /// </summary>
        public int MaxHeight { get; set; }

        /// <summary>
        /// تنسيق الإخراج (jpeg, png, webp)
        /// Output format
        /// </summary>
        public string Format { get; set; } = string.Empty;

        /// <summary>
        /// إنشاء مصغرات إضافية
        /// Generate thumbnails
        /// </summary>
        public bool GenerateThumbnails { get; set; }

        /// <summary>
        /// إزالة بيانات EXIF
        /// Strip EXIF data
        /// </summary>
        public bool StripExif { get; set; }
    }
} 