namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// بيانات تصنيفية للرسوم البيانية
    /// Categorical data point for charts
    /// </summary>
    public class CategoricalDataDto
    {
        /// <summary>
        /// الفئة
        /// Category
        /// </summary>
        public string Category { get; set; }

        /// <summary>
        /// القيمة
        /// Value
        /// </summary>
        public decimal Value { get; set; }
    }
} 