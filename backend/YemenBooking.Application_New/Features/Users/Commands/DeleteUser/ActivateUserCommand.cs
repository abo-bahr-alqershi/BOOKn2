using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Users.Commands.DeleteUser;

/// <summary>
/// أمر لتفعيل الحساب بعد التحقق من البريد الإلكتروني
/// Command to activate user after email verification
/// </summary>
public class ActivateUserCommand : IRequest<ResultDto<bool>>
{
    public Guid UserId { get; set; }
}
