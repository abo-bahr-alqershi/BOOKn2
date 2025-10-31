using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Users.Commands.ManageRoles;

/// <summary>
/// أمر لحذف دور
/// </summary>
public class DeleteRoleCommand : IRequest<ResultDto<bool>>
{
    public Guid RoleId { get; set; }
}
