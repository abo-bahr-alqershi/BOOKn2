using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Units.Queries.SearchUnits
{
    /// <summary>
    /// استعلام للبحث عن الوحدات
    /// Query to search for units
    /// </summary>
    public class SearchUnitsQuery : IRequest<PaginatedResult<UnitDto>>
    {
        /// <summary>
        /// الموقع (اختياري)
        /// Location (optional)
        /// </summary>
        public string? Location { get; set; }

        /// <summary>
        /// الحد الأدنى للسعر (اختياري)
        /// Minimum price (optional)
        /// </summary>
        public decimal? MinPrice { get; set; }

        /// <summary>
        /// الحد الأقصى للسعر (اختياري)
        /// Maximum price (optional)
        /// </summary>
        public decimal? MaxPrice { get; set; }

        /// <summary>
        /// معرف الكيان (اختياري)
        /// Property ID (optional)
        /// </summary>
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// معرف نوع الوحدة (اختياري)
        /// UnitType ID (optional)
        /// </summary>
        public Guid? UnitTypeId { get; set; }

        /// <summary>
        /// تاريخ الدخول (اختياري)
        /// Check-in date (optional)
        /// </summary>
        public DateTime? CheckInDate { get; set; }

        /// <summary>
        /// تاريخ الخروج (اختياري)
        /// Check-out date (optional)
        /// </summary>
        public DateTime? CheckOutDate { get; set; }

        /// <summary>
        /// عدد الضيوف (اختياري)
        /// Number of guests (optional)
        /// </summary>
        public int? NumberOfGuests { get; set; }

        /// <summary>
        /// حالة توفر الوحدة (اختياري)
        /// Availability status filter (optional)
        /// </summary>
        public bool? IsAvailable { get; set; }

        /// <summary>
        /// فلترة حسب وجود حجوزات نشطة (اختياري)
        /// Filter by having active bookings (optional)
        /// </summary>
        public bool? HasActiveBookings { get; set; }

        /// <summary>
        /// رقم الصفحة
        /// Page number
        /// </summary>
        public int PageNumber { get; set; } = 1;

        /// <summary>
        /// حجم الصفحة
        /// Page size
        /// </summary>
        public int PageSize { get; set; } = 10;

        /// <summary>
        /// فلترة باستخدام قيم الحقول الديناميكية: تشمل الوحدات التي تملك القيمة المحددة لكل حقل
        /// Filter by dynamic field values: include units that have the specified value for each field
        /// </summary>
        public IEnumerable<YemenBooking.Application.Features.Units.DTOs.UnitDynamicFieldFilterDto>? DynamicFieldFilters { get; set; }

        /// <summary>
        /// خط عرض العميل (اختياري)
        /// Customer latitude (optional)
        /// </summary>
        public double? Latitude { get; set; }

        /// <summary>
        /// خط طول العميل (اختياري)
        /// Customer longitude (optional)
        /// </summary>
        public double? Longitude { get; set; }

        /// <summary>
        /// نصف قطر البحث بالكيلومتر (اختياري)
        /// Search radius in kilometers (optional)
        /// </summary>
        public double? RadiusKm { get; set; }

        /// <summary>
        /// خيارات الترتيب: popularity, price_asc, price_desc, name_asc, name_desc
        /// Sort options: popularity, price_asc, price_desc, name_asc, name_desc
        /// </summary>
        public string? SortBy { get; set; }

        /// <summary>
        /// بحث بالاسم أو الرقم (اختياري)
        /// Name search: unit name or number (optional)
        /// </summary>
        public string? NameContains { get; set; }

        /// <summary>
        /// فلترة بطريقة التسعير (اختياري)
        /// Filter by pricing method (optional)
        /// </summary>
        public string? PricingMethod { get; set; }
    }
} 