using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// إحصائيات قيمة الحقل
    /// Field value statistics
    /// </summary>
    public class FieldValueStatisticsDto
    {
        /// <summary>
        /// عدد القيم الفريدة
        /// Unique values count
        /// </summary>
        public int UniqueValuesCount { get; set; }

        /// <summary>
        /// عدد القيم الفارغة
        /// Empty values count
        /// </summary>
        public int EmptyValuesCount { get; set; }

        /// <summary>
        /// متوسط طول القيمة
        /// Average value length
        /// </summary>
        public double AverageValueLength { get; set; }

        /// <summary>
        /// أكثر القيم شيوعاً
        /// Most common values
        /// </summary>
        public Dictionary<string, int> MostCommonValues { get; set; } = new Dictionary<string, int>();
    }
} 