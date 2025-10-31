using System;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// بيانات نقطية زمنية للرسوم البيانية
    /// Time series data point for charts
    /// </summary>
    public class TimeSeriesDataDto
    {
        /// <summary>
        /// التاريخ
        /// Date
        /// </summary>
        public DateTime Date { get; set; }

        /// <summary>
        /// القيمة
        /// Value
        /// </summary>
        public decimal Value { get; set; }
    }
} 