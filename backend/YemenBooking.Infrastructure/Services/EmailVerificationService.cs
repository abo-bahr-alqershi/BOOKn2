using System;
using System.Collections.Concurrent;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// خدمة التحقق من البريد الإلكتروني
    /// Stub implementation of IEmailVerificationService
    /// </summary>
    public class EmailVerificationService : IEmailVerificationService
    {
        private static readonly ConcurrentDictionary<string, (string Code, DateTime ExpiresAt)> _codes = new();
        private static readonly ConcurrentDictionary<string, (int Count, DateTime WindowStart)> _rateLimit = new();
        private readonly IEmailService _emailService;
        private readonly ILogger<EmailVerificationService> _logger;

        public EmailVerificationService(IEmailService emailService, ILogger<EmailVerificationService> logger)
        {
            _emailService = emailService;
            _logger = logger;
        }

        public async Task<bool> SendVerificationEmailAsync(string email, string verificationCode)
        {
            var subject = "تأكيد البريد الإلكتروني";
            var body = $"<p>رمز التحقق الخاص بك هو: <strong>{verificationCode}</strong></p><p>صالح لمدة 10 دقائق.</p>";
            var sent = await _emailService.SendEmailAsync(email, subject, body, true);
            if (sent)
            {
                _codes[email.ToLowerInvariant()] = (verificationCode, DateTime.UtcNow.AddMinutes(10));
            }
            return sent;
        }

        public Task<bool> VerifyCodeAsync(string email, string verificationCode)
        {
            var key = email.ToLowerInvariant();
            if (_codes.TryGetValue(key, out var entry))
            {
                if (DateTime.UtcNow <= entry.ExpiresAt && string.Equals(entry.Code, verificationCode, StringComparison.OrdinalIgnoreCase))
                {
                    _codes.TryRemove(key, out _);
                    return Task.FromResult(true);
                }
            }
            return Task.FromResult(false);
        }

        public string GenerateVerificationCode()
        {
            var rng = new Random();
            return rng.Next(100000, 999999).ToString();
        }

        public Task<bool> IsCodeExpiredAsync(string email, string verificationCode)
        {
            var key = email.ToLowerInvariant();
            if (_codes.TryGetValue(key, out var entry))
            {
                // Only consider time expiry here; token mismatch should be handled by VerifyCodeAsync
                return Task.FromResult(DateTime.UtcNow > entry.ExpiresAt);
            }
            // No code stored => treat as expired
            return Task.FromResult(true);
        }

        public Task<bool> DeleteVerificationCodeAsync(string email, string verificationCode)
        {
            var key = email.ToLowerInvariant();
            var removed = _codes.TryRemove(key, out _);
            return Task.FromResult(removed);
        }

        public Task<bool> RecordSendAttemptAsync(string email, CancellationToken cancellationToken = default)
        {
            var now = DateTime.UtcNow;
            var key = email.ToLowerInvariant();
            var entry = _rateLimit.GetOrAdd(key, _ => (0, now));
            if ((now - entry.WindowStart) > TimeSpan.FromMinutes(1))
            {
                entry = (0, now);
            }
            entry = (entry.Count + 1, entry.WindowStart);
            _rateLimit[key] = entry;
            // Example: allow up to 5 sends per minute per email
            var allowed = entry.Count <= 5;
            if (!allowed)
            {
                _logger.LogWarning("تم تجاوز معدل الإرسال للبريد: {Email}", email);
            }
            return Task.FromResult(allowed);
        }
    }
}