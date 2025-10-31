using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace YemenBooking.Application.Infrastructure.Services
{
    /// <summary>
    /// واجهة خدمة رفع الملفات
    /// File upload service interface
    /// </summary>
    public interface IFileUploadService
    {
        /// <summary>
        /// رفع ملف واحد
        /// Upload single file
        /// </summary>
        /// <param name="fileStream">تدفق الملف</param>
        /// <param name="fileName">اسم الملف</param>
        /// <param name="contentType">نوع المحتوى</param>
        /// <param name="folder">المجلد الهدف</param>
        /// <returns>رابط الملف المرفوع</returns>
        Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType, string folder = "uploads");

        /// <summary>
        /// رفع عدة ملفات
        /// Upload multiple files
        /// </summary>
        /// <param name="files">قائمة الملفات</param>
        /// <param name="folder">المجلد الهدف</param>
        /// <returns>قائمة روابط الملفات المرفوعة</returns>
        Task<List<string>> UploadFilesAsync(List<(Stream stream, string fileName, string contentType)> files, string folder = "uploads");

        /// <summary>
        /// رفع صورة مع تحسين الجودة
        /// Upload image with optimization
        /// </summary>
        /// <param name="imageStream">تدفق الصورة</param>
        /// <param name="fileName">اسم الملف</param>
        /// <param name="maxWidth">أقصى عرض</param>
        /// <param name="maxHeight">أقصى ارتفاع</param>
        /// <param name="quality">جودة الضغط</param>
        /// <param name="folder">المجلد الهدف</param>
        /// <returns>رابط الصورة المرفوعة</returns>
        Task<string> UploadImageAsync(Stream imageStream, string fileName, int maxWidth = 1920, int maxHeight = 1080, int quality = 85, string folder = "images");

        /// <summary>
        /// رفع صورة الملف الشخصي للمستخدم وإرجاع الرابط
        /// Upload user profile image and return URL
        /// </summary>
        Task<string> UploadProfileImageAsync(Stream imageStream, string fileName, CancellationToken cancellationToken = default);

        /// <summary>
        /// حذف ملف
        /// Delete file
        /// </summary>
        /// <param name="fileUrl">رابط الملف</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> DeleteFileAsync(string fileUrl);

        /// <summary>
        /// حذف عدة ملفات
        /// Delete multiple files
        /// </summary>
        /// <param name="fileUrls">قائمة روابط الملفات</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> DeleteFilesAsync(List<string> fileUrls);

        /// <summary>
        /// التحقق من صحة نوع الملف
        /// Validate file type
        /// </summary>
        /// <param name="fileName">اسم الملف</param>
        /// <param name="allowedExtensions">الامتدادات المسموحة</param>
        /// <returns>نتيجة التحقق</returns>
        bool IsValidFileType(string fileName, string[] allowedExtensions);

        /// <summary>
        /// التحقق من حجم الملف
        /// Validate file size
        /// </summary>
        /// <param name="fileSize">حجم الملف بالبايت</param>
        /// <param name="maxSizeInMB">أقصى حجم مسموح بالميجابايت</param>
        /// <returns>نتيجة التحقق</returns>
        bool IsValidFileSize(long fileSize, int maxSizeInMB);

        /// <summary>
        /// إنشاء اسم ملف فريد
        /// Generate unique file name
        /// </summary>
        /// <param name="originalFileName">اسم الملف الأصلي</param>
        /// <returns>اسم الملف الفريد</returns>
        string GenerateUniqueFileName(string originalFileName);
    }
}
