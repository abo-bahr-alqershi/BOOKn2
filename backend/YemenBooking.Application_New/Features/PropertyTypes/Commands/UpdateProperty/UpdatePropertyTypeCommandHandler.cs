using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.PropertyTypes;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.PropertyTypes.Commands.UpdateProperty
{
    /// <summary>
    /// معالج أمر تحديث نوع الكيان
    /// </summary>
    public class UpdatePropertyTypeCommandHandler : IRequestHandler<UpdatePropertyTypeCommand, ResultDto<bool>>
    {
        private readonly IPropertyTypeRepository _repository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<UpdatePropertyTypeCommandHandler> _logger;

        public UpdatePropertyTypeCommandHandler(
            IPropertyTypeRepository repository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<UpdatePropertyTypeCommandHandler> logger)
        {
            _repository = repository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(UpdatePropertyTypeCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تحديث نوع الكيان: Id={PropertyTypeId}", request.PropertyTypeId);

            // التحقق من المدخلات
            if (request.PropertyTypeId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف نوع الكيان مطلوب");

            // التحقق من الصلاحيات (مسؤول)
            if (_currentUserService.Role != "Admin")
                return ResultDto<bool>.Failed("غير مصرح لك بتحديث نوع الكيان");

            // التحقق من الوجود
            var type = await _repository.GetPropertyTypeByIdAsync(request.PropertyTypeId, cancellationToken);
            if (type == null)
                return ResultDto<bool>.Failed("نوع الكيان غير موجود");

            // التحقق من التكرار عند تغيير الاسم
            if (!string.Equals(type.Name, request.Name?.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                bool duplicate = await _repository.ExistsAsync(pt => pt.Name.Trim() == request.Name.Trim() && pt.Id != request.PropertyTypeId, cancellationToken);
                if (duplicate)
                    return ResultDto<bool>.Failed("يوجد نوع كيان آخر بنفس الاسم");
                type.Name = request.Name.Trim();
            }
            type.Description = request.Description?.Trim();
            type.DefaultAmenities = request.DefaultAmenities;
            type.Icon = request.Icon.Trim();
            type.UpdatedBy = _currentUserService.UserId;
            type.UpdatedAt = DateTime.UtcNow;

            await _repository.UpdatePropertyTypeAsync(type, cancellationToken);

            // تسجيل التدقيق (يدوي) مع ذكر اسم المستخدم والمعرف
            var notes = $"تم تحديث نوع الكيان {request.PropertyTypeId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "PropertyType",
                entityId: request.PropertyTypeId,
                action: AuditAction.UPDATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { Updated = true }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل تحديث نوع الكيان: Id={PropertyTypeId}", request.PropertyTypeId);
            return ResultDto<bool>.Succeeded(true, "تم تحديث نوع الكيان بنجاح");
        }
    }
} 