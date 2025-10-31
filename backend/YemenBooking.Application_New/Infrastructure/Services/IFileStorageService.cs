namespace YemenBooking.Application.Infrastructure.Services;

/// <summary>
/// واجهة خدمة تخزين الملفات
/// File storage service interface
/// </summary>
public interface IFileStorageService
{
    /// <summary>
    /// رفع ملف
    /// Upload file
    /// </summary>
    Task<FileUploadResult> UploadFileAsync(
        Stream fileStream,
        string fileName,
        string? contentType = null,
        string? folder = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// رفع ملف من byte array
    /// Upload file from byte array
    /// </summary>
    Task<FileUploadResult> UploadFileAsync(
        byte[] fileBytes,
        string fileName,
        string? contentType = null,
        string? folder = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تحميل ملف
    /// Download file
    /// </summary>
    Task<FileDownloadResult> DownloadFileAsync(
        string filePath,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف ملف
    /// Delete file
    /// </summary>
    Task<bool> DeleteFileAsync(
        string filePath,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود الملف
    /// Check if file exists
    /// </summary>
    Task<bool> FileExistsAsync(
        string filePath,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على رابط الملف
    /// Get file URL
    /// </summary>
    Task<string> GetFileUrlAsync(
        string filePath,
        TimeSpan? expiration = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// نسخ ملف
    /// Copy file
    /// </summary>
    Task<bool> CopyFileAsync(
        string sourceFilePath,
        string destinationFilePath,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// نقل ملف
    /// Move file
    /// </summary>
    Task<bool> MoveFileAsync(
        string sourceFilePath,
        string destinationFilePath,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على معلومات الملف
    /// Get file info
    /// </summary>
    Task<FileInfo?> GetFileInfoAsync(
        string filePath,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// نتيجة رفع الملف
/// File upload result
/// </summary>
public class FileUploadResult
{
    public bool IsSuccess { get; set; }
    public string? FilePath { get; set; }
    public string? FileUrl { get; set; }
    public string? FileName { get; set; }
    public long FileSizeBytes { get; set; }
    public string? ContentType { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// نتيجة تحميل الملف
/// File download result
/// </summary>
public class FileDownloadResult
{
    public bool IsSuccess { get; set; }
    public Stream? FileStream { get; set; }
    public byte[]? FileBytes { get; set; }
    public string? FileName { get; set; }
    public string? ContentType { get; set; }
    public long FileSizeBytes { get; set; }
    public string? ErrorMessage { get; set; }
}
