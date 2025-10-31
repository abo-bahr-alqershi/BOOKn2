using System;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// تحذير التحقق
    /// Validation warning
    /// </summary>
    public class ValidationWarningDto
    {
        /// <summary>
        /// معرف فريد للتحذير
        /// Unique warning ID
        /// </summary>
        public Guid WarningId { get; set; }

        /// <summary>
        /// معرف قيمة الحقل
        /// Field value ID
        /// </summary>
        public Guid FieldValueId { get; set; }

        /// <summary>
        /// معرف الحقل
        /// Field ID
        /// </summary>
        public Guid FieldId { get; set; }

        /// <summary>
        /// اسم الحقل
        /// Field name
        /// </summary>
        public string FieldName { get; set; }

        /// <summary>
        /// رسالة التحذير
        /// Warning message
        /// </summary>
        public string WarningMessage { get; set; }

        /// <summary>
        /// نوع التحذير
        /// Warning type
        /// </summary>
        public FieldValidationWarningType WarningType { get; set; }

        /// <summary>
        /// التوصية
        /// Recommendation
        /// </summary>
        public string? Recommendation { get; set; }
    }
} 