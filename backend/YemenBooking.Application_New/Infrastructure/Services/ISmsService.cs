namespace YemenBooking.Application.Infrastructure.Services
{
    /// <summary>
    /// واجهة خدمة الرسائل القصيرة
    /// SMS service interface
    /// </summary>
    public interface ISmsService
    {
        /// <summary>
        /// إرسال رسالة SMS
        /// Send an SMS message
        /// </summary>
        Task<bool> SendSmsAsync(string phoneNumber, string message, CancellationToken cancellationToken = default);
    }
} 