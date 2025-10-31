using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Users.Queries.GetAllRoles;

/// <summary>
/// استعلام للحصول على جميع الأدوار
/// </summary>
public class GetAllRolesQuery : IRequest<PaginatedResult<RoleDto>>
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}
