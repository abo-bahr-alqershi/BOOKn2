using System;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// DTO لبيانات صورة الكيان
    /// DTO for property image data
    /// </summary>
    public class PropertyImageDto
    {
        /// <summary>
        /// معرف الصورة
        /// Image identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// معرف الكيان (إن وجد)
        /// Property identifier (if assigned)
        /// </summary>
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// معرف الوحدة (إن وجد)
        /// Unit identifier (if assigned)
        /// </summary>
        public Guid? UnitId { get; set; }

        /// <summary>
        /// معرف القسم (إن وجد)
        /// Section identifier (if assigned)
        /// </summary>
        public Guid? SectionId { get; set; }

        /// <summary>
        /// ربط بسجل عقار في قسم (إن وجد)
        /// </summary>
        public Guid? PropertyInSectionId { get; set; }

        /// <summary>
        /// ربط بسجل وحدة في قسم (إن وجد)
        /// </summary>
        public Guid? UnitInSectionId { get; set; }

        /// <summary>
        /// اسم المدينة (إن وجد)
        /// </summary>
        public string? CityName { get; set; }

        /// <summary>
        /// اسم الملف
        /// File name
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// مسار الصورة
        /// Image URL
        /// </summary>
        public string Url { get; set; } = string.Empty;

        /// <summary>
        /// حجم الملف بالبايت
        /// Size in bytes
        /// </summary>
        public long SizeBytes { get; set; }

        /// <summary>
        /// نوع المحتوى
        /// Content type
        /// </summary>
        public string Type { get; set; } = string.Empty;

        /// <summary>
        /// فئة الصورة
        /// Image category
        /// </summary>
        public ImageCategory Category { get; set; }

        /// <summary>
        /// تعليق توضيحي للصورة
        /// Image caption
        /// </summary>
        public string Caption { get; set; } = string.Empty;

        /// <summary>
        /// نص بديل للصورة
        /// Image alt text
        /// </summary>
        public string AltText { get; set; } = string.Empty;

        /// <summary>
        /// وسوم الصورة (JSON)
        /// Image tags (JSON)
        /// </summary>
        public string Tags { get; set; } = string.Empty;

        /// <summary>
        /// أحجام الصورة (JSON)
        /// Image sizes (JSON) - mapping keys to URLs for different sizes (e.g. thumbnail, medium, large)
        /// </summary>
        public string Sizes { get; set; } = string.Empty;

        /// <summary>
        /// هل هي الصورة الرئيسية
        /// Is main image
        /// </summary>
        public bool IsMain { get; set; }

        /// <summary>
        /// ترتيب العرض
        /// Display order
        /// </summary>
        public int DisplayOrder { get; set; }

        /// <summary>
        /// تاريخ الرفع
        /// Upload date
        /// </summary>
        public DateTime UploadedAt { get; set; }

        /// <summary>
        /// حالة الصورة
        /// Image status
        /// </summary>
        public ImageStatus Status { get; set; }

        /// <summary>
        /// نوع ارتباط الصورة (Property أو Unit)
        /// Association type indicating whether the image is linked to a property or a unit
        /// </summary>
        public string AssociationType { get; set; } = string.Empty;
    }
} 