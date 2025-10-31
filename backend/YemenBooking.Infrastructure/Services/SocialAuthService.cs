using System;
using System.Net.Http;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Google.Apis.Auth;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Infrastructure.Settings;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تحقق من رموز Google/Facebook وإرجاع معلومات المستخدم الموثقة
    /// </summary>
    public class SocialAuthService : ISocialAuthService
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<SocialAuthService> _logger;
        private readonly SocialAuthSettings _settings;

        public SocialAuthService(
            IHttpClientFactory httpClientFactory,
            ILogger<SocialAuthService> logger,
            IOptions<SocialAuthSettings> settings)
        {
            _httpClientFactory = httpClientFactory;
            _logger = logger;
            _settings = settings.Value;
        }

        public async Task<SocialUserInfo> VerifyGoogleIdTokenAsync(string idToken, CancellationToken cancellationToken = default)
        {
            try
            {
                var validationSettings = new GoogleJsonWebSignature.ValidationSettings
                {
                    Audience = _settings.GoogleClientIds is { Length: > 0 } ? _settings.GoogleClientIds : null
                };
                var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, validationSettings);
                return new SocialUserInfo
                {
                    Provider = "google",
                    ProviderUserId = payload.Subject,
                    Email = payload.Email,
                    Name = payload.Name,
                    PictureUrl = payload.Picture
                };
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Google ID token validation failed");
                throw;
            }
        }

        public async Task<SocialUserInfo> VerifyFacebookAccessTokenAsync(string accessToken, CancellationToken cancellationToken = default)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(_settings.FacebookAppId) || string.IsNullOrWhiteSpace(_settings.FacebookAppSecret))
                {
                    throw new InvalidOperationException("Missing FacebookAppId/AppSecret in configuration");
                }

                var http = _httpClientFactory.CreateClient();

                // Validate token
                var appAccess = $"{_settings.FacebookAppId}|{_settings.FacebookAppSecret}";
                var debugUrl = $"https://graph.facebook.com/debug_token?input_token={Uri.EscapeDataString(accessToken)}&access_token={Uri.EscapeDataString(appAccess)}";
                using (var debugResp = await http.GetAsync(debugUrl, cancellationToken))
                {
                    debugResp.EnsureSuccessStatusCode();
                    var json = await debugResp.Content.ReadAsStringAsync(cancellationToken);
                    using var doc = JsonDocument.Parse(json);
                    var data = doc.RootElement.GetProperty("data");
                    var isValid = data.TryGetProperty("is_valid", out var isValidEl) && isValidEl.GetBoolean();
                    if (!isValid)
                    {
                        throw new InvalidOperationException("Invalid Facebook access token");
                    }
                }

                // Fetch user info
                var meUrl = $"https://graph.facebook.com/me?fields=id,name,email,picture&type=large&access_token={Uri.EscapeDataString(accessToken)}";
                using var meResp = await http.GetAsync(meUrl, cancellationToken);
                meResp.EnsureSuccessStatusCode();
                var meJson = await meResp.Content.ReadAsStringAsync(cancellationToken);
                using var meDoc = JsonDocument.Parse(meJson);
                var root = meDoc.RootElement;
                var id = root.GetProperty("id").GetString();
                var name = root.TryGetProperty("name", out var nameEl) ? nameEl.GetString() : null;
                var email = root.TryGetProperty("email", out var emailEl) ? emailEl.GetString() : null;
                string? pictureUrl = null;
                if (root.TryGetProperty("picture", out var pic) && pic.TryGetProperty("data", out var dataEl) && dataEl.TryGetProperty("url", out var urlEl))
                {
                    pictureUrl = urlEl.GetString();
                }

                return new SocialUserInfo
                {
                    Provider = "facebook",
                    ProviderUserId = id ?? string.Empty,
                    Email = email,
                    Name = name,
                    PictureUrl = pictureUrl
                };
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Facebook access token validation failed");
                throw;
            }
        }
    }
}
