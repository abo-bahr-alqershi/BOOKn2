using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using System.Collections.Generic;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Properties.Commands.UploadImages
{
    /// <summary>
    /// أمر لرفع صورة مع بيانات إضافية
    /// Command to upload an image with additional data
    /// </summary>
    public class UploadImageCommand : IRequest<ResultDto<ImageDto>>
    {
        /// <summary>
        /// مفتاح مؤقت لربط الصور قبل إنشاء السجل المرتبط
        /// Temporary key to associate images before entity/unit exists
        /// </summary>
        public string? TempKey { get; set; }

        /// <summary>
        /// الملف المراد رفعه
        /// The file to upload
        /// </summary>
        public FileUploadRequest File { get; set; } = null!;

        /// <summary>
        /// صورة مصغرة للفيديو يرسلها العميل (اختياري)
        /// Client-provided video thumbnail (optional)
        /// </summary>
        public FileUploadRequest? VideoThumbnail { get; set; }

        /// <summary>
        /// اسم الملف بدون امتداد
        /// File name without extension
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// امتداد الملف (مثل .jpg, .png)
        /// File extension (e.g. .jpg, .png)
        /// </summary>
        public string Extension { get; set; } = string.Empty;

        /// <summary>
        /// غرض الصورة (مراجعة، بروفايل، إدارة صور)
        /// Purpose of the image (Review, Profile, Management)
        /// </summary>
        public ImageType ImageType { get; set; }

        /// <summary>
        /// يشير إلى ما إذا كان يجب تحسين الصورة (ضغط)
        /// Indicates whether to optimize the image (compression)
        /// </summary>
        public bool OptimizeImage { get; set; } = false;

        /// <summary>
        /// جودة الصورة بعد التحسين (1-100)
        /// Quality of the image after optimization (1-100)
        /// </summary>
        public int? Quality { get; set; }

        /// <summary>
        /// يشير إلى ما إذا كان يجب إنشاء صورة مصغرة
        /// Indicates whether to generate a thumbnail
        /// </summary>
        public bool GenerateThumbnail { get; set; } = false;
        
        /// <summary>
        /// فئة الصورة
        /// Image category
        /// </summary>
        public ImageCategory Category { get; set; }

        /// <summary>
        /// معرف الكيان (اختياري)
        /// Property ID (optional)
        /// </summary>
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// معرف الوحدة (اختياري)
        /// Unit ID (optional)
        /// </summary>
        public Guid? UnitId { get; set; }

        /// <summary>
        /// معرف القسم (اختياري) لربط الصورة بقسم
        /// </summary>
        public Guid? SectionId { get; set; }

        /// <summary>
        /// معرف سجل عقار في قسم (اختياري)
        /// </summary>
        public Guid? PropertyInSectionId { get; set; }

        /// <summary>
        /// معرف سجل وحدة في قسم (اختياري)
        /// </summary>
        public Guid? UnitInSectionId { get; set; }

        /// <summary>
        /// اسم المدينة (اختياري)
        /// City name (optional)
        /// </summary>
        public string? CityName { get; set; }

        /// <summary>
        /// النص البديل للصورة
        /// Alt text (optional)
        /// </summary>
        public string? Alt { get; set; }

        /// <summary>
        /// هل هذه الصورة رئيسية
        /// Is primary image (optional)
        /// </summary>
        public bool? IsPrimary { get; set; }

        /// <summary>
        /// ترتيب العرض
        /// Display order (optional)
        /// </summary>
        public int? Order { get; set; }

        /// <summary>
        /// الوسوم المرتبطة بالصورة
        /// Tags (optional)
        /// </summary>
        public List<string>? Tags { get; set; }
    }
} 