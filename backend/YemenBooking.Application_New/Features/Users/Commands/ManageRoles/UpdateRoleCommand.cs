using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Users.Commands.ManageRoles;

/// <summary>
/// أمر لتحديث دور
/// </summary>
public class UpdateRoleCommand : IRequest<ResultDto<bool>>
{
    public Guid RoleId { get; set; }
    public string Name { get; set; } = string.Empty;
}
