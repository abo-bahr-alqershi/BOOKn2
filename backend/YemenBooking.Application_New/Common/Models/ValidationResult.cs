using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// نتيجة التحقق
    /// Validation result
    /// </summary>
    public enum ValidationResult
    {
        /// <summary>
        /// نجح التحقق بدون أخطاء
        /// Validation passed without errors
        /// </summary>
        Success,

        /// <summary>
        /// نجح التحقق مع تحذيرات
        /// Validation passed with warnings
        /// </summary>
        SuccessWithWarnings,

        /// <summary>
        /// فشل التحقق مع أخطاء قابلة للإصلاح
        /// Validation failed with fixable errors
        /// </summary>
        FailedWithFixableErrors,

        /// <summary>
        /// فشل التحقق مع أخطاء حرجة
        /// Validation failed with critical errors
        /// </summary>
        FailedWithCriticalErrors,

        /// <summary>
        /// لم يكتمل التحقق
        /// Validation incomplete
        /// </summary>
        Incomplete
    }
} 