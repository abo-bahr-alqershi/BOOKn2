using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة الرسائل القصيرة SMS
    /// SMS service implementation
    /// </summary>
    public class SmsService : ISmsService
    {
        private readonly ILogger<SmsService> _logger;

        public SmsService(ILogger<SmsService> logger)
        {
            _logger = logger;
        }

        public Task<bool> SendSmsAsync(string phoneNumber, string message, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("إرسال SMS إلى: {PhoneNumber}, الرسالة: {Message}", phoneNumber, message);
            // TODO: دمج مع مزود SMS مثل Twilio أو Nexmo
            return Task.FromResult(true);
        }
    }
} 