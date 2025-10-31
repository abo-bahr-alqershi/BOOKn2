using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Authentication.Commands.PasswordReset;

/// <summary>
/// أمر لطلب إعادة تعيين كلمة المرور
/// Command to request password reset
/// </summary>
public class ForgotPasswordCommand : IRequest<ResultDto<bool>>
{
    public string Email { get; set; } = string.Empty;
}
