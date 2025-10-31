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

namespace YemenBooking.Application.Features.Reports.Queries.GetAllReports
{
    /// <summary>
    /// معالج استعلام الحصول على جميع البلاغات مع الترميز
    /// Handles GetAllReportsQuery and returns paginated reports
    /// </summary>
    public class GetAllReportsQueryHandler : IRequestHandler<GetAllReportsQuery, PaginatedResult<ReportDto>>
    {
        private readonly IReportRepository _reportRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetAllReportsQueryHandler> _logger;

        public GetAllReportsQueryHandler(
            IReportRepository reportRepository,
            ICurrentUserService currentUserService,
            ILogger<GetAllReportsQueryHandler> logger)
        {
            _reportRepository = reportRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<PaginatedResult<ReportDto>> Handle(GetAllReportsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء معالجة استعلام GetAllReports: {@Request}", request);

            if (request.PageNumber <= 0 || request.PageSize <= 0)
                throw new BusinessRuleException("InvalidPagination", "رقم الصفحة وحجم الصفحة يجب أن يكونا أكبر من صفر");

            // جلب البيانات مع الفلاتر الأساسية
            var allReports = await _reportRepository.GetReportsAsync(
                request.ReporterUserId,
                request.ReportedUserId,
                request.ReportedPropertyId,
                cancellationToken);

            // تطبيق الفلاتر الإضافية
            var filtered = allReports.AsQueryable();
            // فلترة نص البحث إذا تم توفير SearchTerm
            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var search = request.SearchTerm.ToLower();
                filtered = filtered.Where(r => r.Reason.ToLower().Contains(search)
                    || (r.Description != null && r.Description.ToLower().Contains(search)));
            }
            if (!string.IsNullOrWhiteSpace(request.Reason))
                filtered = filtered.Where(r => r.Reason.Contains(request.Reason) || (r.Description != null && r.Description.Contains(request.Reason)));
            if (!string.IsNullOrWhiteSpace(request.Status))
                filtered = filtered.Where(r => r.Status.Equals(request.Status, StringComparison.OrdinalIgnoreCase));
            // Normalize incoming date filters (user-local -> UTC)
            if (request.FromDate.HasValue)
                request.FromDate = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.FromDate.Value);
            if (request.ToDate.HasValue)
                request.ToDate = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.ToDate.Value);
            if (request.FromDate.HasValue)
                filtered = filtered.Where(r => r.CreatedAt >= request.FromDate.Value);
            if (request.ToDate.HasValue)
                filtered = filtered.Where(r => r.CreatedAt <= request.ToDate.Value);

            var totalCount = filtered.Count();
            var items = filtered
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