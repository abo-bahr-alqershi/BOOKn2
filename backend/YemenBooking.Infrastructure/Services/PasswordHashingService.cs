using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Authentication.Services;
using System.Security.Cryptography;
using System.Text;
using System.Linq;
using System.Collections.Generic;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة تشفير كلمة المرور
    /// Password hashing service implementation
    /// </summary>
    public class PasswordHashingService : IPasswordHashingService
    {
        private readonly ILogger<PasswordHashingService> _logger;

        public PasswordHashingService(ILogger<PasswordHashingService> logger)
        {
            _logger = logger;
        }

        /// <inheritdoc />
        public Task<string> HashPasswordAsync(string password, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("تشفير كلمة المرور");
            // إنشاء ملح عشوائي
            var salt = new byte[16];
            RandomNumberGenerator.Fill(salt);
            // اشتقاق المفتاح باستخدام PBKDF2
            using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 100_000, HashAlgorithmName.SHA256);
            var hash = pbkdf2.GetBytes(32);
            // دمج الملح والتجزئة
            var saltB64 = Convert.ToBase64String(salt);
            var hashB64 = Convert.ToBase64String(hash);
            return Task.FromResult($"{saltB64}.{hashB64}");
        }

        /// <inheritdoc />
        public Task<bool> VerifyPasswordAsync(string password, string hashedPassword, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("التحقق من كلمة المرور");
            // Accept plain-text password if no salt is present (for seeded users)
            if (!hashedPassword.Contains('.'))
                return Task.FromResult(password == hashedPassword);
            try
            {
                var parts = hashedPassword.Split('.', 2);
                if (parts.Length != 2) return Task.FromResult(false);
                var salt = Convert.FromBase64String(parts[0]);
                var hash = Convert.FromBase64String(parts[1]);
                using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 100_000, HashAlgorithmName.SHA256);
                var computed = pbkdf2.GetBytes(hash.Length);
                if (CryptographicOperations.FixedTimeEquals(computed, hash))
                    return Task.FromResult(true);
                return Task.FromResult(false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء التحقق من كلمة المرور");
                return Task.FromResult(false);
            }
        }

        /// <inheritdoc />
        public Task<string> GenerateRandomPasswordAsync(int length = 12, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("توليد كلمة مرور عشوائية بالطول: {Length}", length);
            const string chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()";
            var data = new byte[length];
            RandomNumberGenerator.Fill(data);
            var result = new StringBuilder(length);
            foreach (var b in data)
            {
                result.Append(chars[b % chars.Length]);
            }
            return Task.FromResult(result.ToString());
        }

        /// <inheritdoc />
        public Task<(bool IsValid, string[] Issues)> ValidatePasswordStrengthAsync(string password, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("التحقق من قوة كلمة المرور");
            var issues = new List<string>();
            if (password.Length < 8) issues.Add("يجب أن تكون كلمة المرور 8 أحرف على الأقل");
            if (!password.Any(char.IsUpper)) issues.Add("يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل");
            if (!password.Any(char.IsLower)) issues.Add("يجب أن تحتوي كلمة المرور على حرف صغير واحد على الأقل");
            if (!password.Any(char.IsDigit)) issues.Add("يجب أن تحتوي كلمة المرور على رقم واحد على الأقل");
            if (!password.Any(ch => "!@#$%^&*()".Contains(ch))) issues.Add("يجب أن تحتوي كلمة المرور على رمز خاص واحد على الأقل");
            var isValid = !issues.Any();
            return Task.FromResult((isValid, issues.ToArray()));
        }
    }
}
