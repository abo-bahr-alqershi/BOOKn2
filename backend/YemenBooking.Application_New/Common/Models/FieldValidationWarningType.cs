namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// نوع تحذير التحقق من الحقل
    /// Field validation warning type
    /// </summary>
    public enum FieldValidationWarningType
    {
        /// <summary>
        /// قيمة مشكوك فيها
        /// Suspicious value
        /// </summary>
        SuspiciousValue,

        /// <summary>
        /// تنسيق غير مألوف
        /// Unusual format
        /// </summary>
        UnusualFormat,

        /// <summary>
        /// قيمة قديمة
        /// Outdated value
        /// </summary>
        OutdatedValue,

        /// <summary>
        /// قيمة غير محسنة
        /// Unoptimized value
        /// </summary>
        UnoptimizedValue
    }
} 