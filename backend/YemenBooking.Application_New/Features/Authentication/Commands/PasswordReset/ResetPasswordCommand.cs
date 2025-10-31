using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Authentication.Commands.PasswordReset;

/// <summary>
/// أمر لإعادة تعيين كلمة المرور باستخدام رمز
/// Command to reset password using token
/// </summary>
public class ResetPasswordCommand : IRequest<ResultDto<bool>>
{
    public string Token { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}
