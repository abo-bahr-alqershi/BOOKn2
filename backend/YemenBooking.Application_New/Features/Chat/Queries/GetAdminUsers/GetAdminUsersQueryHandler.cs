using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.GetAdminUsers
{
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using AutoMapper;
    using MediatR;
    using Microsoft.EntityFrameworkCore;
    using YemenBooking.Application.Common.Models;
    using YemenBooking.Application.Features.Users;
    using YemenBooking.Application.Features.Chat;
    using YemenBooking.Core.Interfaces.Repositories;

    /// <summary>
    /// معالج استعلام جلب حسابات الإدارة فقط
    /// Fetch only users having ADMIN or SUPER_ADMIN roles
    /// </summary>
    public class GetAdminUsersQueryHandler : IRequestHandler<GetAdminUsersQuery, ResultDto<IEnumerable<ChatUserDto>>>
    {
        private readonly IUserRepository _userRepository;
        private readonly IMapper _mapper;

        public GetAdminUsersQueryHandler(IUserRepository userRepository, IMapper mapper)
        {
            _userRepository = userRepository;
            _mapper = mapper;
        }

        public async Task<ResultDto<IEnumerable<ChatUserDto>>> Handle(GetAdminUsersQuery request, CancellationToken cancellationToken)
        {
            var query = _userRepository.GetQueryable()
                .AsNoTracking()
                .Include(u => u.UserRoles).ThenInclude(ur => ur.Role)
                .Where(u => u.UserRoles.Any(ur => ur.Role.Name.ToLower() == "admin" || ur.Role.Name.ToLower() == "super_admin"));

            var users = await query.ToListAsync(cancellationToken);
            var dtos = _mapper.Map<IEnumerable<ChatUserDto>>(users);
            return ResultDto<IEnumerable<ChatUserDto>>.Ok(dtos);
        }
    }
}
