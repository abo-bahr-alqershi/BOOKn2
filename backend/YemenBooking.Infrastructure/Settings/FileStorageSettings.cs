namespace YemenBooking.Infrastructure.Settings
{
    /// <summary>
    /// إعدادات تخزين الملفات
    /// File storage settings
    /// </summary>
    public class FileStorageSettings
    {
        /// <summary>
        /// المسار الجذري لتخزين الملفات
        /// Root path for storing files
        /// </summary>
        public string RootPath { get; set; } = "Uploads";

        /// <summary>
        /// عنوان URL الأساسي للوصول إلى الملفات
        /// Base URL to access files
        /// </summary>
        public string BaseUrl { get; set; } = "/uploads";
    }
} 