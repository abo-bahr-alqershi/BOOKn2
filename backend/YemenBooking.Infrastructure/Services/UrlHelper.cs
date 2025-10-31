using System;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// خدمة مساعدة لمعالجة عناوين URL
    /// URL helper service implementation
    /// </summary>
    public class UrlHelper : IUrlHelper
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IConfiguration _configuration;

        public UrlHelper(IHttpContextAccessor httpContextAccessor, IConfiguration configuration)
        {
            _httpContextAccessor = httpContextAccessor;
            _configuration = configuration;
        }

        public string GetBaseUrl()
        {
            // Try to get from HttpContext first (most accurate)
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext != null)
            {
                var request = httpContext.Request;
                return $"{request.Scheme}://{request.Host}";
            }

            // Fallback to configuration
            var baseUrl = _configuration["BaseUrl"];
            if (!string.IsNullOrEmpty(baseUrl))
            {
                return baseUrl;
            }

            // Fallback to default
            return "http://localhost:5000";
        }

        public string ToAbsoluteUrl(string? relativePath)
        {
            if (string.IsNullOrWhiteSpace(relativePath))
            {
                return string.Empty;
            }

            // Already absolute URL
            if (relativePath.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                relativePath.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                return relativePath;
            }

            // Ensure path starts with /
            if (!relativePath.StartsWith("/"))
            {
                relativePath = "/" + relativePath;
            }

            var baseUrl = GetBaseUrl();
            return $"{baseUrl}{relativePath}";
        }

        public string ToRelativePath(string? absoluteUrl)
        {
            if (string.IsNullOrWhiteSpace(absoluteUrl))
            {
                return string.Empty;
            }

            // Already relative path
            if (!absoluteUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) &&
                !absoluteUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                return absoluteUrl;
            }

            try
            {
                var uri = new Uri(absoluteUrl);
                return uri.PathAndQuery;
            }
            catch
            {
                return absoluteUrl;
            }
        }
    }
}
