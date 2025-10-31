using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.GetAvailableUsers
{
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using AutoMapper;
    using MediatR;
    using Microsoft.EntityFrameworkCore;
    using YemenBooking.Application.Features.Users;
    using YemenBooking.Application.Common.Models;
    using YemenBooking.Application.Features.Chat;
    using YemenBooking.Core.Interfaces.Repositories;
    using YemenBooking.Application.Infrastructure.Services;
    using System;

    /// <summary>
    /// معالج استعلام جلب قائمة المستخدمين المتاحين للمحادثة
    /// Handler for GetAvailableUsersQuery
    /// </summary>
    public class GetAvailableUsersQueryHandler : IRequestHandler<GetAvailableUsersQuery, ResultDto<IEnumerable<ChatUserDto>>>
    {
        private readonly IUserRepository _userRepo;
        private readonly IChatConversationRepository _chatRepo;
        private readonly ICurrentUserService _currentUser;
        private readonly IMapper _mapper;

        public GetAvailableUsersQueryHandler(IUserRepository userRepo, IChatConversationRepository chatRepo, IMapper mapper, ICurrentUserService currentUser)
        {
            _userRepo = userRepo;
            _chatRepo = chatRepo;
            _mapper = mapper;
            _currentUser = currentUser;
        }

        public async Task<ResultDto<IEnumerable<ChatUserDto>>> Handle(GetAvailableUsersQuery request, CancellationToken cancellationToken)
        {
            IQueryable<YemenBooking.Core.Entities.User> query = _userRepo.GetQueryable().AsNoTracking();
            query = query.Include(u => u.UserRoles).ThenInclude(ur => ur.Role);
            query = query.Include(u => u.Properties);
            
            // Role-based filtering for available contacts list
            var roles = (_currentUser.UserRoles ?? Enumerable.Empty<string>()).Select(r => (r ?? string.Empty).ToLowerInvariant()).ToList();
            var accountRole = (_currentUser.AccountRole ?? string.Empty).ToLowerInvariant();
            var isAdmin = roles.Contains("admin") || roles.Contains("super_admin") || accountRole == "admin";
            var isOwner = roles.Contains("owner") || roles.Contains("hotel_owner") || accountRole == "owner";
            var isStaff = roles.Contains("staff") || roles.Contains("hotel_manager") || roles.Contains("receptionist") || accountRole == "staff";
            var isClient = roles.Contains("client") || roles.Contains("customer") || accountRole == "client";

            if (isAdmin)
            {
                // Admin: قائمة كاملة بجميع المستخدمين (يمكن تضييقها بالـ request.UserType إن وُجد)
                if (!string.IsNullOrEmpty(request.UserType))
                    query = query.Where(u => u.UserRoles.Any(ur => ur.Role != null && ur.Role.Name.ToLower() == request.UserType.ToLower()));
            }
            else if (isOwner || isStaff)
            {
                // Owner/Staff: حساب مراسلة واحد (العقار). يمكنهم رؤية:
                // - حسابات الأدمن
                // - العملاء الذين سبق أن راسلوا هذا العقار
                var propertyId = _currentUser.PropertyId;
                if (propertyId.HasValue)
                {
                    var pid = propertyId.Value;
                    var propertyParticipantIds = _chatRepo.GetQueryable()
                        .Where(c => c.PropertyId.HasValue && c.PropertyId.Value == pid)
                        .SelectMany(c => c.Participants.Select(p => p.Id));
                    query = query.Where(u =>
                        u.UserRoles.Any(ur => ur.Role != null && (ur.Role.Name.ToLower() == "admin" || ur.Role.Name.ToLower() == "super_admin"))
                        || propertyParticipantIds.Contains(u.Id));
                }
                else
                {
                    // إن لم يوجد PropertyId، فلا جهات اتصال
                    query = query.Where(u => false);
                }
            }
            else if (isClient)
            {
                // Client: يمكنه مراسلة الأدمن والعقارات التي سبق مراسلتها فقط حتى تظهر في القائمة
                // لإضافة عقار جديد، يبدأ محادثة عبر شاشة العقار وليس من قائمة جهات الاتصال
                var currentUserId = _currentUser.UserId;
                var chattedPropertyParticipantIds = _chatRepo.GetQueryable()
                    .Where(c => c.PropertyId.HasValue && c.Participants.Any(p => p.Id == currentUserId))
                    .SelectMany(c => c.Participants.Select(p => p.Id));
                query = query.Where(u =>
                    u.UserRoles.Any(ur => ur.Role != null && (ur.Role.Name.ToLower() == "admin" || ur.Role.Name.ToLower() == "super_admin"))
                    || chattedPropertyParticipantIds.Contains(u.Id));
            }
            else
            {
                // أدوار أخرى: لا شيء
                query = query.Where(u => false);
            }

            var users = await query.ToListAsync(cancellationToken);
            var dtos = _mapper.Map<IEnumerable<ChatUserDto>>(users).ToList();
            for (int i = 0; i < dtos.Count; i++)
            {
                if (dtos[i].LastSeen.HasValue)
                    dtos[i].LastSeen = await _currentUser.ConvertFromUtcToUserLocalAsync(dtos[i].LastSeen.Value);
            }

            return ResultDto<IEnumerable<ChatUserDto>>.Ok(dtos);
        }
    }
} 