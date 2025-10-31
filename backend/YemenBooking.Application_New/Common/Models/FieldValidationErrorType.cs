namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// نوع خطأ التحقق من الحقل
    /// Field validation error type
    /// </summary>
    public enum FieldValidationErrorType
    {
        /// <summary>
        /// قيمة مطلوبة مفقودة
        /// Required value missing
        /// </summary>
        RequiredValueMissing,

        /// <summary>
        /// تنسيق غير صحيح
        /// Invalid format
        /// </summary>
        InvalidFormat,

        /// <summary>
        /// خارج النطاق المسموح
        /// Out of range
        /// </summary>
        OutOfRange,

        /// <summary>
        /// نوع بيانات غير صحيح
        /// Invalid data type
        /// </summary>
        InvalidDataType,

        /// <summary>
        /// قيمة مكررة
        /// Duplicate value
        /// </summary>
        DuplicateValue,

        /// <summary>
        /// قيمة غير متسقة
        /// Inconsistent value
        /// </summary>
        InconsistentValue,

        /// <summary>
        /// قاعدة تحقق مخصصة فشلت
        /// Custom validation rule failed
        /// </summary>
        CustomRuleFailed
    }
} 