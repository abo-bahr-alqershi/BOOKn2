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

namespace YemenBooking.Application.Features.PropertyTypes.Commands.CreateProperty
{
    /// <summary>
    /// معالج أمر إنشاء نوع كيان جديد
    /// </summary>
    public class CreatePropertyTypeCommandHandler : IRequestHandler<CreatePropertyTypeCommand, ResultDto<Guid>>
    {
        private readonly IPropertyTypeRepository _repository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<CreatePropertyTypeCommandHandler> _logger;

        public CreatePropertyTypeCommandHandler(
            IPropertyTypeRepository repository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<CreatePropertyTypeCommandHandler> logger)
        {
            _repository = repository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<Guid>> Handle(CreatePropertyTypeCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء إنشاء نوع كيان جديد: Name={Name}", request.Name);

            // التحقق من المدخلات
            if (string.IsNullOrWhiteSpace(request.Name))
                return ResultDto<Guid>.Failed("اسم نوع الكيان مطلوب");

            // التحقق من الصلاحيات (مسؤول)
            if (_currentUserService.Role != "Admin")
                return ResultDto<Guid>.Failed("غير مصرح لك بإنشاء نوع كيان");

            // التحقق من التكرار
            bool exists = await _repository.ExistsAsync(pt => pt.Name.Trim() == request.Name.Trim(), cancellationToken);
            if (exists)
                return ResultDto<Guid>.Failed("يوجد نوع كيان بنفس الاسم");

            // إنشاء نوع الكيان
            var type = new PropertyType
            {
                Name = request.Name.Trim(),
                Description = request.Description?.Trim(),
                DefaultAmenities = request.DefaultAmenities,
                Icon = request.Icon.Trim(),
                CreatedBy = _currentUserService.UserId,
                CreatedAt = DateTime.UtcNow
            };
            var created = await _repository.CreatePropertyTypeAsync(type, cancellationToken);

            // تسجيل التدقيق (يدوي) مع ذكر اسم المستخدم والمعرف
            var notes = $"تم إنشاء نوع كيان جديد {created.Id} باسم {created.Name} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "PropertyType",
                entityId: created.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { created.Id, created.Name }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل إنشاء نوع الكيان: PropertyTypeId={PropertyTypeId}", created.Id);
            return ResultDto<Guid>.Succeeded(created.Id, "تم إنشاء نوع الكيان بنجاح");
        }
    }
} 