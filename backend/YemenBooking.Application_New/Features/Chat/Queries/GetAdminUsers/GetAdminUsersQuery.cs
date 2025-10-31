using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.GetAdminUsers
{
    using System.Collections.Generic;
    using MediatR;
    using YemenBooking.Application.Common.Models;
    using YemenBooking.Application.Features.Users;

    /// <summary>
    /// استعلام لجلب حسابات الإدارة (ADMIN و SUPER_ADMIN)
    /// Query to get admin accounts (ADMIN and SUPER_ADMIN)
    /// </summary>
    public class GetAdminUsersQuery : IRequest<ResultDto<IEnumerable<ChatUserDto>>>
    {
    }
}
