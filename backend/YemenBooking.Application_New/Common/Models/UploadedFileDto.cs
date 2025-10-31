namespace YemenBooking.Application.Common.Models;

/// <summary>
/// DTO الملف المرفوع
/// Uploaded file DTO
/// </summary>
public class UploadedFileDto
{
    /// <summary>
    /// اسم الملف
    /// File name
    /// </summary>
    public string FileName { get; set; } = null!;
    
    /// <summary>
    /// اسم الملف الأصلي
    /// Original file name
    /// </summary>
    public string OriginalFileName { get; set; } = null!;
    
    /// <summary>
    /// نوع المحتوى
    /// Content type
    /// </summary>
    public string ContentType { get; set; } = null!;
    
    /// <summary>
    /// حجم الملف بالبايت
    /// File size in bytes
    /// </summary>
    public long Size { get; set; }
    
    /// <summary>
    /// رابط الملف
    /// File URL
    /// </summary>
    public string Url { get; set; } = null!;
    
    /// <summary>
    /// مسار الملف النسبي
    /// Relative file path
    /// </summary>
    public string RelativePath { get; set; } = null!;
    
    /// <summary>
    /// تاريخ الرفع
    /// Upload date
    /// </summary>
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    
    /// <summary>
    /// معرف المستخدم الذي رفع الملف
    /// Uploaded by user ID
    /// </summary>
    public Guid? UploadedBy { get; set; }
    
    /// <summary>
    /// هاش الملف
    /// File hash
    /// </summary>
    public string? FileHash { get; set; }
    
    /// <summary>
    /// عرض الصورة (للصور)
    /// Image width (for images)
    /// </summary>
    public int? Width { get; set; }
    
    /// <summary>
    /// ارتفاع الصورة (للصور)
    /// Image height (for images)
    /// </summary>
    public int? Height { get; set; }
    
    /// <summary>
    /// مدة الفيديو (للفيديوهات)
    /// Video duration (for videos)
    /// </summary>
    public TimeSpan? Duration { get; set; }
    
    /// <summary>
    /// الوصف
    /// Description
    /// </summary>
    public string? Description { get; set; }
    
    /// <summary>
    /// الكلمات المفتاحية
    /// Tags
    /// </summary>
    public string? Tags { get; set; }
    
    /// <summary>
    /// هل الملف صورة
    /// Is image file
    /// </summary>
    public bool IsImage => ContentType.StartsWith("image/");
    
    /// <summary>
    /// هل الملف فيديو
    /// Is video file
    /// </summary>
    public bool IsVideo => ContentType.StartsWith("video/");
    
    /// <summary>
    /// هل الملف مستند
    /// Is document file
    /// </summary>
    public bool IsDocument => ContentType.StartsWith("application/") || ContentType.StartsWith("text/");
    
    /// <summary>
    /// حجم الملف المنسق
    /// Formatted file size
    /// </summary>
    public string FormattedSize
    {
        get
        {
            string[] sizes = { "B", "KB", "MB", "GB", "TB" };
            double len = Size;
            int order = 0;
            while (len >= 1024 && order < sizes.Length - 1)
            {
                order++;
                len = len / 1024;
            }
            return $"{len:0.##} {sizes[order]}";
        }
    }
}