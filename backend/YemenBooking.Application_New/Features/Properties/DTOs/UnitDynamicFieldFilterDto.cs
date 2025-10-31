using System;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// فلتر باستخدام قيم الحقول الديناميكية للكيان
    /// Filter by dynamic field values for property search
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