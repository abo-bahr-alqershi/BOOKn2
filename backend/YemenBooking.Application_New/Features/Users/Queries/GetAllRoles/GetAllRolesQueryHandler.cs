using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Users.Queries.GetAllRoles
{
    /// <summary>
    /// معالج استعلام الحصول على جميع الأدوار مع الترميز
    /// Handles GetAllRolesQuery and returns paginated roles
    /// </summary>
    public class GetAllRolesQueryHandler : IRequestHandler<GetAllRolesQuery, PaginatedResult<RoleDto>>
    {
        private readonly IRoleRepository _roleRepository;
        private readonly ILogger<GetAllRolesQueryHandler> _logger;

        public GetAllRolesQueryHandler(
            IRoleRepository roleRepository,
            ILogger<GetAllRolesQueryHandler> logger)
        {
            _roleRepository = roleRepository;
            _logger = logger;
        }

        public async Task<PaginatedResult<RoleDto>> Handle(GetAllRolesQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء معالجة استعلام GetAllRoles: Page={Page}, Size={Size}", request.PageNumber, request.PageSize);

            if (request.PageNumber <= 0 || request.PageSize <= 0)
                throw new BusinessRuleException("InvalidPagination", "رقم الصفحة وحجم الصفحة يجب أن يكونا أكبر من صفر");

            var allRoles = await _roleRepository.GetAllAsync(cancellationToken);
            var totalCount = allRoles.Count();
            var items = allRoles
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .Select(r => new RoleDto
                {
                    Id = r.Id,
                    Name = r.Name
                })
                .ToList();

            return PaginatedResult<RoleDto>.Create(items, request.PageNumber, request.PageSize, totalCount);
        }
    }
} 