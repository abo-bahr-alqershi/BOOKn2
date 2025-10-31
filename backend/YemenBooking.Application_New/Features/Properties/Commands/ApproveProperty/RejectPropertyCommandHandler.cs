using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Notifications;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Application_New.Core.Enums;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Properties.Commands.ApproveProperty
{
    /// <summary>
    /// معالج أمر رفض الكيان
    /// </summary>
    public class RejectPropertyCommandHandler : IRequestHandler<RejectPropertyCommand, ResultDto<bool>>
    {
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly INotificationService _notificationService;
        private readonly IAuditService _auditService;
        private readonly ILogger<RejectPropertyCommandHandler> _logger;

        public RejectPropertyCommandHandler(
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            INotificationService notificationService,
            IAuditService auditService,
            ILogger<RejectPropertyCommandHandler> logger)
        {
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _notificationService = notificationService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(RejectPropertyCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء رفض الكيان: PropertyId={PropertyId}", request.PropertyId);

            // التحقق من صحة المدخلات
            if (request.PropertyId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الكيان مطلوب");
            if (string.IsNullOrWhiteSpace(request.Reason))
                return ResultDto<bool>.Failed("سبب الرفض مطلوب");
            if (request.AdminId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف المسؤول مطلوب");

            // التحقق من الصلاحيات (مسؤول)
            if (_currentUserService.Role != "Admin")
                return ResultDto<bool>.Failed("غير مصرح لك برفض الكيان");

            // التحقق من وجود الكيان وحالته
            var property = await _propertyRepository.GetPropertyByIdAsync(request.PropertyId, cancellationToken);
            if (property == null)
                return ResultDto<bool>.Failed("الكيان غير موجود");
            if (property.IsApproved)
                return ResultDto<bool>.Failed("الكيان معتمد مسبقاً ولا يمكن رفضه");

            // تنفيذ الرفض
            var success = await _propertyRepository.RejectPropertyAsync(request.PropertyId, request.Reason, cancellationToken);
            if (!success)
                return ResultDto<bool>.Failed("فشل رفض الكيان");

            // تسجيل العملية في سجل التدقيق
            await _auditService.LogAuditAsync(
                entityType: "Property",
                entityId: request.PropertyId,
                action: YemenBooking.Core.Entities.AuditAction.REJECT,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { Rejected = true, Reason = request.Reason }),
                performedBy: _currentUserService.UserId,
                notes: $"تم رفض الكيان {request.PropertyId} لسبب: {request.Reason} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            // إرسال إشعار للمالك
            await _notificationService.SendAsync(new NotificationRequest
            {
                UserId = property.OwnerId,
                Type = NotificationType.BookingCancelled,
                Title = "تم رفض الكيان",
                Message = $"عذراً، تم رفض كيانك '{property.Name}' بسبب: {request.Reason}"
            }, cancellationToken);

            _logger.LogInformation("اكتمل رفض الكيان: PropertyId={PropertyId}", request.PropertyId);
            return ResultDto<bool>.Succeeded(true, "تم رفض الكيان بنجاح");
        }
    }
} 