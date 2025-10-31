using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Common.Interfaces;
using System.Text.Json;

namespace YemenBooking.Application.Features.Authentication.Commands.Login;

public class SocialLoginCommand : IRequest<ResultDto<ClientLoginUserResponse>>
{
    public string Provider { get; set; } = string.Empty; // google | facebook
    public string Token { get; set; } = string.Empty; // id_token (google) | access_token (facebook)
}

public class SocialLoginCommandHandler : IRequestHandler<SocialLoginCommand, ResultDto<ClientLoginUserResponse>>
{
    private readonly ISocialAuthService _socialAuthService;
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHashingService _passwordHashingService;
    private readonly IAuthenticationService _authService;
    private readonly ILogger<SocialLoginCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

    public SocialLoginCommandHandler(
        ISocialAuthService socialAuthService,
        IUserRepository userRepository,
        IPasswordHashingService passwordHashingService,
        IAuthenticationService authService,
        ILogger<SocialLoginCommandHandler> logger,
        IAuditService auditService,
        ICurrentUserService currentUserService)
    {
        _socialAuthService = socialAuthService;
        _userRepository = userRepository;
        _passwordHashingService = passwordHashingService;
        _authService = authService;
        _logger = logger;
        _auditService = auditService;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto<ClientLoginUserResponse>> Handle(SocialLoginCommand request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Provider) || string.IsNullOrWhiteSpace(request.Token))
        {
            return ResultDto<ClientLoginUserResponse>.Failed("المزوّد أو التوكن مفقود", "PROVIDER_OR_TOKEN_MISSING");
        }

        try
        {
            var provider = request.Provider.Trim().ToLowerInvariant();
            SocialUserInfo info;
            switch (provider)
            {
                case "google":
                    info = await _socialAuthService.VerifyGoogleIdTokenAsync(request.Token, cancellationToken);
                    break;
                case "facebook":
                    info = await _socialAuthService.VerifyFacebookAccessTokenAsync(request.Token, cancellationToken);
                    break;
                default:
                    return ResultDto<ClientLoginUserResponse>.Failed("مزود غير مدعوم", "UNSUPPORTED_PROVIDER");
            }

            if (info == null || string.IsNullOrWhiteSpace(info.ProviderUserId))
            {
                return ResultDto<ClientLoginUserResponse>.Failed("تعذر التحقق من هوية المستخدم", "VERIFICATION_FAILED");
            }

            // Try find user by email first
            User? user = null;
            if (!string.IsNullOrWhiteSpace(info.Email))
            {
                user = await _userRepository.GetUserByEmailAsync(info.Email!, cancellationToken);
            }

            // If not found, create a new user
            if (user == null)
            {
                var pseudoEmail = info.Email ?? $"{info.ProviderUserId}@{provider}.local";
                var hashedPassword = await _passwordHashingService.HashPasswordAsync(Guid.NewGuid().ToString("N"), cancellationToken);
                user = new User
                {
                    Id = Guid.NewGuid(),
                    Name = string.IsNullOrWhiteSpace(info.Name) ? provider == "google" ? "Google User" : "Facebook User" : info.Name!,
                    Email = pseudoEmail,
                    Phone = string.Empty,
                    Password = hashedPassword,
                    ProfileImage = info.PictureUrl,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true,
                    EmailConfirmed = true,
                    IsEmailVerified = true,
                    SettingsJson = "{}",
                    FavoritesJson = "[]",
                };
                await _userRepository.CreateUserAsync(user, cancellationToken);
            }
            else
            {
                // Update basic profile info
                var changed = false;
                if (!string.IsNullOrWhiteSpace(info.Name) && info.Name != user.Name) { user.Name = info.Name!; changed = true; }
                if (!string.IsNullOrWhiteSpace(info.PictureUrl) && info.PictureUrl != user.ProfileImage) { user.ProfileImage = info.PictureUrl; changed = true; }
                if (!user.IsEmailVerified) { user.IsEmailVerified = true; user.EmailConfirmed = true; changed = true; }
                if (changed)
                {
                    user.UpdatedAt = DateTime.UtcNow;
                    await _userRepository.UpdateUserAsync(user, cancellationToken);
                }
            }

            // Persist provider mapping into SettingsJson
            try
            {
                var settings = string.IsNullOrWhiteSpace(user.SettingsJson) ? new Dictionary<string, object>() :
                    JsonSerializer.Deserialize<Dictionary<string, object>>(user.SettingsJson) ?? new Dictionary<string, object>();
                var social = settings.ContainsKey("social") && settings["social"] is JsonElement je && je.ValueKind == JsonValueKind.Object
                    ? JsonSerializer.Deserialize<Dictionary<string, object>>(je.GetRawText())!
                    : settings.ContainsKey("social") && settings["social"] is Dictionary<string, object> d ? d : new Dictionary<string, object>();

                social[provider] = new { id = info.ProviderUserId, email = info.Email };
                settings["social"] = social;
                user.SettingsJson = JsonSerializer.Serialize(settings);
                user.UpdatedAt = DateTime.UtcNow;
                await _userRepository.UpdateUserAsync(user, cancellationToken);
            }
            catch { }

            // Issue tokens
            var authResult = await _authService.IssueTokensForUserAsync(user.Id, cancellationToken);

            var response = new ClientLoginUserResponse
            {
                UserId = authResult.UserId,
                Name = authResult.UserName,
                Email = authResult.Email,
                Phone = "",
                AccessToken = authResult.AccessToken,
                RefreshToken = authResult.RefreshToken,
                Roles = new List<string> { string.IsNullOrWhiteSpace(authResult.AccountRole) ? authResult.Role : authResult.AccountRole },
            };

            // Optional audit
            try
            {
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes = $"تم تسجيل دخول اجتماعي للمستخدم {authResult.UserId} عبر {provider} بواسطة {performerName} (ID={performerId})";
                await _auditService.LogAuditAsync(
                    entityType: "User",
                    entityId: authResult.UserId,
                    action: YemenBooking.Core.Entities.AuditAction.LOGIN,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { Success = true, Provider = provider }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);
            }
            catch { }

            return ResultDto<ClientLoginUserResponse>.Ok(response, "تم تسجيل الدخول بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Social login failed for provider {Provider}", request.Provider);
            return ResultDto<ClientLoginUserResponse>.Failed("فشل تسجيل الدخول الاجتماعي", "SOCIAL_LOGIN_FAILED");
        }
    }
}
