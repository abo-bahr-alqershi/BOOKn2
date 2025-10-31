using MediatR;
using System;
using YemenBooking.Application.Common.Models;
using System.Collections.Generic;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.SearchImages
{
    /// <summary>
    /// استعلام للبحث المتقدم في الصور وفق معايير متعددة
    /// Query for advanced image search with multiple filters
    /// </summary>
    public class SearchImagesQuery : IRequest<ResultDto<PaginatedResultDto<ImageDto>>>
    {
        /// <summary>
        /// تاريخ البداية (تصفية حسب تاريخ الرفع)
        /// Start date filter for uploaded date
        /// </summary>
        public DateTime? DateFrom { get; set; }

        /// <summary>
        /// تاريخ النهاية (تصفية حسب تاريخ الرفع)
        /// End date filter for uploaded date
        /// </summary>
        public DateTime? DateTo { get; set; }

        /// <summary>
        /// الحد الأدنى لحجم الصورة بالبايت
        /// Minimum image size (bytes)
        /// </summary>
        public long? MinSize { get; set; }

        /// <summary>
        /// الحد الأقصى لحجم الصورة بالبايت
        /// Maximum image size (bytes)
        /// </summary>
        public long? MaxSize { get; set; }

        /// <summary>
        /// الحد الأدنى للعرض
        /// Minimum width
        /// </summary>
        public int? MinWidth { get; set; }

        /// <summary>
        /// الحد الأقصى للعرض
        /// Maximum width
        /// </summary>
        public int? MaxWidth { get; set; }

        /// <summary>
        /// الحد الأدنى للارتفاع
        /// Minimum height
        /// </summary>
        public int? MinHeight { get; set; }

        /// <summary>
        /// الحد الأقصى للارتفاع
        /// Maximum height
        /// </summary>
        public int? MaxHeight { get; set; }

        /// <summary>
        /// أنواع ملفات محددة
        /// MIME types filter
        /// </summary>
        public List<string>? MimeTypes { get; set; }

        /// <summary>
        /// قائمة معرفات المستخدمين الذي رفعوا الصور
        /// Uploaded by user IDs
        /// </summary>
        public List<Guid>? UploadedBy { get; set; }

        /// <summary>
        /// العلامات المرتبطة
        /// Tags filter
        /// </summary>
        public List<string>? Tags { get; set; }

        /// <summary>
        /// جلب الصور الرئيسية فقط
        /// Primary images only flag
        /// </summary>
        public bool? PrimaryOnly { get; set; }

        /// <summary>
        /// رقم الصفحة
        /// Page number
        /// </summary>
        public int? Page { get; set; }

        /// <summary>
        /// حجم الصفحة
        /// Items per page
        /// </summary>
        public int? Limit { get; set; }
    }
} 