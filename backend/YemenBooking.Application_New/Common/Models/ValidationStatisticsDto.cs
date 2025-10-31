using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// إحصائيات التحقق
    /// Validation statistics
    /// </summary>
    public class ValidationStatisticsDto
    {
        /// <summary>
        /// أخطاء حسب الحقل
        /// Errors by field
        /// </summary>
        public Dictionary<string, int> ErrorsByField { get; set; } = new Dictionary<string, int>();

        /// <summary>
        /// أخطاء حسب نوع البيانات
        /// Errors by data type
        /// </summary>
        public Dictionary<string, int> ErrorsByDataType { get; set; } = new Dictionary<string, int>();

        /// <summary>
        /// أكثر الحقول مشكلة
        /// Most problematic fields
        /// </summary>
        public List<ProblematicFieldDto> MostProblematicFields { get; set; } = new List<ProblematicFieldDto>();

        /// <summary>
        /// درجة جودة البيانات
        /// Data quality score
        /// </summary>
        public decimal DataQualityScore { get; set; }

        /// <summary>
        /// اتجاه جودة البيانات
        /// Data quality trend
        /// </summary>
        public QualityTrend QualityTrend { get; set; }
    }
} 