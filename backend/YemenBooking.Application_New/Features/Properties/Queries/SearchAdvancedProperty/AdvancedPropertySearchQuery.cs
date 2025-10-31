using MediatR;
using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.SearchAdvancedProperty
{
    /// <summary>
    /// استعلام البحث المتقدم عن الكيانات
    /// يسمح بالفلترة حسب نوع الكيان، النطاق الزمني، السعر، الحقول الديناميكية، نوع الوحدة، المرافق، الخدمات، والترتيب.
    /// </summary>
    public class AdvancedPropertySearchQuery : IRequest<PaginatedResult<Properties.DTOs.AdvancedPropertyDto>>
    {
        /// <summary>
        /// معرف نوع الكيان (اختياري)
        /// PropertyTypeId (optional)
        /// </summary>
        public Guid? PropertyTypeId { get; set; }

        /// <summary>
        /// تاريخ ووقت بداية البحث (لاستخدامه في فلترة فترة الاتاحة اللتي يرغب العميل بحجزها)
        /// FromDate (DateTime) for pricing/time filters
        /// </summary>
        public DateTime? FromDate { get; set; }

        /// <summary>
        /// تاريخ ووقت نهاية فترة الاتاحة اللتي يرغب العميل بأنهاء حجزها
        /// ToDate (DateTime) for pricing/time filters
        /// </summary>
        public DateTime? ToDate { get; set; }

        /// <summary>
        /// الحد الأدنى للسعر
        /// Minimum price
        /// </summary>
        public decimal? MinPrice { get; set; }

        /// <summary>
        /// الحد الأقصى للسعر
        /// Maximum price
        /// </summary>
        public decimal? MaxPrice { get; set; }

        /// <summary>
        /// رمز العملة (ISO)
        /// Currency code
        /// </summary>
        public string Currency { get; set; }

        /// <summary>
        /// قيم الحقول الديناميكية الأساسية (FieldId => List of values)
        /// Only fields marked as IsPrimaryFilter
        /// </summary>
        public Dictionary<Guid, IEnumerable<string>> PrimaryFieldFilters { get; set; }

        /// <summary>
        /// قيم الحقول الديناميكية العادية (FieldId => List of values)
        /// </summary>
        public Dictionary<Guid, IEnumerable<string>> FieldFilters { get; set; }

        /// <summary>
        /// قائمة معرفات نوع الوحدة المرشح لها
        /// UnitTypeIds filter
        /// </summary>
        public IEnumerable<Guid> UnitTypeIds { get; set; }

        /// <summary>
        /// قائمة معرفات المرافق المرشح لها
        /// AmenityIds filter
        /// </summary>
        public IEnumerable<Guid> AmenityIds { get; set; }

        /// <summary>
        /// قائمة معرفات الخدمات المرشح لها
        /// ServiceIds filter
        /// </summary>
        public IEnumerable<Guid> ServiceIds { get; set; }

        /// <summary>
        /// حقل الترتيب (مثل "price", "rating", "name")
        /// SortBy field
        /// </summary>
        public string SortBy { get; set; }

        /// <summary>
        /// اتجاه الترتيب (صعوداً أو هبوطاً)
        /// IsAscending flag
        /// </summary>
        public bool IsAscending { get; set; } = false;

        /// <summary>
        /// رقم الصفحة الحالية (1 = الأولى)
        /// Current page number
        /// </summary>
        public int PageNumber { get; set; } = 1;

        /// <summary>
        /// حجم الصفحة (عدد العناصر في الصفحة)
        /// Page size
        /// </summary>
        public int PageSize { get; set; } = 10;
    }
} 
