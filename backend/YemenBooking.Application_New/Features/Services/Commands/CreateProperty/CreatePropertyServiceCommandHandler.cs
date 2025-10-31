 using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Services;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Services.Commands.CreateProperty
{
    /// <summary>
    /// معالج أمر إنشاء خدمة جديدة للكيان
    /// </summary>
    public class CreatePropertyServiceCommandHandler : IRequestHandler<CreatePropertyServiceCommand, ResultDto<Guid>>
    {
        private readonly IPropertyServiceRepository _serviceRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<CreatePropertyServiceCommandHandler> _logger;
        private readonly ICurrencySettingsService _currencySettingsService;

        public CreatePropertyServiceCommandHandler(
            IPropertyServiceRepository serviceRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<CreatePropertyServiceCommandHandler> logger,
            ICurrencySettingsService currencySettingsService)
        {
            _serviceRepository = serviceRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
            _currencySettingsService = currencySettingsService;
        }

        public async Task<ResultDto<Guid>> Handle(CreatePropertyServiceCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء إنشاء خدمة للكيان: PropertyId={PropertyId}, Name={Name}", request.PropertyId, request.Name);

            // التحقق من المدخلات
            if (request.PropertyId == Guid.Empty)
                return ResultDto<Guid>.Failed("معرف الكيان مطلوب");
            if (string.IsNullOrWhiteSpace(request.Name))
                return ResultDto<Guid>.Failed("اسم الخدمة مطلوب");
            if (request.Price == null || request.Price.Amount < 0)
                return ResultDto<Guid>.Failed("السعر لا يمكن أن يكون سالباً");
            // allow zero for free services

            if (request.Price != null && decimal.Round(request.Price.Amount, 2) != request.Price.Amount)
                return ResultDto<Guid>.Failed("عدد المنازل العشرية للسعر يجب ألا يتجاوز رقمين");

            // التحقق من الصلاحيات (مالك الكيان أو مسؤول)
            var property = await _serviceRepository.GetPropertyByIdAsync(request.PropertyId, cancellationToken);
            if (property == null)
                return ResultDto<Guid>.Failed("الكيان غير موجود");
            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);
            if (!isAdmin && property.OwnerId != _currentUserService.UserId)
                return ResultDto<Guid>.Failed("غير مصرح لك بإنشاء خدمة لهذا الكيان");

            // Validate currency consistency with property
            if (!string.Equals(request.Price.Currency, property.Currency, StringComparison.OrdinalIgnoreCase))
                return ResultDto<Guid>.Failed($"عملة السعر ({request.Price.Currency}) يجب أن تطابق عملة الكيان ({property.Currency})");

            // Validate currency is supported by system settings
            var currencies = await _currencySettingsService.GetCurrenciesAsync(cancellationToken);
            var isSupported = currencies.Any(c => string.Equals(c.Code, request.Price.Currency, StringComparison.OrdinalIgnoreCase));
            if (!isSupported)
                return ResultDto<Guid>.Failed("العملة غير مدعومة في إعدادات النظام");

            // التحقق من التكرار
            bool exists = await _serviceRepository.ExistsAsync(s => s.PropertyId == request.PropertyId && s.Name.Trim() == request.Name.Trim(), cancellationToken);
            if (exists)
                return ResultDto<Guid>.Failed("يوجد خدمة بنفس الاسم لهذا الكيان");

            // إنشاء الكيان
            var service = new PropertyService
            {
                PropertyId = request.PropertyId,
                Name = request.Name.Trim(),
                Price = new Money(request.Price.Amount, request.Price.Currency),
                PricingModel = request.PricingModel,
                Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description!.Trim(),
                Icon = (request.Icon ?? string.Empty).Trim(),
                CreatedBy = _currentUserService.UserId,
                CreatedAt = DateTime.UtcNow
            };
            var created = await _serviceRepository.CreatePropertyServiceAsync(service, cancellationToken);

            // تسجيل التدقيق (يدوي) يتضمن اسم ومعرّف المنفذ
            var notes = $"تم إنشاء خدمة جديدة {created.Id} للكيان {created.PropertyId} (السعر: {created.Price.Amount} {created.Price.Currency}, الوصف: {created.Description ?? "-"}) بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "PropertyService",
                entityId: created.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { created.Id, created.PropertyId, created.Name, created.Price, created.Description }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل إنشاء الخدمة بنجاح: ServiceId={ServiceId}", created.Id);
            return ResultDto<Guid>.Succeeded(created.Id, "تم إنشاء الخدمة بنجاح");
        }
    }
}