namespace YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;

/// <summary>
/// واجهة خدمة تشفير كلمات المرور
/// Password hashing service interface
/// </summary>
public interface IPasswordHashingService
{
    /// <summary>
    /// تشفير كلمة المرور
    /// Hash password
    /// </summary>
    Task<string> HashPasswordAsync(string password, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من كلمة المرور
    /// Verify password
    /// </summary>
    Task<bool> VerifyPasswordAsync(string password, string hashedPassword, CancellationToken cancellationToken = default);

    /// <summary>
    /// توليد كلمة مرور عشوائية
    /// Generate random password
    /// </summary>
    Task<string> GenerateRandomPasswordAsync(int length = 12, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من قوة كلمة المرور
    /// Validate password strength
    /// </summary>
    Task<(bool IsValid, string[] Issues)> ValidatePasswordStrengthAsync(string password, CancellationToken cancellationToken = default);
}
