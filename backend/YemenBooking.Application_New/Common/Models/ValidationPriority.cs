namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// أولوية التحقق
    /// Validation priority
    /// </summary>
    public enum ValidationPriority
    {
        /// <summary>
        /// منخفضة - التحقق التدريجي في الخلفية
        /// Low - gradual background validation
        /// </summary>
        Low,

        /// <summary>
        /// عادية - التحقق المعتاد
        /// Normal - standard validation
        /// </summary>
        Normal,

        /// <summary>
        /// عالية - التحقق السريع والفوري
        /// High - fast and immediate validation
        /// </summary>
        High,

        /// <summary>
        /// حرجة - التحقق الفوري مع أولوية قصوى
        /// Critical - immediate validation with top priority
        /// </summary>
        Critical
    }
} 