using System;
using YemenBooking.Core.Enums;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.DynamicFields.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Units.DTOs {
    /// <summary>
    /// DTO لبيانات الوحدة
    /// DTO for unit data
    /// </summary>
    public class UnitDto
    {
        /// <summary>
        /// المعرف الفريد للوحدة
        /// Unit unique identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// معرف الكيان
        /// Property identifier
        /// </summary>
        public Guid PropertyId { get; set; }

        /// <summary>
        /// معرف نوع الوحدة
        /// Unit type identifier
        /// </summary>
        public Guid UnitTypeId { get; set; }

        /// <summary>
        /// اسم الوحدة
        /// Unit name
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// السعر الأساسي للوحدة
        /// Base price of the unit
        /// </summary>
        public MoneyDto BasePrice { get; set; }

        /// <summary>
        /// الميزات المخصصة للوحدة (JSON)
        /// Custom features of the unit
        /// </summary>
        public string CustomFeatures { get; set; }

        /// <summary>
        /// حالة توفر الوحدة
        /// Availability status
        /// </summary>
        public bool IsAvailable { get; set; }

        /// <summary>
        /// اسم الكيان
        /// Property name
        /// </summary>
        public string PropertyName { get; set; }

        /// <summary>
        /// اسم نوع الوحدة
        /// Unit type name
        /// </summary>
        public string UnitTypeName { get; set; }

        /// <summary>
        /// طريقة حساب السعر
        /// Pricing calculation method
        /// </summary>
        public PricingMethod PricingMethod { get; set; }

        /// <summary>
        /// قيم الحقول الديناميكية للوحدة
        /// Dynamic field values for the unit
        /// </summary>
        public List<UnitFieldValueDto> FieldValues { get; set; }

        /// <summary>
        /// قيم الحقول الديناميكية مجمعة ضمن المجموعات الخاصة بها
        /// Dynamic fields grouped within their field groups
        /// </summary>
        public List<FieldGroupWithValuesDto> DynamicFields { get; set; } = new List<FieldGroupWithValuesDto>();

        /// <summary>
        /// المسافة من الموقع الحالي بالكيلومترات
        /// Distance from current location in kilometers
        /// </summary>
        public double? DistanceKm { get; set; }

        /// <summary>
        /// صور الكيان
        /// Property images
        /// </summary>
        public IEnumerable<PropertyImageDto> Images { get; set; } = new List<PropertyImageDto>();

        /// <summary>
        /// هل تقبل الوحدة الإلغاء
        /// Allows cancellation
        /// </summary>
        public bool AllowsCancellation { get; set; }

        /// <summary>
        /// نافذة الإلغاء بالأيام
        /// Cancellation window in days
        /// </summary>
        public int? CancellationWindowDays { get; set; }

    }
} 