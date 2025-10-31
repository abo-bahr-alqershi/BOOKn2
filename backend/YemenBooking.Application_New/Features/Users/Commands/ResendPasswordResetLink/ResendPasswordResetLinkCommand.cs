using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Users.Commands.ResendPasswordResetLink
{
    /// <summary>
    /// أمر لإعادة إرسال رابط إعادة تعيين كلمة المرور
    /// Command to resend password reset link for user
    /// </summary>
    public class ResendPasswordResetLinkCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// البريد الإلكتروني للمستخدم
        /// User's email
        /// </summary>
        public string Email { get; set; } = string.Empty;
    }
} 