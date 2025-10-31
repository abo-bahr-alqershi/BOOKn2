using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Users.Commands.ManageRoles;

/// <summary>
/// أمر لإنشاء دور جديد
/// </summary>
public class CreateRoleCommand : IRequest<ResultDto<Guid>>
{
    public string Name { get; set; } = string.Empty;
}
