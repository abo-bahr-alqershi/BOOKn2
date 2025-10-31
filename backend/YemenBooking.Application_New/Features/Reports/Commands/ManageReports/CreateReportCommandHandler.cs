using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Reports.Commands.ManageReports
{
    /// <summary>
    /// معالج أمر إنشاء بلاغ جديد
    /// </summary>
    public class CreateReportCommandHandler : IRequestHandler<CreateReportCommand, ResultDto<Guid>>
    {
        private readonly IReportRepository _reportRepository;
        private readonly IUserRepository _userRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<CreateReportCommandHandler> _logger;

        public CreateReportCommandHandler(
            IReportRepository reportRepository,
            IUserRepository userRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<CreateReportCommandHandler> logger)
        {
            _reportRepository = reportRepository;
            _userRepository = userRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<Guid>> Handle(CreateReportCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء إنشاء بلاغ: Reporter={Reporter}, ReportedUser={ReportedUser}, ReportedProperty={ReportedProperty}",
                request.ReporterUserId, request.ReportedUserId, request.ReportedPropertyId);

            // التحقق من المدخلات
            if (request.ReporterUserId == Guid.Empty)
                return ResultDto<Guid>.Failed("معرف المبلغ مطلوب");
            if (string.IsNullOrWhiteSpace(request.Reason))
                return ResultDto<Guid>.Failed("سبب البلاغ مطلوب");
            if (string.IsNullOrWhiteSpace(request.Description))
                return ResultDto<Guid>.Failed("تفاصيل البلاغ مطلوبة");
            if (request.ReportedUserId == null && request.ReportedPropertyId == null)
                return ResultDto<Guid>.Failed("يجب تحديد المستخدم المبلغ عنه أو الكيان المبلغ عنه");

            // التحقق من وجود المبلغ
            var reporter = await _userRepository.GetByIdAsync(request.ReporterUserId, cancellationToken);
            if (reporter == null || !reporter.IsActive)
                return ResultDto<Guid>.Failed("المستخدم المبلغ غير موجود أو غير نشط");

            // التحقق من وجود الهدف
            if (request.ReportedUserId.HasValue)
            {
                var targetUser = await _userRepository.GetByIdAsync(request.ReportedUserId.Value, cancellationToken);
                if (targetUser == null)
                    return ResultDto<Guid>.Failed("المستخدم المبلغ عنه غير موجود");
            }
            if (request.ReportedPropertyId.HasValue)
            {
                var property = await _propertyRepository.GetPropertyByIdAsync(request.ReportedPropertyId.Value, cancellationToken);
                if (property == null)
                    return ResultDto<Guid>.Failed("الكيان المبلغ عنه غير موجود");
            }

            // التحقق من التكرار
            bool exists = await _reportRepository.ExistsAsync(r =>
                r.ReporterUserId == request.ReporterUserId &&
                r.ReportedUserId == request.ReportedUserId &&
                r.ReportedPropertyId == request.ReportedPropertyId, cancellationToken);
            if (exists)
                return ResultDto<Guid>.Failed("لقد قمت بإنشاء بلاغ مشابه من قبل");

            // إنشاء الكيان
            var report = new Report
            {
                ReporterUserId = request.ReporterUserId,
                ReportedUserId = request.ReportedUserId,
                ReportedPropertyId = request.ReportedPropertyId,
                Reason = request.Reason.Trim(),
                Description = request.Description.Trim(),
                CreatedBy = _currentUserService.UserId,
                CreatedAt = DateTime.UtcNow
            };
            var created = await _reportRepository.CreateReportAsync(report, cancellationToken);

            // تسجيل التدقيق (يدوي) يتضمن اسم ومعرّف المنفذ
            var notes = $"تم إنشاء بلاغ جديد {created.Id} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "Report",
                entityId: created.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { created.Id, request.ReporterUserId, request.ReportedUserId, request.ReportedPropertyId }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل إنشاء البلاغ بنجاح: ReportId={ReportId}", created.Id);
            return ResultDto<Guid>.Succeeded(created.Id, "تم إنشاء البلاغ بنجاح");
        }
    }
} 