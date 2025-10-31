using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Infrastructure.Services;
using Microsoft.Extensions.Logging;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// خدمة رفع الملفات
    /// Implementation of IFileUploadService that stores files locally under Uploads folder
    /// </summary>
    public class FileUploadService : IFileUploadService
    {
        private readonly ILogger<FileUploadService> _logger;

        public FileUploadService(ILogger<FileUploadService> logger)
        {
            _logger = logger;
        }

        public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType, string folder = "uploads")
        {
            var root = Path.Combine(Directory.GetCurrentDirectory(), "Uploads", folder);
            Directory.CreateDirectory(root);
            var uniqueName = GenerateUniqueFileName(fileName);
            var fullPath = Path.Combine(root, uniqueName);
            using (var fs = new FileStream(fullPath, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                await fileStream.CopyToAsync(fs);
            }
            var url = $"/uploads/{folder}/{uniqueName}";
            _logger.LogInformation("Uploaded file {FileName} to {Path}", fileName, url);
            return url;
        }

        public async Task<List<string>> UploadFilesAsync(List<(Stream stream, string fileName, string contentType)> files, string folder = "uploads")
        {
            var urls = new List<string>();
            foreach (var (stream, fileName, contentType) in files)
            {
                var url = await UploadFileAsync(stream, fileName, contentType, folder);
                urls.Add(url);
            }
            return urls;
        }

        public async Task<string> UploadImageAsync(Stream imageStream, string fileName, int maxWidth = 1920, int maxHeight = 1080, int quality = 85, string folder = "images")
        {
            // Simple save; image processing can be added later
            return await UploadFileAsync(imageStream, fileName, "image/*", folder);
        }

        public async Task<string> UploadProfileImageAsync(Stream imageStream, string fileName, CancellationToken cancellationToken = default)
        {
            // Store under images/profile
            return await UploadImageAsync(imageStream, fileName, folder: Path.Combine("images", "profile"));
        }

        public Task<bool> DeleteFileAsync(string fileUrl)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(fileUrl)) return Task.FromResult(false);
                var relativePath = fileUrl.StartsWith("/uploads/") ? fileUrl.Replace("/uploads/", string.Empty) : fileUrl;
                var fullPath = Path.Combine(Directory.GetCurrentDirectory(), "Uploads", relativePath);
                if (File.Exists(fullPath))
                {
                    File.Delete(fullPath);
                    _logger.LogInformation("Deleted file {Path}", fileUrl);
                    return Task.FromResult(true);
                }
                return Task.FromResult(false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to delete file {Path}", fileUrl);
                return Task.FromResult(false);
            }
        }

        public async Task<bool> DeleteFilesAsync(List<string> fileUrls)
        {
            var results = await Task.WhenAll(fileUrls.Select(DeleteFileAsync));
            return results.All(x => x);
        }

        public bool IsValidFileType(string fileName, string[] allowedExtensions)
        {
            var extension = Path.GetExtension(fileName);
            return !string.IsNullOrWhiteSpace(extension) && allowedExtensions.Any(e => e.Equals(extension, StringComparison.OrdinalIgnoreCase));
        }

        public bool IsValidFileSize(long fileSize, int maxSizeInMB)
        {
            return fileSize <= maxSizeInMB * 1024 * 1024;
        }

        public string GenerateUniqueFileName(string originalFileName)
        {
            return $"{Guid.NewGuid()}{Path.GetExtension(originalFileName)}";
        }
    }
}