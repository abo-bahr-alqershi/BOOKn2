using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// تفاصيل خطأ التحقق
    /// Validation error details
    /// </summary>
    public class ValidationErrorDto
    {
        /// <summary>
        /// معرف الخطأ
        /// Error ID
        /// </summary>
        public Guid ErrorId { get; set; }

        /// <summary>
        /// معرف قيمة الحقل
        /// Field value ID
        /// </summary>
        public Guid FieldValueId { get; set; }

        /// <summary>
        /// معرف الكيان
        /// Property ID
        /// </summary>
        public Guid PropertyId { get; set; }

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
        /// قيمة الخطأ
        /// Error value
        /// </summary>
        public string? ErrorValue { get; set; }

        /// <summary>
        /// نوع الخطأ
        /// Error type
        /// </summary>
        public FieldValidationErrorType ErrorType { get; set; }

        /// <summary>
        /// رسالة الخطأ
        /// Error message
        /// </summary>
        public string ErrorMessage { get; set; }

        /// <summary>
        /// شدة الخطأ
        /// Severity
        /// </summary>
        public ErrorSeverity Severity { get; set; }

        /// <summary>
        /// قابل للإصلاح تلقائياً
        /// Is auto-fixable
        /// </summary>
        public bool IsAutoFixable { get; set; }

        /// <summary>
        /// المقترح للإصلاح
        /// Suggested fix
        /// </summary>
        public string? SuggestedFix { get; set; }

        /// <summary>
        /// القيمة المقترحة
        /// Suggested value
        /// </summary>
        public string? SuggestedValue { get; set; }

        /// <summary>
        /// تم إصلاحه تلقائياً
        /// Was auto-fixed
        /// </summary>
        public bool WasAutoFixed { get; set; }

        /// <summary>
        /// تفاصيل إضافية
        /// Additional details
        /// </summary>
        public Dictionary<string, object>? AdditionalDetails { get; set; }
    }
} 