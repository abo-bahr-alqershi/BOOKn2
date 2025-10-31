using System;

namespace YemenBooking.Application.Common.Interfaces
{
    /// <summary>
    /// واجهة خدمة مساعدة لمعالجة عناوين URL
    /// URL helper service interface
    /// </summary>
    public interface IUrlHelper
    {
        /// <summary>
        /// تحويل مسار نسبي إلى مسار مطلق
        /// Convert relative path to absolute URL
        /// </summary>
        /// <param name="relativePath">المسار النسبي / Relative path (e.g., "/uploads/images/profile/abc.jpg")</param>
        /// <returns>عنوان URL المطلق / Absolute URL (e.g., "http://localhost:5000/uploads/images/profile/abc.jpg")</returns>
        string ToAbsoluteUrl(string? relativePath);

        /// <summary>
        /// تحويل مسار مطلق إلى مسار نسبي
        /// Convert absolute URL to relative path
        /// </summary>
        /// <param name="absoluteUrl">عنوان URL المطلق / Absolute URL</param>
        /// <returns>المسار النسبي / Relative path</returns>
        string ToRelativePath(string? absoluteUrl);

        /// <summary>
        /// الحصول على عنوان URL الأساسي للخادم
        /// Get the base URL of the server
        /// </summary>
        /// <returns>عنوان URL الأساسي / Base URL (e.g., "http://localhost:5000")</returns>
        string GetBaseUrl();
    }
}
