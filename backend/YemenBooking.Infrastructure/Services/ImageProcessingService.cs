using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats;
using SixLabors.ImageSharp.Formats.Bmp;
using SixLabors.ImageSharp.Formats.Gif;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.Formats.Tiff;
using SixLabors.ImageSharp.Formats.Webp;
using SixLabors.ImageSharp.Processing;
using SixLabors.ImageSharp.Drawing.Processing;
using SixLabors.Fonts;
using System.Collections.Concurrent;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Services;

/// <summary>
/// تنفيذ خدمة معالجة الصور
/// Image processing service implementation
/// </summary>
public class ImageProcessingService : IImageProcessingService
{
    private readonly ILogger<ImageProcessingService> _logger;
    private readonly ImageProcessingOptions _options;
    private readonly ConcurrentDictionary<string, FontFamily> _fontCache;
    
    private static readonly Dictionary<ImageFormat, IImageFormat> FormatMapping = new()
    {
        { ImageFormat.JPEG, JpegFormat.Instance },
        { ImageFormat.PNG, PngFormat.Instance },
        { ImageFormat.GIF, GifFormat.Instance },
        { ImageFormat.BMP, BmpFormat.Instance },
        { ImageFormat.TIFF, TiffFormat.Instance },
        { ImageFormat.WEBP, WebpFormat.Instance }
    };

    public ImageProcessingService(
        ILogger<ImageProcessingService> logger,
        IOptions<ImageProcessingOptions> options)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _options = options?.Value ?? new ImageProcessingOptions();
        _fontCache = new ConcurrentDictionary<string, FontFamily>();
    }

    public async Task<ImageProcessingResult> ResizeImageAsync(
        Stream imageStream,
        int width,
        int height,
        ImageResizeMode mode = ImageResizeMode.Fit,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ValidateInputStream(imageStream);
            ValidateDimensions(width, height);

            using var image = await Image.LoadAsync(imageStream, cancellationToken);
            
            var resizeOptions = new ResizeOptions
            {
                Size = new Size(width, height),
                Mode = MapResizeMode(mode)
            };

            image.Mutate(x => x.Resize(resizeOptions));

            var result = await CreateResultAsync(image, cancellationToken);
            
            _logger.LogInformation("Image resized successfully to {Width}x{Height} using mode {Mode}", 
                width, height, mode);
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error resizing image to {Width}x{Height}", width, height);
            return new ImageProcessingResult
            {
                IsSuccess = false,
                ErrorMessage = ex.Message
            };
        }
    }

    public async Task<ImageProcessingResult> CropImageAsync(
        Stream imageStream,
        int x,
        int y,
        int width,
        int height,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ValidateInputStream(imageStream);
            ValidateDimensions(width, height);
            ValidateCoordinates(x, y);

            using var image = await Image.LoadAsync(imageStream, cancellationToken);
            
            var cropRectangle = new Rectangle(x, y, width, height);
            
            if (cropRectangle.Right > image.Width || cropRectangle.Bottom > image.Height)
            {
                throw new ArgumentException("Crop rectangle exceeds image boundaries");
            }

            image.Mutate(ctx => ctx.Crop(cropRectangle));

            var result = await CreateResultAsync(image, cancellationToken);
            
            _logger.LogInformation("Image cropped successfully at ({X},{Y}) with size {Width}x{Height}", 
                x, y, width, height);
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error cropping image at ({X},{Y}) with size {Width}x{Height}", 
                x, y, width, height);
            return new ImageProcessingResult
            {
                IsSuccess = false,
                ErrorMessage = ex.Message
            };
        }
    }

    public async Task<ImageProcessingResult> CompressImageAsync(
        Stream imageStream,
        int quality = 85,
        ImageFormat? outputFormat = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ValidateInputStream(imageStream);
            ValidateQuality(quality);

            using var image = await Image.LoadAsync(imageStream, cancellationToken);
            
            var format = outputFormat ?? DetectImageFormat(image);
            var encoder = CreateEncoder(format, quality);

            using var outputStream = new MemoryStream();
            await image.SaveAsync(outputStream, encoder, cancellationToken);
            
            outputStream.Position = 0;
            var compressedBytes = outputStream.ToArray();
            
            var result = new ImageProcessingResult
            {
                IsSuccess = true,
                ProcessedImageStream = new MemoryStream(compressedBytes),
                ProcessedImageBytes = compressedBytes,
                ImageInfo = CreateImageInfo(image, compressedBytes.Length)
            };
            
            _logger.LogInformation("Image compressed successfully with quality {Quality} to format {Format}", 
                quality, format);
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error compressing image with quality {Quality}", quality);
            return new ImageProcessingResult
            {
                IsSuccess = false,
                ErrorMessage = ex.Message
            };
        }
    }

    public async Task<ImageProcessingResult> GenerateThumbnailAsync(
        Stream imageStream,
        int maxWidth = 150,
        int maxHeight = 150,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ValidateInputStream(imageStream);
            ValidateDimensions(maxWidth, maxHeight);

            using var image = await Image.LoadAsync(imageStream, cancellationToken);
            
            var aspectRatio = (double)image.Width / image.Height;
            int thumbWidth, thumbHeight;
            
            if (aspectRatio > 1) // Landscape
            {
                thumbWidth = Math.Min(maxWidth, image.Width);
                thumbHeight = (int)(thumbWidth / aspectRatio);
            }
            else // Portrait or Square
            {
                thumbHeight = Math.Min(maxHeight, image.Height);
                thumbWidth = (int)(thumbHeight * aspectRatio);
            }

            image.Mutate(x => x.Resize(new ResizeOptions
            {
                Size = new Size(thumbWidth, thumbHeight),
                Mode = ResizeMode.Max
            }));

            var result = await CreateResultAsync(image, cancellationToken);
            
            _logger.LogInformation("Thumbnail generated successfully with max size {MaxWidth}x{MaxHeight}", 
                maxWidth, maxHeight);
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating thumbnail with max size {MaxWidth}x{MaxHeight}", 
                maxWidth, maxHeight);
            return new ImageProcessingResult
            {
                IsSuccess = false,
                ErrorMessage = ex.Message
            };
        }
    }

    public async Task<ImageProcessingResult> ConvertFormatAsync(
        Stream imageStream,
        ImageFormat outputFormat,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ValidateInputStream(imageStream);

            using var image = await Image.LoadAsync(imageStream, cancellationToken);
            
            var encoder = CreateEncoder(outputFormat);
            
            using var outputStream = new MemoryStream();
            await image.SaveAsync(outputStream, encoder, cancellationToken);
            
            outputStream.Position = 0;
            var convertedBytes = outputStream.ToArray();
            
            var result = new ImageProcessingResult
            {
                IsSuccess = true,
                ProcessedImageStream = new MemoryStream(convertedBytes),
                ProcessedImageBytes = convertedBytes,
                ImageInfo = CreateImageInfo(image, convertedBytes.Length)
            };
            
            _logger.LogInformation("Image format converted successfully to {OutputFormat}", outputFormat);
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error converting image to format {OutputFormat}", outputFormat);
            return new ImageProcessingResult
            {
                IsSuccess = false,
                ErrorMessage = ex.Message
            };
        }
    }

    public async Task<ImageProcessingResult> AddWatermarkAsync(
        Stream imageStream,
        Stream watermarkStream,
        WatermarkPosition position = WatermarkPosition.BottomRight,
        float opacity = 0.5f,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ValidateInputStream(imageStream);
            ValidateInputStream(watermarkStream);
            ValidateOpacity(opacity);

            using var image = await Image.LoadAsync(imageStream, cancellationToken);
            using var watermark = await Image.LoadAsync(watermarkStream, cancellationToken);
            
            var location = CalculateWatermarkPosition(image.Size, watermark.Size, position);
            
            watermark.Mutate(x => x.Opacity(opacity));
            
            image.Mutate(x => x.DrawImage(watermark, location, 1f));

            var result = await CreateResultAsync(image, cancellationToken);
            
            _logger.LogInformation("Watermark added successfully at position {Position} with opacity {Opacity}", 
                position, opacity);
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding watermark at position {Position}", position);
            return new ImageProcessingResult
            {
                IsSuccess = false,
                ErrorMessage = ex.Message
            };
        }
    }

    public async Task<ImageProcessingResult> AddTextWatermarkAsync(
        Stream imageStream,
        string text,
        WatermarkPosition position = WatermarkPosition.BottomRight,
        string fontName = "Arial",
        int fontSize = 12,
        string color = "#FFFFFF",
        float opacity = 0.5f,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ValidateInputStream(imageStream);
            ValidateText(text);
            ValidateOpacity(opacity);

            using var image = await Image.LoadAsync(imageStream, cancellationToken);
            
            var font = await GetFontAsync(fontName, fontSize);
            var textColor = Color.ParseHex(color);
            
            var textPosition = CalculateTextPosition(image.Size, text, font, position);
            textColor = textColor.WithAlpha(opacity);
            
            image.Mutate(x => x.DrawText(text, font, textColor, textPosition));

            var result = await CreateResultAsync(image, cancellationToken);
            
            _logger.LogInformation("Text watermark added successfully: '{Text}' at position {Position}", 
                text, position);
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding text watermark: '{Text}' at position {Position}", 
                text, position);
            return new ImageProcessingResult
            {
                IsSuccess = false,
                ErrorMessage = ex.Message
            };
        }
    }

    public async Task<Application.Infrastructure.Services.ImageInfo> GetImageInfoAsync(
        Stream imageStream,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ValidateInputStream(imageStream);

            using var image = await Image.LoadAsync(imageStream, cancellationToken);
            
            var info = CreateImageInfo(image, imageStream.Length);
            
            _logger.LogInformation("Image info retrieved successfully for {Width}x{Height} image", 
                info.Width, info.Height);
            
            return info;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting image info");
            throw;
        }
    }

    public async Task<ImageValidationResult> ValidateImageAsync(
        Stream imageStream,
        ImageValidationOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ValidateInputStream(imageStream);
            options ??= new ImageValidationOptions();

            var result = new ImageValidationResult { IsValid = true };
            
            using var image = await Image.LoadAsync(imageStream, cancellationToken);
            
            result.ImageInfo = CreateImageInfo(image, imageStream.Length);
            
            ValidateImageDimensions(image, options, result);
            ValidateImageFormat(image, options, result);
            ValidateImageSize(imageStream, options, result);
            ValidateImageTransparency(image, options, result);
            
            _logger.LogInformation("Image validation completed. Valid: {IsValid}", result.IsValid);
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating image");
            return new ImageValidationResult
            {
                IsValid = false,
                ValidationErrors = new List<string> { ex.Message }
            };
        }
    }

    public async Task<MultipleSizeResult> GenerateMultipleSizesAsync(
        Stream imageStream,
        ImageSize[] sizes,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ValidateInputStream(imageStream);
            ValidateSizes(sizes);

            var result = new MultipleSizeResult { IsSuccess = true };
            
            foreach (var size in sizes)
            {
                imageStream.Position = 0;
                var sizeResult = await ResizeImageAsync(
                    imageStream, 
                    size.Width, 
                    size.Height, 
                    size.Mode, 
                    cancellationToken);
                
                result.Results[size.Name] = sizeResult;
                
                if (!sizeResult.IsSuccess)
                {
                    result.IsSuccess = false;
                    result.ErrorMessage = $"Failed to generate size '{size.Name}': {sizeResult.ErrorMessage}";
                    break;
                }
            }
            
            _logger.LogInformation("Multiple sizes generated successfully for {Count} sizes", sizes.Length);
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating multiple sizes");
            return new MultipleSizeResult
            {
                IsSuccess = false,
                ErrorMessage = ex.Message
            };
        }
    }

    #region Private Helper Methods

    private static void ValidateInputStream(Stream stream)
    {
        if (stream == null)
            throw new ArgumentNullException(nameof(stream));
        
        if (!stream.CanRead)
            throw new ArgumentException("Stream must be readable", nameof(stream));
    }

    private static void ValidateDimensions(int width, int height)
    {
        if (width <= 0 || height <= 0)
            throw new ArgumentException("Width and height must be positive");
    }

    private static void ValidateCoordinates(int x, int y)
    {
        if (x < 0 || y < 0)
            throw new ArgumentException("Coordinates must be non-negative");
    }

    private static void ValidateQuality(int quality)
    {
        if (quality < 1 || quality > 100)
            throw new ArgumentException("Quality must be between 1 and 100");
    }

    private static void ValidateOpacity(float opacity)
    {
        if (opacity < 0f || opacity > 1f)
            throw new ArgumentException("Opacity must be between 0 and 1");
    }

    private static void ValidateText(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
            throw new ArgumentException("Text cannot be null or empty");
    }

    private static void ValidateSizes(ImageSize[] sizes)
    {
        if (sizes == null || sizes.Length == 0)
            throw new ArgumentException("Sizes array cannot be null or empty");
        
        foreach (var size in sizes)
        {
            if (string.IsNullOrWhiteSpace(size.Name))
                throw new ArgumentException("Size name cannot be null or empty");
            
            ValidateDimensions(size.Width, size.Height);
        }
    }

    private static ResizeMode MapResizeMode(ImageResizeMode mode)
    {
        return mode switch
        {
            ImageResizeMode.Fit => ResizeMode.Max,
            ImageResizeMode.Fill => ResizeMode.Pad,
            ImageResizeMode.Stretch => ResizeMode.Stretch,
            ImageResizeMode.Crop => ResizeMode.Crop,
            _ => ResizeMode.Max
        };
    }

    private static ImageFormat DetectImageFormat(Image image)
    {
        var formatName = image.Metadata.DecodedImageFormat?.Name?.ToUpperInvariant();
        return formatName switch
        {
            "JPEG" => ImageFormat.JPEG,
            "PNG" => ImageFormat.PNG,
            "GIF" => ImageFormat.GIF,
            "BMP" => ImageFormat.BMP,
            "TIFF" => ImageFormat.TIFF,
            "WEBP" => ImageFormat.WEBP,
            _ => ImageFormat.JPEG
        };
    }

    private static IImageEncoder CreateEncoder(ImageFormat format, int quality = 85)
    {
        return format switch
        {
            ImageFormat.JPEG => new JpegEncoder { Quality = quality },
            ImageFormat.PNG => new PngEncoder(),
            ImageFormat.GIF => new GifEncoder(),
            ImageFormat.BMP => new BmpEncoder(),
            ImageFormat.TIFF => new TiffEncoder(),
            ImageFormat.WEBP => new WebpEncoder { Quality = quality },
            _ => new JpegEncoder { Quality = quality }
        };
    }

    private static Application.Infrastructure.Services.ImageInfo CreateImageInfo(Image image, long fileSize)
    {
        var format = DetectImageFormat(image);

        return new Application.Infrastructure.Services.ImageInfo
        {
            Width = image.Width,
            Height = image.Height,
            Format = format,
            FileSizeBytes = fileSize,
            ColorSpace = image.PixelType.ToString(),
            BitsPerPixel = image.PixelType.BitsPerPixel,
            HasTransparency = image.Metadata.DecodedImageFormat?.Name?.ToUpperInvariant() == "PNG",
            MimeType = GetMimeType(format)
        };
    }

    private static string GetMimeType(ImageFormat format)
    {
        return format switch
        {
            ImageFormat.JPEG => "image/jpeg",
            ImageFormat.PNG => "image/png",
            ImageFormat.GIF => "image/gif",
            ImageFormat.BMP => "image/bmp",
            ImageFormat.TIFF => "image/tiff",
            ImageFormat.WEBP => "image/webp",
            _ => "image/jpeg"
        };
    }

    private static Point CalculateWatermarkPosition(Size imageSize, Size watermarkSize, WatermarkPosition position)
    {
        const int margin = 10;
        
        return position switch
        {
            WatermarkPosition.TopLeft => new Point(margin, margin),
            WatermarkPosition.TopCenter => new Point((imageSize.Width - watermarkSize.Width) / 2, margin),
            WatermarkPosition.TopRight => new Point(imageSize.Width - watermarkSize.Width - margin, margin),
            WatermarkPosition.MiddleLeft => new Point(margin, (imageSize.Height - watermarkSize.Height) / 2),
            WatermarkPosition.MiddleCenter => new Point((imageSize.Width - watermarkSize.Width) / 2, (imageSize.Height - watermarkSize.Height) / 2),
            WatermarkPosition.MiddleRight => new Point(imageSize.Width - watermarkSize.Width - margin, (imageSize.Height - watermarkSize.Height) / 2),
            WatermarkPosition.BottomLeft => new Point(margin, imageSize.Height - watermarkSize.Height - margin),
            WatermarkPosition.BottomCenter => new Point((imageSize.Width - watermarkSize.Width) / 2, imageSize.Height - watermarkSize.Height - margin),
            WatermarkPosition.BottomRight => new Point(imageSize.Width - watermarkSize.Width - margin, imageSize.Height - watermarkSize.Height - margin),
            _ => new Point(imageSize.Width - watermarkSize.Width - margin, imageSize.Height - watermarkSize.Height - margin)
        };
    }

    private static PointF CalculateTextPosition(Size imageSize, string text, Font font, WatermarkPosition position)
    {
        const int margin = 10;
        
        // تقدير حجم النص
        var textSize = TextMeasurer.MeasureAdvance(text, new TextOptions(font));
        
        return position switch
        {
            WatermarkPosition.TopLeft => new PointF(margin, margin),
            WatermarkPosition.TopCenter => new PointF((imageSize.Width - textSize.Width) / 2, margin),
            WatermarkPosition.TopRight => new PointF(imageSize.Width - textSize.Width - margin, margin),
            WatermarkPosition.MiddleLeft => new PointF(margin, (imageSize.Height - textSize.Height) / 2),
            WatermarkPosition.MiddleCenter => new PointF((imageSize.Width - textSize.Width) / 2, (imageSize.Height - textSize.Height) / 2),
            WatermarkPosition.MiddleRight => new PointF(imageSize.Width - textSize.Width - margin, (imageSize.Height - textSize.Height) / 2),
            WatermarkPosition.BottomLeft => new PointF(margin, imageSize.Height - textSize.Height - margin),
            WatermarkPosition.BottomCenter => new PointF((imageSize.Width - textSize.Width) / 2, imageSize.Height - textSize.Height - margin),
            WatermarkPosition.BottomRight => new PointF(imageSize.Width - textSize.Width - margin, imageSize.Height - textSize.Height - margin),
            _ => new PointF(imageSize.Width - textSize.Width - margin, imageSize.Height - textSize.Height - margin)
        };
    }

    private async Task<Font> GetFontAsync(string fontName, int fontSize)
    {
        var fontFamily = _fontCache.GetOrAdd(fontName, name =>
        {
            try
            {
                var collection = new FontCollection();
                return collection.Add($"fonts/{name}.ttf");
            }
            catch
            {
                // Fallback to system font
                return SystemFonts.Get(name);
            }
        });

        return fontFamily.CreateFont(fontSize);
    }

    private async Task<ImageProcessingResult> CreateResultAsync(Image image, CancellationToken cancellationToken)
    {
        using var outputStream = new MemoryStream();
        await image.SaveAsync(outputStream, image.Metadata.DecodedImageFormat ?? JpegFormat.Instance, cancellationToken);
        
        outputStream.Position = 0;
        var processedBytes = outputStream.ToArray();
        
        return new ImageProcessingResult
        {
            IsSuccess = true,
            ProcessedImageStream = new MemoryStream(processedBytes),
            ProcessedImageBytes = processedBytes,
            ImageInfo = CreateImageInfo(image, processedBytes.Length)
        };
    }

    private static void ValidateImageDimensions(Image image, ImageValidationOptions options, ImageValidationResult result)
    {
        if (options.MaxWidth.HasValue && image.Width > options.MaxWidth.Value)
            result.ValidationErrors.Add($"Image width {image.Width} exceeds maximum {options.MaxWidth.Value}");
        
        if (options.MaxHeight.HasValue && image.Height > options.MaxHeight.Value)
            result.ValidationErrors.Add($"Image height {image.Height} exceeds maximum {options.MaxHeight.Value}");
        
        if (options.MinWidth.HasValue && image.Width < options.MinWidth.Value)
            result.ValidationErrors.Add($"Image width {image.Width} is below minimum {options.MinWidth.Value}");
        
        if (options.MinHeight.HasValue && image.Height < options.MinHeight.Value)
            result.ValidationErrors.Add($"Image height {image.Height} is below minimum {options.MinHeight.Value}");
    }

    private static void ValidateImageFormat(Image image, ImageValidationOptions options, ImageValidationResult result)
    {
        if (options.AllowedFormats?.Any() == true)
        {
            var imageFormat = DetectImageFormat(image);
            if (!options.AllowedFormats.Contains(imageFormat))
            {
                result.ValidationErrors.Add($"Image format {imageFormat} is not allowed");
            }
        }
    }

    private static void ValidateImageSize(Stream imageStream, ImageValidationOptions options, ImageValidationResult result)
    {
        if (options.MaxFileSizeBytes.HasValue && imageStream.Length > options.MaxFileSizeBytes.Value)
        {
            result.ValidationErrors.Add($"Image file size {imageStream.Length} bytes exceeds maximum {options.MaxFileSizeBytes.Value} bytes");
        }
    }

    private static void ValidateImageTransparency(Image image, ImageValidationOptions options, ImageValidationResult result)
    {
        if (options.RequireTransparency)
        {
            var hasTransparency = image.Metadata.DecodedImageFormat?.Name?.ToUpperInvariant() == "PNG";
            if (!hasTransparency)
            {
                result.ValidationErrors.Add("Image must support transparency");
            }
        }
    }

    #endregion
}

/// <summary>
/// خيارات إعداد خدمة معالجة الصور
/// Image processing service options
/// </summary>
public class ImageProcessingOptions
{
    public int DefaultQuality { get; set; } = 85;
    public int MaxImageWidth { get; set; } = 4096;
    public int MaxImageHeight { get; set; } = 4096;
    public long MaxFileSizeBytes { get; set; } = 10 * 1024 * 1024; // 10MB
    public string DefaultFontName { get; set; } = "Arial";
    public int DefaultFontSize { get; set; } = 12;
    public string DefaultWatermarkColor { get; set; } = "#FFFFFF";
    public float DefaultWatermarkOpacity { get; set; } = 0.5f;
}