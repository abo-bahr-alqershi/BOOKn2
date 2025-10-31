using System.Threading;
using System.Threading.Tasks;

namespace YemenBooking.Application.Features.Authentication.Services
{
    /// <summary>
    /// خدمة التحقق من مصادقة مزودي الطرف الثالث (Google/Facebook)
    /// Third-party social auth verification service
    /// </summary>
    public interface ISocialAuthService
    {
        Task<SocialUserInfo> VerifyGoogleIdTokenAsync(string idToken, CancellationToken cancellationToken = default);
        Task<SocialUserInfo> VerifyFacebookAccessTokenAsync(string accessToken, CancellationToken cancellationToken = default);
    }

    /// <summary>
    /// معلومات المستخدم المستخرجة من مزود المصادقة الاجتماعية
    /// Normalized user info from social provider
    /// </summary>
    public class SocialUserInfo
    {
        public string Provider { get; set; } = string.Empty; // google, facebook
        public string ProviderUserId { get; set; } = string.Empty; // sub for google, id for facebook
        public string? Email { get; set; }
        public string? Name { get; set; }
        public string? PictureUrl { get; set; }
    }
}
