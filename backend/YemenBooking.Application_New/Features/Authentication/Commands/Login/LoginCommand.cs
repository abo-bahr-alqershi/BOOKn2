using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication.DTOs;

namespace YemenBooking.Application.Features.Authentication.Commands.Login;

/// <summary>
/// أمر لتسجيل الدخول والحصول على التوكنات
/// Command for user login and token issuance
/// </summary>
public class LoginCommand : IRequest<ResultDto<AuthResultDto>>
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public bool RememberMe { get; set; } = false;
}
