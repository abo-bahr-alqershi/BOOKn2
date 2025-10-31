namespace YemenBooking.Application.Infrastructure.Services;

/// <summary>
/// واجهة خدمة استخراج بيانات الوسائط (مثل مدة الصوت/الفيديو)
/// Media metadata extraction service
/// </summary>
public interface IMediaMetadataService
{
    /// <summary>
    /// يحاول استخراج مدة ملف الوسائط بالثواني إذا كان الملف صوتًا أو فيديو
    /// Try to extract media duration in seconds if the file is audio/video
    /// </summary>
    /// <param name="filePath">المسار الكامل للملف على نظام الملفات</param>
    /// <param name="contentType">نوع المحتوى (MIME type)</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>عدد الثواني أو null إذا لم يمكن تحديدها</returns>
    Task<int?> TryGetDurationSecondsAsync(string filePath, string? contentType, CancellationToken cancellationToken = default);
}
