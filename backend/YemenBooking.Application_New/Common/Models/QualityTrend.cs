namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// اتجاه جودة البيانات
    /// Data quality trend
    /// </summary>
    public enum QualityTrend
    {
        /// <summary>
        /// تحسن
        /// Improving
        /// </summary>
        Improving,

        /// <summary>
        /// مستقر
        /// Stable
        /// </summary>
        Stable,

        /// <summary>
        /// تراجع
        /// Declining
        /// </summary>
        Declining,

        /// <summary>
        /// غير واضح
        /// Unclear
        /// </summary>
        Unclear
    }
} 