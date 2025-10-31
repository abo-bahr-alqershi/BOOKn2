using System;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Reviews.DTOs {
    /// <summary>
    /// DTO لصورة التقييم
    /// DTO for review image
    /// </summary>
    public class ReviewImageDto
    {
        /// <summary>
        /// معرف الصورة
        /// Image identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// معرف التقييم
        /// Review identifier
        /// </summary>
        public Guid ReviewId { get; set; }

        /// <summary>
        /// اسم الملف
        /// File name
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// رابط الصورة
        /// Image URL
        /// </summary>
        public string Url { get; set; } = string.Empty;

        /// <summary>
        /// حجم الصورة بالبايت
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
        /// Alt text
        /// </summary>
        public string AltText { get; set; } = string.Empty;

        /// <summary>
        /// تاريخ الرفع
        /// Upload date
        /// </summary>
        public DateTime UploadedAt { get; set; }
    }
} 