using System;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// DTO لإصدار التطبيق
    /// App version DTO
    /// </summary>
    public class AppVersionDto
    {
        /// <summary>
        /// رقم الإصدار
        /// Version number
        /// </summary>
        public string Version { get; set; } = string.Empty;

        /// <summary>
        /// رقم البناء
        /// Build number
        /// </summary>
        public string BuildNumber { get; set; } = string.Empty;

        /// <summary>
        /// هل التحديث مطلوب
        /// Whether update is required
        /// </summary>
        public bool IsUpdateRequired { get; set; }

        /// <summary>
        /// هل التحديث إجباري
        /// Whether update is forced
        /// </summary>
        public bool IsForceUpdate { get; set; }

        /// <summary>
        /// رابط التحديث للأندرويد
        /// Android update URL
        /// </summary>
        public string? AndroidUpdateUrl { get; set; }

        /// <summary>
        /// رابط التحديث للآيفون
        /// iOS update URL
        /// </summary>
        public string? IosUpdateUrl { get; set; }

        /// <summary>
        /// ملاحظات الإصدار
        /// Release notes
        /// </summary>
        public string? ReleaseNotes { get; set; }

        /// <summary>
        /// ملاحظات الإصدار بالعربية
        /// Release notes in Arabic
        /// </summary>
        public string? ReleaseNotesAr { get; set; }

        /// <summary>
        /// الحد الأدنى للإصدار
        /// Minimum version
        /// </summary>
        public string? MinVersion { get; set; }

        /// <summary>
        /// تاريخ الإصدار
        /// Release date
        /// </summary>
        public DateTime ReleaseDate { get; set; }

        /// <summary>
        /// الحد الأدنى للإصدار المدعوم
        /// Minimum supported version
        /// </summary>
        public string MinSupportedVersion { get; set; } = string.Empty;

        /// <summary>
        /// رسالة التحديث
        /// Update message
        /// </summary>
        public string? UpdateMessage { get; set; }

        /// <summary>
        /// حجم التحديث (بالميجابايت)
        /// Update size in MB
        /// </summary>
        public decimal? UpdateSizeMB { get; set; }

        /// <summary>
        /// المميزات الجديدة
        /// New features
        /// </summary>
        public string[]? NewFeatures { get; set; }

        /// <summary>
        /// الإصلاحات
        /// Bug fixes
        /// </summary>
        public string[]? BugFixes { get; set; }

        /// <summary>
        /// تحسينات الأداء
        /// Performance improvements
        /// </summary>
        public string[]? PerformanceImprovements { get; set; }
    }
}
