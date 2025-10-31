using System;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Units.DTOs {
    /// <summary>
    /// فلتر باستخدام قيم الحقول الديناميكية للوحدة
    /// Filter by dynamic field values for unit search
    /// </summary>
    public class UnitDynamicFieldFilterDto
    {
        /// <summary>
        /// معرف الحقل الديناميكي
        /// Dynamic field identifier
        /// </summary>
        public Guid FieldId { get; set; }

        /// <summary>
        /// قيمة الحقل المطلوبة للتصفية
        /// Field value to filter by
        /// </summary>
        public string FieldValue { get; set; } = string.Empty;
    }
} 