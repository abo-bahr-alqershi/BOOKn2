using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Users.Commands.ManageRoles;

/// <summary>
/// أمر لتخصيص دور للمستخدم
/// Command to assign a role to a user
/// </summary>
public class AssignUserRoleCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// معرف الدور
    /// Role ID
    /// </summary>
    public Guid RoleId { get; set; }
} 