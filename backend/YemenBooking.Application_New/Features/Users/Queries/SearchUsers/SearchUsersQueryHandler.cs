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
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Users.Queries.SearchUsers
{
    /// <summary>
    /// معالج استعلام البحث عن المستخدمين
    /// Query handler for SearchUsersQuery
    /// </summary>
    public class SearchUsersQueryHandler : IRequestHandler<SearchUsersQuery, PaginatedResult<UserDto>>
    {
        private readonly IUserRepository _userRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IUrlHelper _urlHelper;
        private readonly IMapper _mapper;
        private readonly ILogger<SearchUsersQueryHandler> _logger;

        public SearchUsersQueryHandler(
            IUserRepository userRepository,
            ICurrentUserService currentUserService,
            IUrlHelper urlHelper,
            IMapper mapper,
            ILogger<SearchUsersQueryHandler> logger)
        {
            _userRepository = userRepository;
            _currentUserService = currentUserService;
            _urlHelper = urlHelper;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<PaginatedResult<UserDto>> Handle(SearchUsersQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام البحث عن المستخدمين - مصطلح البحث: {SearchTerm}, الصفحة: {PageNumber}, الحجم: {PageSize}",
                request.SearchTerm, request.PageNumber, request.PageSize);

            if (string.IsNullOrWhiteSpace(request.SearchTerm))
                return PaginatedResult<UserDto>.Empty(request.PageNumber, request.PageSize);

            // صلاحيات المسؤول فقط
            if (!_currentUserService.UserRoles.Contains("Admin"))
                throw new UnauthorizedAccessException("ليس لديك صلاحية للبحث عن المستخدمين");

            var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
            var pageSize = request.PageSize < 1 ? 10 : request.PageSize;

            var term = request.SearchTerm.Trim().ToLower();
            var query = _userRepository.GetQueryable()
                .AsNoTracking()
                .Include(u => u.UserRoles).ThenInclude(ur => ur.Role)
                .Where(u => u.Name.ToLower().Contains(term) || u.Email.ToLower().Contains(term) || u.Phone.ToLower().Contains(term));

            if (request.RoleId.HasValue)
                query = query.Where(u => u.UserRoles.Any(ur => ur.RoleId == request.RoleId.Value));
            else if (!string.IsNullOrWhiteSpace(request.RoleName))
                query = query.Where(u => u.UserRoles.Any(ur => ur.Role != null && ur.Role.Name == request.RoleName));

            if (request.IsActive.HasValue)
                query = query.Where(u => u.IsActive == request.IsActive.Value);

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
            query = request.SortBy?.Trim().ToLower() switch
            {
                "registration_date" => query.OrderBy(u => u.CreatedAt),
                "last_login" => query.OrderBy(u => u.LastLoginDate),
                "total_spent" => query.OrderBy(u => u.TotalSpent),
                _ => query.OrderBy(u => u.Name)
            };

            var totalCount = await query.CountAsync(cancellationToken);
            var users = await query
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            // تحويل التواريخ إلى التوقيت المحلي للمستخدم وتحويل الصور إلى absolute URLs
            var dtos = new List<UserDto>();
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

            _logger.LogInformation("تم جلب {Count} مستخدم من إجمالي {TotalCount} بناءً على البحث", dtos.Count, totalCount);
            return new PaginatedResult<UserDto>(dtos, pageNumber, pageSize, totalCount);
        }
    }
} 