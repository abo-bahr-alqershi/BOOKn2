namespace YemenBooking.Application.Infrastructure.Services;

/// <summary>
/// واجهة خدمة معالجة الصور
/// Image processing service interface
/// </summary>
public interface IImageProcessingService
{
    /// <summary>
    /// تغيير حجم الصورة
    /// Resize image
    /// </summary>
    Task<ImageProcessingResult> ResizeImageAsync(
        Stream imageStream,
        int width,
        int height,
        ImageResizeMode mode = ImageResizeMode.Fit,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// قص الصورة
    /// Crop image
    /// </summary>
    Task<ImageProcessingResult> CropImageAsync(
        Stream imageStream,
        int x,
        int y,
        int width,
        int height,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// ضغط الصورة
    /// Compress image
    /// </summary>
    Task<ImageProcessingResult> CompressImageAsync(
        Stream imageStream,
        int quality = 85,
        ImageFormat? outputFormat = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إنشاء صورة مصغرة
    /// Generate thumbnail
    /// </summary>
    Task<ImageProcessingResult> GenerateThumbnailAsync(
        Stream imageStream,
        int maxWidth = 150,
        int maxHeight = 150,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تحويل صيغة الصورة
    /// Convert image format
    /// </summary>
    Task<ImageProcessingResult> ConvertFormatAsync(
        Stream imageStream,
        ImageFormat outputFormat,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إضافة علامة مائية
    /// Add watermark
    /// </summary>
    Task<ImageProcessingResult> AddWatermarkAsync(
        Stream imageStream,
        Stream watermarkStream,
        WatermarkPosition position = WatermarkPosition.BottomRight,
        float opacity = 0.5f,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إضافة نص كعلامة مائية
    /// Add text watermark
    /// </summary>
    Task<ImageProcessingResult> AddTextWatermarkAsync(
        Stream imageStream,
        string text,
        WatermarkPosition position = WatermarkPosition.BottomRight,
        string fontName = "Arial",
        int fontSize = 12,
        string color = "#FFFFFF",
        float opacity = 0.5f,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على معلومات الصورة
    /// Get image info
    /// </summary>
    Task<ImageInfo> GetImageInfoAsync(
        Stream imageStream,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من صحة الصورة
    /// Validate image
    /// </summary>
    Task<ImageValidationResult> ValidateImageAsync(
        Stream imageStream,
        ImageValidationOptions? options = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إنشاء عدة أحجام للصورة
    /// Generate multiple sizes
    /// </summary>
    Task<MultipleSizeResult> GenerateMultipleSizesAsync(
        Stream imageStream,
        ImageSize[] sizes,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// نتيجة معالجة الصورة
/// Image processing result
/// </summary>
public class ImageProcessingResult
{
    public bool IsSuccess { get; set; }
    public Stream? ProcessedImageStream { get; set; }
    public byte[]? ProcessedImageBytes { get; set; }
    public ImageInfo? ImageInfo { get; set; }
    public string? ErrorMessage { get; set; }
}

/// <summary>
/// معلومات الصورة
/// Image information
/// </summary>
public class ImageInfo
{
    public int Width { get; set; }
    public int Height { get; set; }
    public ImageFormat Format { get; set; }
    public long FileSizeBytes { get; set; }
    public string? ColorSpace { get; set; }
    public int BitsPerPixel { get; set; }
    public bool HasTransparency { get; set; }
    public string? MimeType { get; set; }
}

/// <summary>
/// نتيجة التحقق من صحة الصورة
/// Image validation result
/// </summary>
public class ImageValidationResult
{
    public bool IsValid { get; set; }
    public List<string> ValidationErrors { get; set; } = new();
    public ImageInfo? ImageInfo { get; set; }
}

/// <summary>
/// خيارات التحقق من صحة الصورة
/// Image validation options
/// </summary>
public class ImageValidationOptions
{
    public int? MaxWidth { get; set; }
    public int? MaxHeight { get; set; }
    public int? MinWidth { get; set; }
    public int? MinHeight { get; set; }
    public long? MaxFileSizeBytes { get; set; }
    public HashSet<ImageFormat>? AllowedFormats { get; set; }
    public bool RequireTransparency { get; set; } = false;
}

/// <summary>
/// نتيجة عدة أحجام
/// Multiple sizes result
/// </summary>
public class MultipleSizeResult
{
    public bool IsSuccess { get; set; }
    public Dictionary<string, ImageProcessingResult> Results { get; set; } = new();
    public string? ErrorMessage { get; set; }
}

/// <summary>
/// حجم الصورة
/// Image size
/// </summary>
public class ImageSize
{
    public string Name { get; set; } = null!;
    public int Width { get; set; }
    public int Height { get; set; }
    public ImageResizeMode Mode { get; set; } = ImageResizeMode.Fit;
}

/// <summary>
/// أنماط تغيير حجم الصورة
/// Image resize modes
/// </summary>
public enum ImageResizeMode
{
    Fit,
    Fill,
    Stretch,
    Crop
}

/// <summary>
/// صيغ الصور
/// Image formats
/// </summary>
public enum ImageFormat
{
    JPEG,
    PNG,
    GIF,
    BMP,
    TIFF,
    WEBP
}

/// <summary>
/// مواضع العلامة المائية
/// Watermark positions
/// </summary>
public enum WatermarkPosition
{
    TopLeft,
    TopCenter,
    TopRight,
    MiddleLeft,
    MiddleCenter,
    MiddleRight,
    BottomLeft,
    BottomCenter,
    BottomRight
}
