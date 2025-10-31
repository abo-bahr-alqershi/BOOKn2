using System;
using YemenBooking.Application.Features.DynamicFields.DTOs;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// قيمة الحقل الديناميكي للوحدة
    /// </summary>
    public class UnitDynamicFieldValueDto
    {
        /// <summary>
        /// معرف الحقل
        /// </summary>
        public Guid FieldId { get; set; }

        /// <summary>
        /// قيمة الحقل
        /// </summary>
        public string FieldValue { get; set; } = string.Empty;

        /// <summary>
        /// هل الحقل عام
        /// </summary>
        public bool IsPublic { get; set; } = true;
    }
} 