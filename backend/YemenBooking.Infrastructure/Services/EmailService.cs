using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using System.Net.Mail;
using System.Net;
using System.Text.Json;
using Microsoft.Extensions.Options;
using YemenBooking.Infrastructure.Settings;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة البريد الإلكتروني
    /// Email service implementation
    /// </summary>
    public class EmailService : IEmailService
    {
        private readonly ILogger<EmailService> _logger;
        private readonly EmailSettings _settings;

        public EmailService(ILogger<EmailService> logger, IOptions<EmailSettings> options)
        {
            _logger = logger;
            _settings = options.Value;
        }

        /// <inheritdoc />
        public async Task<bool> SendEmailAsync(string to, string subject, string body, bool isHtml = true, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("إرسال بريد إلى: {To}، الموضوع: {Subject}", to, subject);
            try
            {
                using var mail = new MailMessage
                {
                    From = new MailAddress(string.IsNullOrWhiteSpace(_settings.FromEmail) ? "noreply@example.com" : _settings.FromEmail, string.IsNullOrWhiteSpace(_settings.FromName) ? "YemenBooking" : _settings.FromName),
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = isHtml
                };
                mail.To.Add(to);
                using var client = new SmtpClient();
                if (_settings.UsePickupDirectory)
                {
                    var pickupPath = string.IsNullOrWhiteSpace(_settings.PickupDirectoryLocation) ? "Emails" : _settings.PickupDirectoryLocation;
                    Directory.CreateDirectory(pickupPath);
                    client.DeliveryMethod = SmtpDeliveryMethod.SpecifiedPickupDirectory;
                    client.PickupDirectoryLocation = pickupPath;
                }
                else
                {
                    client.Host = _settings.SmtpHost;
                    client.Port = _settings.SmtpPort;
                    client.EnableSsl = _settings.EnableSsl;
                    if (!string.IsNullOrWhiteSpace(_settings.Username))
                    {
                        client.Credentials = new NetworkCredential(_settings.Username, _settings.Password);
                    }
                }
                await client.SendMailAsync(mail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء إرسال البريد");
                return false;
            }
        }

        /// <inheritdoc />
        public Task<bool> SendWelcomeEmailAsync(string email, string userName, CancellationToken cancellationToken = default)
        {
            var subject = "مرحباً بك في YemenBooking";
            var body = $"<p>مرحباً {userName},</p><p>شكراً لانضمامك إلينا!</p>";
            return SendEmailAsync(email, subject, body, true, cancellationToken);
        }

        /// <inheritdoc />
        public Task<bool> SendBookingConfirmationEmailAsync(string email, string customerName, object bookingDetails, CancellationToken cancellationToken = default)
        {
            var subject = "تأكيد الحجز";
            var details = JsonSerializer.Serialize(bookingDetails, new JsonSerializerOptions { WriteIndented = true });
            var body = $"<p>عزيزي {customerName},</p><p>تم تأكيد حجزك بنجاح:</p><pre>{details}</pre>";
            return SendEmailAsync(email, subject, body, true, cancellationToken);
        }

        /// <inheritdoc />
        public Task<bool> SendBookingCancellationEmailAsync(string email, string customerName, object bookingDetails, string reason, CancellationToken cancellationToken = default)
        {
            var subject = "إلغاء الحجز";
            var details = JsonSerializer.Serialize(bookingDetails, new JsonSerializerOptions { WriteIndented = true });
            var body = $"<p>عزيزي {customerName},</p><p>تم إلغاء حجزك:</p><pre>{details}</pre><p>السبب: {reason}</p>";
            return SendEmailAsync(email, subject, body, true, cancellationToken);
        }

        /// <inheritdoc />
        public Task<bool> SendPasswordResetEmailAsync(string email, string userName, string resetToken, CancellationToken cancellationToken = default)
        {
            var subject = "إعادة تعيين كلمة المرور";
            var body = $"<p>مرحباً {userName},</p><p>رمز إعادة التعيين الخاص بك هو: <strong>{resetToken}</strong></p>";
            return SendEmailAsync(email, subject, body, true, cancellationToken);
        }

        /// <inheritdoc />
        public Task<bool> SendOwnerNotificationEmailAsync(string email, string ownerName, string subject, string message, CancellationToken cancellationToken = default)
        {
            var body = $"<p>مرحباً {ownerName},</p><p>{message}</p>";
            return SendEmailAsync(email, subject, body, true, cancellationToken);
        }

        /// <inheritdoc />
        public async Task<bool> SendReportEmailAsync(string email, string reportName, byte[] reportData, string fileName, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("إرسال تقرير عبر البريد إلى: {Email} للتقرير: {ReportName}", email, reportName);
            try
            {
                using var mail = new MailMessage
                {
                    From = new MailAddress(_settings.FromEmail, _settings.FromName),
                    Subject = $"تقرير: {reportName}",
                    Body = "<p>يرجى الاطلاع على التقرير المرفق.</p>",
                    IsBodyHtml = true
                };
                mail.To.Add(email);
                mail.Attachments.Add(new Attachment(new MemoryStream(reportData), fileName));
                using var client = new SmtpClient(_settings.SmtpHost, _settings.SmtpPort)
                {
                    EnableSsl = _settings.EnableSsl,
                    Credentials = new NetworkCredential(_settings.Username, _settings.Password)
                };
                await client.SendMailAsync(mail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء إرسال التقرير عبر البريد");
                return false;
            }
        }
    }
}
