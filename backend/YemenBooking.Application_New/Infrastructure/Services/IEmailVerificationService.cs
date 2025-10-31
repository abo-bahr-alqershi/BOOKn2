using System;
using System.Threading.Tasks;

namespace YemenBooking.Application.Infrastructure.Services
{
    /// <summary>
    /// واجهة خدمة التحقق من البريد الإلكتروني
    /// Email verification service interface
    /// </summary>
    public interface IEmailVerificationService
    {
        /// <summary>
        /// إرسال رمز التحقق عبر البريد الإلكتروني
        /// Send verification code via email
        /// </summary>
        /// <param name="email">البريد الإلكتروني</param>
        /// <param name="verificationCode">رمز التحقق</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> SendVerificationEmailAsync(string email, string verificationCode);

        /// <summary>
        /// التحقق من صحة رمز التحقق
        /// Verify the verification code
        /// </summary>
        /// <param name="email">البريد الإلكتروني</param>
        /// <param name="verificationCode">رمز التحقق</param>
        /// <returns>نتيجة التحقق</returns>
        Task<bool> VerifyCodeAsync(string email, string verificationCode);

        /// <summary>
        /// إنشاء رمز تحقق جديد
        /// Generate new verification code
        /// </summary>
        /// <returns>رمز التحقق</returns>
        string GenerateVerificationCode();

        /// <summary>
        /// التحقق من انتهاء صلاحية رمز التحقق
        /// Check if verification code is expired
        /// </summary>
        /// <param name="email">البريد الإلكتروني</param>
        /// <param name="verificationCode">رمز التحقق</param>
        /// <returns>true إذا كان منتهي الصلاحية</returns>
        Task<bool> IsCodeExpiredAsync(string email, string verificationCode);

        /// <summary>
        /// حذف رمز التحقق بعد الاستخدام
        /// Delete verification code after use
        /// </summary>
        /// <param name="email">البريد الإلكتروني</param>
        /// <param name="verificationCode">رمز التحقق</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> DeleteVerificationCodeAsync(string email, string verificationCode);

        /// <summary>
        /// تسجيل محاولة إرسال أخرى لفرض قيود معدل الإرسال
        /// Record another send attempt to enforce rate limiting
        /// </summary>
        Task<bool> RecordSendAttemptAsync(string email, CancellationToken cancellationToken = default);
    }
}
