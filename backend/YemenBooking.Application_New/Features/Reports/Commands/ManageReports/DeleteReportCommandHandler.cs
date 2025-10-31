using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Reports;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using System.Collections.Generic;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Reports.Commands.ManageReports
{
    /// <summary>
    /// معالج أمر حذف بلاغ
    /// </summary>
    public class DeleteReportCommandHandler : IRequestHandler<DeleteReportCommand, ResultDto<bool>>
    {
        private readonly IReportRepository _reportRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<DeleteReportCommandHandler> _logger;

        public DeleteReportCommandHandler(
            IReportRepository reportRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<DeleteReportCommandHandler> logger)
        {
            _reportRepository = reportRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(DeleteReportCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء حذف البلاغ: Id={ReportId}", request.Id);

            // التحقق من المدخلات
            if (request.Id == Guid.Empty)
                return ResultDto<bool>.Failed("معرف البلاغ مطلوب");

            // التحقق من الوجود
            var report = await _reportRepository.GetReportByIdAsync(request.Id, cancellationToken);
            if (report == null)
                return ResultDto<bool>.Failed("البلاغ غير موجود");

            // التحقق من الصلاحيات
            if (_currentUserService.Role != "Admin" && report.ReporterUserId != _currentUserService.UserId)
                return ResultDto<bool>.Failed("غير مصرح لك بحذف هذا البلاغ");

            // تنفيذ الحذف
            bool deleted = await _reportRepository.DeleteReportAsync(request.Id, cancellationToken);
            if (!deleted)
                return ResultDto<bool>.Failed("فشل حذف البلاغ");

            // تسجيل التدقيق (يدوي) يتضمن اسم ومعرّف المنفذ
            var notes = $"تم حذف البلاغ {request.Id} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "Report",
                entityId: request.Id,
                action: YemenBooking.Core.Entities.AuditAction.DELETE,
                oldValues: System.Text.Json.JsonSerializer.Serialize(new { request.Id, request.DeletionReason }),
                newValues: null,
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل حذف البلاغ بنجاح: Id={ReportId}", request.Id);
            return ResultDto<bool>.Succeeded(true, "تم حذف البلاغ بنجاح");
        }
    }
} 