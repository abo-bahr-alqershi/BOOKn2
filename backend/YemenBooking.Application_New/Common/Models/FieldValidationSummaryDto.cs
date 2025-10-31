using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// ملخص الحقول المفحوصة
    /// Validated fields summary
    /// </summary>
    public class FieldValidationSummaryDto
    {
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
        /// نوع البيانات
        /// Data type
        /// </summary>
        public string DataType { get; set; }

        /// <summary>
        /// عدد القيم المفحوصة
        /// Values validated count
        /// </summary>
        public int ValuesValidatedCount { get; set; }

        /// <summary>
        /// عدد القيم الصحيحة
        /// Valid values count
        /// </summary>
        public int ValidValuesCount { get; set; }

        /// <summary>
        /// عدد القيم غير الصحيحة
        /// Invalid values count
        /// </summary>
        public int InvalidValuesCount { get; set; }

        /// <summary>
        /// نسبة النجاح
        /// Success percentage
        /// </summary>
        public decimal SuccessPercentage { get; set; }

        /// <summary>
        /// الأخطاء الشائعة
        /// Common errors
        /// </summary>
        public List<string> CommonErrors { get; set; } = new List<string>();

        /// <summary>
        /// إحصائيات قيم الحقل
        /// Field value statistics
        /// </summary>
        public FieldValueStatisticsDto? ValueStatistics { get; set; }
    }
} 