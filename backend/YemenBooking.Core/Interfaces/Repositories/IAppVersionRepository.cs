using System;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories
{
    /// <summary>
    /// واجهة مستودع إصدارات التطبيق
    /// App version repository interface
    /// </summary>
    public interface IAppVersionRepository : IRepository<AppVersion>
    {
        /// <summary>
        /// الحصول على أحدث إصدار للتطبيق
        /// Get latest app version
        /// </summary>
        /// <param name="platform">المنصة (Android/iOS)</param>
        /// <returns>أحدث إصدار</returns>
        Task<AppVersion?> GetLatestVersionAsync(string platform);

        /// <summary>
        /// الحصول على إصدار محدد
        /// Get specific version
        /// </summary>
        /// <param name="version">رقم الإصدار</param>
        /// <param name="platform">المنصة</param>
        /// <returns>الإصدار المطلوب</returns>
        Task<AppVersion?> GetVersionAsync(string version, string platform);

        /// <summary>
        /// التحقق من الحاجة للتحديث
        /// Check if update is needed
        /// </summary>
        /// <param name="currentVersion">الإصدار الحالي</param>
        /// <param name="platform">المنصة</param>
        /// <returns>معلومات التحديث</returns>
        Task<UpdateInfo> CheckUpdateAsync(string currentVersion, string platform);

        /// <summary>
        /// الحصول على الحد الأدنى للإصدار المدعوم
        /// Get minimum supported version
        /// </summary>
        /// <param name="platform">المنصة</param>
        /// <returns>الحد الأدنى للإصدار</returns>
        Task<string?> GetMinSupportedVersionAsync(string platform);

        /// <summary>
        /// تحديث إصدار التطبيق
        /// Update app version
        /// </summary>
        /// <param name="appVersion">بيانات الإصدار الجديد</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> UpdateVersionAsync(AppVersion appVersion);

        /// <summary>
        /// تعطيل إصدار قديم
        /// Disable old version
        /// </summary>
        /// <param name="version">رقم الإصدار</param>
        /// <param name="platform">المنصة</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> DisableVersionAsync(string version, string platform);
    }

    /// <summary>
    /// كيان إصدار التطبيق
    /// App version entity
    /// </summary>
    public class AppVersion : BaseEntity<Guid>
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
        /// المنصة (Android/iOS)
        /// Platform
        /// </summary>
        public string Platform { get; set; } = string.Empty;

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
        /// رابط التحديث
        /// Update URL
        /// </summary>
        public string? UpdateUrl { get; set; }

        /// <summary>
        /// ملاحظات الإصدار
        /// Release notes
        /// </summary>
        public string? ReleaseNotes { get; set; }

        /// <summary>
        /// تاريخ الإصدار
        /// Release date
        /// </summary>
        public DateTime ReleaseDate { get; set; }

        /// <summary>
        /// هل الإصدار نشط
        /// Whether version is active
        /// </summary>
        public bool IsActive { get; set; } = true;

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
    }

    /// <summary>
    /// معلومات التحديث
    /// Update information
    /// </summary>
    public class UpdateInfo
    {
        /// <summary>
        /// هل التحديث متاح
        /// Whether update is available
        /// </summary>
        public bool IsUpdateAvailable { get; set; }

        /// <summary>
        /// هل التحديث إجباري
        /// Whether update is forced
        /// </summary>
        public bool IsForceUpdate { get; set; }

        /// <summary>
        /// أحدث إصدار
        /// Latest version
        /// </summary>
        public string? LatestVersion { get; set; }

        /// <summary>
        /// رابط التحديث
        /// Update URL
        /// </summary>
        public string? UpdateUrl { get; set; }

        /// <summary>
        /// رسالة التحديث
        /// Update message
        /// </summary>
        public string? UpdateMessage { get; set; }
    }
}
