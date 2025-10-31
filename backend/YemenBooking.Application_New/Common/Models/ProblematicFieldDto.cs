using System;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// حقل إشكالي
    /// Problematic field
    /// </summary>
    public class ProblematicFieldDto
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
        /// عدد الأخطاء
        /// Error count
        /// </summary>
        public int ErrorCount { get; set; }

        /// <summary>
        /// نسبة الأخطاء
        /// Error percentage
        /// </summary>
        public decimal ErrorPercentage { get; set; }

        /// <summary>
        /// أكثر الأخطاء شيوعاً
        /// Most common error
        /// </summary>
        public string MostCommonError { get; set; }
    }
} 