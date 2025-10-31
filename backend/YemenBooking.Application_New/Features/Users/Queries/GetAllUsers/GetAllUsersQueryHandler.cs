using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Features.Users;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Users.Queries.GetAllUsers
{
    /// <summary>
    /// معالج استعلام الحصول على جميع المستخدمين
    /// Query handler for GetAllUsersQuery
    /// </summary>
    public class GetAllUsersQueryHandler : IRequestHandler<GetAllUsersQuery, PaginatedResult<object>>
    {
        private readonly IUserRepository _userRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IUrlHelper _urlHelper;
        private readonly IMapper _mapper;
        private readonly ILogger<GetAllUsersQueryHandler> _logger;

        public GetAllUsersQueryHandler(
            IUserRepository userRepository,
            ICurrentUserService currentUserService,
            IUrlHelper urlHelper,
            IMapper mapper,
            ILogger<GetAllUsersQueryHandler> logger)
        {
            _userRepository = userRepository;
            _currentUserService = currentUserService;
            _urlHelper = urlHelper;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<PaginatedResult<object>> Handle(GetAllUsersQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام جميع المستخدمين - الصفحة: {PageNumber}, الحجم: {PageSize}", request.PageNumber, request.PageSize);

            // التحقق من صلاحية المسؤول فقط
            var roles = _currentUserService.UserRoles;
            if (!roles.Contains("Admin"))
            {
                throw new UnauthorizedAccessException("ليس لديك صلاحية لعرض قائمة المستخدمين");
            }

            // التحقق من صحة معاملات الصفحة
            var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
            var pageSize = request.PageSize < 1 ? 10 : request.PageSize;

            IQueryable<User> query = _userRepository
                .GetQueryable()
                .AsNoTracking()
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role);

            if (request.RoleId.HasValue)
            {
                query = query.Where(u => u.UserRoles.Any(ur => ur.RoleId == request.RoleId.Value));
            }
            else if (!string.IsNullOrWhiteSpace(request.RoleName))
            {
                var roleName = request.RoleName.Trim();
                query = query.Where(u => u.UserRoles.Any(ur => ur.Role != null && ur.Role.Name == roleName));
            }

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = request.SearchTerm.Trim().ToLower();
                query = query.Where(u =>
                    u.Name.ToLower().Contains(term)
                    || u.Email.ToLower().Contains(term)
                    || u.Phone.ToLower().Contains(term));
            }

            if (request.IsActive.HasValue)
            {
                query = query.Where(u => u.IsActive == request.IsActive.Value);
            }

            if (request.CreatedAfter.HasValue)
                query = query.Where(u => u.CreatedAt >= request.CreatedAfter.Value);

            if (request.CreatedBefore.HasValue)
                query = query.Where(u => u.CreatedAt <= request.CreatedBefore.Value);

            if (request.LastLoginAfter.HasValue)
                query = query.Where(u => u.LastLoginDate.HasValue && u.LastLoginDate.Value >= request.LastLoginAfter.Value);

            if (!string.IsNullOrWhiteSpace(request.LoyaltyTier))
                query = query.Where(u => u.LoyaltyTier == request.LoyaltyTier);

            if (request.MinTotalSpent.HasValue)
                query = query.Where(u => u.TotalSpent >= request.MinTotalSpent.Value);

            // تطبيق الترتيب
            query = (request.SortBy?.Trim().ToLower(), request.IsAscending) switch
            {
                ("name", true) => query.OrderBy(u => u.Name),
                ("name", false) => query.OrderByDescending(u => u.Name),
                ("email", true) => query.OrderBy(u => u.Email),
                ("email", false) => query.OrderByDescending(u => u.Email),
                ("createdat", true) => query.OrderBy(u => u.CreatedAt),
                ("createdat", false) => query.OrderByDescending(u => u.CreatedAt),
                _ => query.OrderBy(u => u.Name)
            };

            var totalCount = await query.CountAsync(cancellationToken);
            var users = await query
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            // تحويل التواريخ إلى التوقيت المحلي للمستخدم وتحويل الصور إلى absolute URLs
            var dtos = new List<object>();
            foreach (var user in users)
            {
                var dto = _mapper.Map<UserDto>(user);
                
                // تحويل LastSeen إلى التوقيت المحلي
                if (dto.LastSeen.HasValue)
                {
                    dto.LastSeen = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.LastSeen.Value);
                }
                
                // تحويل LastLoginDate إلى التوقيت المحلي
                if (dto.LastLoginDate.HasValue)
                {
                    dto.LastLoginDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.LastLoginDate.Value);
                }
                
                // تحويل ProfileImage إلى absolute URL
                if (!string.IsNullOrEmpty(dto.ProfileImage))
                {
                    dto.ProfileImage = _urlHelper.ToAbsoluteUrl(dto.ProfileImage);
                }
                
                dtos.Add(dto);
            }

            _logger.LogInformation("تم جلب {Count} مستخدم من إجمالي {TotalCount}", dtos.Count, totalCount);
            var result = new PaginatedResult<object>(dtos, pageNumber, pageSize, totalCount);
            if (pageNumber == 1)
            {
                var activeUsers = await query.CountAsync(u => u.IsActive, cancellationToken);
                var inactiveUsers = totalCount - activeUsers;
                var newUsersLast7Days = await query.CountAsync(u => u.CreatedAt >= DateTime.UtcNow.AddDays(-7), cancellationToken);
                result.Metadata = new
                {
                    totalUsers = totalCount,
                    activeUsers,
                    inactiveUsers,
                    newUsersLast7Days
                };
            }
            return result;
        }
    }
} 