using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.DynamicFields.DTOs;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;

namespace YemenBooking.Application.Features.Units.DTOs {
    /// <summary>
    /// تفاصيل نوع الوحدة
    /// Unit type DTO
    /// </summary>
    public class UnitTypeDto
    {
        /// <summary>
        /// معرف نوع الوحدة
        /// Unit type identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// معرف نوع الكيان
        /// Property type identifier
        /// </summary>
        public Guid PropertyTypeId { get; set; }

        /// <summary>
        /// اسم نوع الوحدة
        /// Unit type name
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// وصف نوع الوحدة
        /// Unit type description
        /// </summary>
        public string Description { get; set; }

        /// <summary>
        /// قواعد التسعير الافتراضية (JSON)
        /// Default pricing rules (JSON)
        /// </summary>
        public string DefaultPricingRules { get; set; }

        /// <summary>
        /// هذا النوع يحتوي على بالغين
        /// This type has adults
        /// </summary>
        public bool IsHasAdults { get; set; } = false;

        /// <summary>
        /// هذا النوع يحتوي على أطفال
        /// This type has children
        /// </summary>
        public bool IsHasChildren { get; set; } = false;

        /// <summary>
        /// هذا النوع يحتوي على أيام متعددة
        /// This type has multiple days
        /// </summary>
        public bool IsMultiDays { get; set; } = false;

        /// <summary>
        /// هذا النوع يحتاج لتحديد الساعة
        /// This type requires determining the hour
        /// </summary>
        public bool IsRequiredToDetermineTheHour { get; set; } = false;

        /// <summary>
        /// المجموعات التي تحوي الحقول الديناميكية لنوع الوحدة
        /// Groups containing dynamic fields for the unit type
        /// </summary>
        public List<FieldGroupDto> FieldGroups { get; set; } = new List<FieldGroupDto>();

        /// <summary>
        /// قائمة الحقول الديناميكية المباشرة التابعة لنوع الوحدة
        /// Direct dynamic fields for this unit type
        /// </summary>
        public List<UnitTypeFieldDto> Fields { get; set; } = new List<UnitTypeFieldDto>();

        /// <summary>
        /// فلاتر البحث الديناميكية المطبقة على الحقول
        /// Dynamic search filters for the unit type fields
        /// </summary>
        public List<SearchFilterDto> Filters { get; set; } = new List<SearchFilterDto>();

        /// <summary>
        /// الحد الأقصى للسعة
        /// Maximum capacity
        /// </summary>
        public int MaxCapacity { get; set; }

        /// <summary>
        /// ايقونة لنوع الوحدة
        /// Icon for the unit type
        /// </summary>
        public string Icon { get; set; } = string.Empty;

        /// <summary>
        /// نسبة عمولة النظام (0-100)
        /// System commission rate percentage
        /// </summary>
        public decimal? SystemCommissionRate { get; set; }

    }
} 