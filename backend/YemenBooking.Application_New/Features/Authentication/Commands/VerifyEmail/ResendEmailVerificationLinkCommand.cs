using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Authentication.Commands.VerifyEmail
{
    /// <summary>
    /// أمر لإعادة إرسال رابط التحقق للبريد الإلكتروني لتفعيل الحساب
    /// Command to resend email verification link for account activation
    /// </summary>
    public class ResendEmailVerificationLinkCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// البريد الإلكتروني للمستخدم
        /// User's email
        /// </summary>
        public string Email { get; set; } = string.Empty;
    }
} 