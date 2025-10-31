namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// نطاق التحقق
    /// Validation scope
    /// </summary>
    public enum ValidationScope
    {
        /// <summary>
        /// جميع القيم
        /// All values
        /// </summary>
        All,

        /// <summary>
        /// الحقول المطلوبة فقط
        /// Required fields only
        /// </summary>
        RequiredOnly,

        /// <summary>
        /// الحقول العامة فقط
        /// Public fields only
        /// </summary>
        PublicOnly,

        /// <summary>
        /// الحقول التي تحتوي على قواعد تحقق مخصصة
        /// Fields with custom validation rules
        /// </summary>
        CustomRulesOnly,

        /// <summary>
        /// الحقول المحدثة مؤخراً
        /// Recently updated fields
        /// </summary>
        RecentlyUpdated
    }
} 