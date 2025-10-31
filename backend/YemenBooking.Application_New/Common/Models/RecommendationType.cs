namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// نوع التوصية
    /// Recommendation type
    /// </summary>
    public enum RecommendationType
    {
        /// <summary>
        /// تحسين جودة البيانات
        /// Data quality improvement
        /// </summary>
        DataQualityImprovement,

        /// <summary>
        /// تحسين الأداء
        /// Performance improvement
        /// </summary>
        PerformanceImprovement,

        /// <summary>
        /// تحسين قواعد التحقق
        /// Validation rules improvement
        /// </summary>
        ValidationRulesImprovement,

        /// <summary>
        /// تحسين بنية الحقول
        /// Field structure improvement
        /// </summary>
        FieldStructureImprovement
    }
} 