namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// إعدادات التحقق
    /// Validation settings
    /// </summary>
    public class ValidationSettingsDto
    {
        /// <summary>
        /// تجاهل القيم الفارغة
        /// Skip empty values
        /// </summary>
        public bool SkipEmptyValues { get; set; } = true;

        /// <summary>
        /// تجاهل الحقول المحذوفة
        /// Skip deleted fields
        /// </summary>
        public bool SkipDeletedFields { get; set; } = true;

        /// <summary>
        /// التحقق من التكرار
        /// Check for duplicates
        /// </summary>
        public bool CheckDuplicates { get; set; } = true;

        /// <summary>
        /// التحقق من التماسك بين الحقول المرتبطة
        /// Check consistency between related fields
        /// </summary>
        public bool CheckConsistency { get; set; } = true;

        /// <summary>
        /// التحقق من التنسيق
        /// Check formatting
        /// </summary>
        public bool CheckFormatting { get; set; } = true;

        /// <summary>
        /// التحقق من النطاقات المسموحة
        /// Check allowed ranges
        /// </summary>
        public bool CheckRanges { get; set; } = true;

        /// <summary>
        /// تحديد مهلة زمنية للتحقق (بالثواني)
        /// Validation timeout in seconds
        /// </summary>
        public int TimeoutSeconds { get; set; } = 300;

        /// <summary>
        /// حجم الدفعة للمعالجة
        /// Batch size for processing
        /// </summary>
        public int BatchSize { get; set; } = 100;
    }
} 