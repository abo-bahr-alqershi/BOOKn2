using System;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;
using System.Linq;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Amenities.Commands.ManageAmenities
{
    /// <summary>
    /// معالج أمر إنشاء المرفق
    /// </summary>
    public class CreateAmenityCommandHandler : IRequestHandler<CreateAmenityCommand, ResultDto<Guid>>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<CreateAmenityCommandHandler> _logger;

        public CreateAmenityCommandHandler(
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<CreateAmenityCommandHandler> logger)
        {
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        /// <summary>
        /// تنفيذ منطق إنشاء المرفق
        /// </summary>
        public async Task<ResultDto<Guid>> Handle(CreateAmenityCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء معالجة أمر إنشاء المرفق: {Name}", request.Name);

            try
            {
                // التحقق من صحة المدخلات
                var inputValidation = await ValidateInputAsync(request);
                if (!inputValidation.IsSuccess)
                    return inputValidation;

                // التحقق من الصلاحيات
                var authorizationValidation = await ValidateAuthorizationAsync();
                if (!authorizationValidation.IsSuccess)
                    return authorizationValidation;

                // التحقق من قواعد العمل
                var businessValidation = await ValidateBusinessRulesAsync(request, cancellationToken);
                if (!businessValidation.IsSuccess)
                    return businessValidation;

                // التنفيذ: إنشاء المرفق
                var amenity = new Amenity
                {
                    Id = Guid.NewGuid(),
                    Name = request.Name.Trim(),
                    Description = request.Description.Trim(),
                    Icon = (request.Icon ?? string.Empty).Trim(),
                    CreatedAt = DateTime.UtcNow
                };

                await _unitOfWork.Repository<Amenity>().AddAsync(amenity, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // If a PropertyTypeId was provided, create the link immediately
                if (request.PropertyTypeId.HasValue && request.PropertyTypeId.Value != Guid.Empty)
                {
                    // validate property type exists
                    var propertyType = await _unitOfWork.Repository<PropertyType>()
                        .GetByIdAsync(request.PropertyTypeId.Value, cancellationToken);
                    if (propertyType == null)
                    {
                        return ResultDto<Guid>.Failed("نوع الكيان المحدد غير موجود");
                    }

                    var linkExists = await _unitOfWork.Repository<PropertyTypeAmenity>()
                        .ExistsAsync(x => x.PropertyTypeId == request.PropertyTypeId.Value && x.AmenityId == amenity.Id, cancellationToken);
                    if (!linkExists)
                    {
                        var pta = new PropertyTypeAmenity
                        {
                            PropertyTypeId = request.PropertyTypeId.Value,
                            AmenityId = amenity.Id,
                            IsDefault = request.IsDefaultForType
                        };
                        await _unitOfWork.Repository<PropertyTypeAmenity>().AddAsync(pta, cancellationToken);
                        await _unitOfWork.SaveChangesAsync(cancellationToken);

                        var notesLink = $"تم ربط المرفق بنوع الكيان مباشرة بعد الإنشاء بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
                        await _auditService.LogAuditAsync(
                            entityType: nameof(PropertyTypeAmenity),
                            entityId: pta.Id,
                            action: AuditAction.CREATE,
                            oldValues: null,
                            newValues: System.Text.Json.JsonSerializer.Serialize(new { pta.PropertyTypeId, pta.AmenityId, pta.IsDefault }),
                            performedBy: _currentUserService.UserId,
                            notes: notesLink,
                            cancellationToken: cancellationToken);
                    }
                }

                // الآثار الجانبية: تسجيل العملية في السجل (يدوي)
                var notes = $"تم إنشاء المرفق بنجاح بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
                await _auditService.LogAuditAsync(
                    entityType: nameof(Amenity),
                    entityId: amenity.Id,
                    action: AuditAction.CREATE,
                    oldValues: null,
                    newValues: System.Text.Json.JsonSerializer.Serialize(new { amenity.Id, amenity.Name, amenity.Description, amenity.Icon }),
                    performedBy: _currentUserService.UserId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                _logger.LogInformation("تم إنشاء المرفق بالمعرف {AmenityId}", amenity.Id);

                return ResultDto<Guid>.Succeeded(amenity.Id, "تم إنشاء المرفق بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في معالجة أمر إنشاء المرفق: {Name}", request.Name);
                return ResultDto<Guid>.Failed("حدث خطأ أثناء إنشاء المرفق");
            }
        }

        /// <summary>
        /// التحقق من صحة المدخلات
        /// </summary>
        private Task<ResultDto<Guid>> ValidateInputAsync(CreateAmenityCommand request)
        {
            var errors = new List<string>();

            if (string.IsNullOrWhiteSpace(request.Name))
                errors.Add("اسم المرفق مطلوب");
            else if (request.Name.Length > 50)
                errors.Add("اسم المرفق لا يجب أن يتجاوز 50 حرفًا");

            if (!string.IsNullOrWhiteSpace(request.Description) && request.Description.Length > 200)
                errors.Add("وصف المرفق لا يجب أن يتجاوز 200 حرفًا");

            if (errors.Count > 0)
                return Task.FromResult(ResultDto<Guid>.Failed(errors, "بيانات المدخلات غير صحيحة"));

            return Task.FromResult(ResultDto<Guid>.Succeeded(Guid.Empty));
        }

        /// <summary>
        /// التحقق من الصلاحيات
        /// </summary>
        private Task<ResultDto<Guid>> ValidateAuthorizationAsync()
        {
            if (_currentUserService.Role != "Admin")
                return Task.FromResult(ResultDto<Guid>.Failed("غير مصرح لك بإنشاء مرافق"));

            return Task.FromResult(ResultDto<Guid>.Succeeded(Guid.Empty));
        }

        /// <summary>
        /// التحقق من قواعد العمل
        /// </summary>
        private async Task<ResultDto<Guid>> ValidateBusinessRulesAsync(CreateAmenityCommand request, CancellationToken cancellationToken)
        {
            var exists = await _unitOfWork.Repository<Amenity>()
                .ExistsAsync(a => a.Name.ToLower() == request.Name.Trim().ToLower(), cancellationToken);

            if (exists)
                return ResultDto<Guid>.Failed("مرفق بنفس الاسم موجود مسبقًا");

            return ResultDto<Guid>.Succeeded(Guid.Empty);
        }
    }
} 