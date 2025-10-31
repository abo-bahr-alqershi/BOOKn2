using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Application.Features.Authentication.DTOs;

namespace YemenBooking.Application.Features.Authentication.Commands.PasswordReset
{
    /// <summary>
    /// أمر طلب إعادة تعيين كلمة المرور
    /// Command to request password reset
    /// </summary>
    public class RequestPasswordResetCommand : IRequest<ResultDto<RequestPasswordResetResponse>>
    {
        /// <summary>
        /// البريد الإلكتروني أو رقم الهاتف
        /// </summary>
        [Required(ErrorMessage = "البريد الإلكتروني أو رقم الهاتف مطلوب")]
        public string EmailOrPhone { get; set; } = string.Empty;
    }
}