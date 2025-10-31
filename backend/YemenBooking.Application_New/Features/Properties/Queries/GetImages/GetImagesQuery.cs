using MediatR;
using System;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Models;
using System.Collections.Generic;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.GetImages
{
    /// <summary>
    /// استعلام للحصول على قائمة الصور مع الفلترة والصفحات
    /// Query to get list of images with filters and pagination
    /// </summary>
    public class GetImagesQuery : IRequest<ResultDto<PaginatedResultDto<ImageDto>>>
    {
        /// <summary>
        /// مفتاح مؤقت لتجميع الصور قبل الربط
        /// Temporary key to group images prior to binding
        /// </summary>
        public string? TempKey { get; set; }

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
        /// معرف القسم (اختياري)
        /// Section ID (optional)
        /// </summary>
        public Guid? SectionId { get; set; }

        /// <summary>
        /// معرف سجل عقار في قسم (اختياري)
        /// PropertyInSection ID (optional)
        /// </summary>
        public Guid? PropertyInSectionId { get; set; }

        /// <summary>
        /// معرف سجل وحدة في قسم (اختياري)
        /// UnitInSection ID (optional)
        /// </summary>
        public Guid? UnitInSectionId { get; set; }

        /// <summary>
        /// اسم المدينة (اختياري)
        /// City name (optional)
        /// </summary>
        public string? CityName { get; set; }

        /// <summary>
        /// فئة الصورة (اختياري)
        /// Image category (optional)
        /// </summary>
        public ImageCategory? Category { get; set; }

        /// <summary>
        /// رقم الصفحة (اختياري)
        /// Page number (optional)
        /// </summary>
        public int? Page { get; set; }

        /// <summary>
        /// حجم الصفحة (اختياري)
        /// Items per page (optional)
        /// </summary>
        public int? Limit { get; set; }

        /// <summary>
        /// ترتيب النتائج حسب (uploadedAt, order, filename)
        /// Sort by field
        /// </summary>
        public string? SortBy { get; set; }

        /// <summary>
        /// اتجاه الترتيب (asc أو desc)
        /// Sort order (asc or desc)
        /// </summary>
        public string? SortOrder { get; set; }

        /// <summary>
        /// مصطلح البحث في الاسم أو الوسوم (اختياري)
        /// Search term in filename or tags (optional)
        /// </summary>
        public string? Search { get; set; }
    }
} 