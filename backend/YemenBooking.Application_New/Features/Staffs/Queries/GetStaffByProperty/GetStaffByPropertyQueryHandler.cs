using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Staffs;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Staffs.DTOs;

namespace YemenBooking.Application.Features.Staffs.Queries.GetStaffByProperty
{
    /// <summary>
    /// معالج استعلام الحصول على موظفي الكيان
    /// Handles GetStaffByPropertyQuery and returns paginated staff for a property
    /// </summary>
    public class GetStaffByPropertyQueryHandler : IRequestHandler<GetStaffByPropertyQuery, PaginatedResult<StaffDto>>
    {
        private readonly IStaffRepository _staffRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetStaffByPropertyQueryHandler> _logger;

        public GetStaffByPropertyQueryHandler(
            IStaffRepository staffRepository,
            ICurrentUserService currentUserService,
            ILogger<GetStaffByPropertyQueryHandler> logger)
        {
            _staffRepository = staffRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<PaginatedResult<StaffDto>> Handle(GetStaffByPropertyQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب موظفي الكيان: {PropertyId}, Page={Page}, Size={Size}", request.PropertyId, request.PageNumber, request.PageSize);

            if (request.PropertyId == Guid.Empty)
                throw new ValidationException(nameof(request.PropertyId), "معرف الكيان غير صالح");

            if (request.PageNumber <= 0 || request.PageSize <= 0)
                throw new BusinessRuleException("InvalidPagination", "رقم الصفحة وحجم الصفحة يجب أن يكونا أكبر من صفر");

            if (_currentUserService.Role != "Admin" && _currentUserService.PropertyId != request.PropertyId)
            {
                _logger.LogWarning("ليس لدى المستخدم صلاحية الوصول إلى موظفي هذا الكيان");
                throw new ForbiddenException("ليس لديك صلاحية الوصول إلى موظفي هذا الكيان");
            }

            var allStaff = await _staffRepository.GetStaffByPropertyAsync(request.PropertyId, cancellationToken);
            var totalCount = allStaff.Count();
            var items = allStaff
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .Select(s => new StaffDto
                {
                    Id = s.Id,
                    UserId = s.UserId,
                    UserName = string.Empty,
                    PropertyId = s.PropertyId,
                    PropertyName = string.Empty,
                    Position = s.Position,
                    Permissions = s.Permissions
                })
                .ToList();

            return PaginatedResult<StaffDto>.Create(items, request.PageNumber, request.PageSize, totalCount);
        }
    }
} 