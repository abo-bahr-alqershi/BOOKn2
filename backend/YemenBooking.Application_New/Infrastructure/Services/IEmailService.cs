namespace YemenBooking.Application.Infrastructure.Services;

/// <summary>
/// واجهة خدمة البريد الإلكتروني
/// Email service interface
/// </summary>
public interface IEmailService
{
    /// <summary>
    /// إرسال بريد ترحيبي
    /// Send welcome email
    /// </summary>
    Task<bool> SendWelcomeEmailAsync(
        string email, 
        string userName, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إرسال بريد إلكتروني
    /// Send email
    /// </summary>
    Task<bool> SendEmailAsync(
        string to, 
        string subject, 
        string body, 
        bool isHtml = true, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إرسال بريد تأكيد الحجز
    /// Send booking confirmation email
    /// </summary>
    Task<bool> SendBookingConfirmationEmailAsync(
        string email,
        string customerName,
        object bookingDetails,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إرسال بريد إلغاء الحجز
    /// Send booking cancellation email
    /// </summary>
    Task<bool> SendBookingCancellationEmailAsync(
        string email,
        string customerName,
        object bookingDetails,
        string reason,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إرسال بريد إعادة تعيين كلمة المرور
    /// Send password reset email
    /// </summary>
    Task<bool> SendPasswordResetEmailAsync(
        string email,
        string userName,
        string resetToken,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إرسال بريد إشعار للمالك
    /// Send owner notification email
    /// </summary>
    Task<bool> SendOwnerNotificationEmailAsync(
        string email,
        string ownerName,
        string subject,
        string message,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// إرسال تقرير بالبريد الإلكتروني
    /// Send report via email
    /// </summary>
    Task<bool> SendReportEmailAsync(
        string email,
        string reportName,
        byte[] reportData,
        string fileName,
        CancellationToken cancellationToken = default);
}
