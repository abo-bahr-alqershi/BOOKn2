using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reports;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Reports.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reports.Queries.GetReportsByReportedUser
{
    /// <summary>
    /// معالج استعلام الحصول على البلاغات المقدمة ضد مستخدم معين
    /// Handles GetReportsByReportedUserQuery and returns paginated reports for a user
    /// </summary>
    public class GetReportsByReportedUserQueryHandler : IRequestHandler<GetReportsByReportedUserQuery, PaginatedResult<ReportDto>>
    {
        private readonly IReportRepository _reportRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetReportsByReportedUserQueryHandler> _logger;

        public GetReportsByReportedUserQueryHandler(
            IReportRepository reportRepository,
            ICurrentUserService currentUserService,
            ILogger<GetReportsByReportedUserQueryHandler> logger)
        {
            _reportRepository = reportRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<PaginatedResult<ReportDto>> Handle(GetReportsByReportedUserQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب البلاغات ضد المستخدم: {UserId}, Page={Page}, Size={Size}", request.UserId, request.PageNumber, request.PageSize);

            if (request.UserId == Guid.Empty)
                throw new BusinessRuleException("InvalidUserId", "معرف المستخدم غير صالح");

            if (request.PageNumber <= 0 || request.PageSize <= 0)
                throw new BusinessRuleException("InvalidPagination", "رقم الصفحة وحجم الصفحة يجب أن يكونا أكبر من صفر");

            var currentUserId = _currentUserService.UserId;
            var role = _currentUserService.Role;
            if (role != "Admin" && currentUserId != request.UserId)
            {
                _logger.LogWarning("ليس لدى المستخدم صلاحية الوصول إلى البلاغات المقدمة ضد هذا المستخدم");
                throw new ForbiddenException("ليس لديك صلاحية الوصول إلى هذه البلاغات");
            }

            var allReports = await _reportRepository.GetReportsAsync(null, request.UserId, null, cancellationToken);
            var totalCount = allReports.Count();
            var items = allReports
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .Select(r => new ReportDto
                {
                    Id = r.Id,
                    ReporterUserId = r.ReporterUserId,
                    ReporterUserName = r.ReporterUser.Name,
                    ReportedUserId = r.ReportedUserId,
                    ReportedUserName = r.ReportedUser != null ? r.ReportedUser.Name : null,
                    ReportedPropertyId = r.ReportedPropertyId,
                    ReportedPropertyName = r.ReportedProperty != null ? r.ReportedProperty.Name : null,
                    Reason = r.Reason,
                    Description = r.Description,
                    CreatedAt = r.CreatedAt
                })
                .ToList();

            // Localize CreatedAt for client
            for (int i = 0; i < items.Count; i++)
            {
                items[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(items[i].CreatedAt);
            }

            return PaginatedResult<ReportDto>.Create(items, request.PageNumber, request.PageSize, totalCount);
        }
    }
} 