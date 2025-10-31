using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Users.Commands.DeleteUser;

/// <summary>
/// أمر لإلغاء تفعيل حساب المستخدم
/// Command to deactivate a user account
/// </summary>
public class DeactivateUserCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }
} 