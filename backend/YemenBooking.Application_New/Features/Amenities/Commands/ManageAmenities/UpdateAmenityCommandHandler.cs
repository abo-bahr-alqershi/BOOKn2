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
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Amenities.Commands.ManageAmenities
{
    /// <summary>
    /// معالج أمر تحديث بيانات المرفق
    /// </summary>
    public class UpdateAmenityCommandHandler : IRequestHandler<UpdateAmenityCommand, ResultDto<bool>>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<UpdateAmenityCommandHandler> _logger;

        public UpdateAmenityCommandHandler(
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<UpdateAmenityCommandHandler> logger)
        {
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        /// <summary>
        /// تنفيذ منطق تحديث المرفق
        /// </summary>
        public async Task<ResultDto<bool>> Handle(UpdateAmenityCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء معالجة أمر تحديث المرفق: {AmenityId}", request.AmenityId);

            try
            {
                // التحقق من صحة المدخلات
                var inputValidation = await ValidateInputAsync(request);
                if (!inputValidation.IsSuccess)
                    return inputValidation;

                // التحقق من وجود المرفق
                var existing = await _unitOfWork.Repository<Amenity>()
                    .GetByIdAsync(request.AmenityId, cancellationToken);
                if (existing == null)
                    return ResultDto<bool>.Failed("المرفق غير موجود");

                // التحقق من الصلاحيات
                var authorizationValidation = await ValidateAuthorizationAsync();
                if (!authorizationValidation.IsSuccess)
                    return authorizationValidation;

                // التحقق من قواعد العمل
                var businessValidation = await ValidateBusinessRulesAsync(request, existing, cancellationToken);
                if (!businessValidation.IsSuccess)
                    return businessValidation;

                // حفظ القيم القديمة للتدقيق
                var oldValues = new Amenity
                {
                    Id = existing.Id,
                    Name = existing.Name,
                    Description = existing.Description,
                    CreatedAt = existing.CreatedAt,
                    UpdatedAt = existing.UpdatedAt,
                    IsDeleted = existing.IsDeleted,
                    DeletedAt = existing.DeletedAt
                };

                // التنفيذ: تحديث بيانات المرفق
                if (!string.IsNullOrWhiteSpace(request.Name))
                    existing.Name = request.Name.Trim();
                if (!string.IsNullOrWhiteSpace(request.Description))
                    existing.Description = request.Description.Trim();
                if (!string.IsNullOrWhiteSpace(request.Icon))
                    existing.Icon = request.Icon.Trim();
                existing.UpdatedAt = DateTime.UtcNow;

                await _unitOfWork.Repository<Amenity>().UpdateAsync(existing, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // الآثار الجانبية: تسجيل العملية في السجل مع القيم القديمة والجديدة (يدوي)
                var notes = $"تم تحديث بيانات المرفق عن طريق {_currentUserService.Username} (ID={_currentUserService.UserId})";
                await _auditService.LogAuditAsync(
                    entityType: nameof(Amenity),
                    entityId: existing.Id,
                    action: AuditAction.UPDATE,
                    oldValues: System.Text.Json.JsonSerializer.Serialize(new { oldValues.Id, oldValues.Name, oldValues.Description }),
                    newValues: System.Text.Json.JsonSerializer.Serialize(new { existing.Id, existing.Name, existing.Description }),
                    performedBy: _currentUserService.UserId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                _logger.LogInformation("تم تحديث المرفق بالمعرف {AmenityId}", existing.Id);
                return ResultDto<bool>.Succeeded(true, "تم تحديث بيانات المرفق بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في معالجة أمر تحديث المرفق: {AmenityId}", request.AmenityId);
                return ResultDto<bool>.Failed("حدث خطأ أثناء تحديث المرفق");
            }
        }

        /// <summary>
        /// التحقق من صحة المدخلات
        /// </summary>
        private Task<ResultDto<bool>> ValidateInputAsync(UpdateAmenityCommand request)
        {
            var errors = new List<string>();

            if (request.AmenityId == Guid.Empty)
                errors.Add("معرف المرفق مطلوب");

            if (string.IsNullOrWhiteSpace(request.Name))
                errors.Add("اسم المرفق مطلوب");
            else if (request.Name.Length > 50)
                errors.Add("اسم المرفق لا يجب أن يتجاوز 50 حرفًا");

            if (request.Description == null)
                errors.Add("وصف المرفق مطلوب");
            else if (request.Description.Length > 200)
                errors.Add("وصف المرفق لا يجب أن يتجاوز 200 حرفًا");

            if (errors.Count > 0)
                return Task.FromResult(ResultDto<bool>.Failed(errors, "بيانات المدخلات غير صحيحة"));

            return Task.FromResult(ResultDto<bool>.Succeeded(true));
        }

        /// <summary>
        /// التحقق من الصلاحيات
        /// </summary>
        private Task<ResultDto<bool>> ValidateAuthorizationAsync()
        {
            if (_currentUserService.Role != "Admin")
                return Task.FromResult(ResultDto<bool>.Failed("غير مصرح لك بتحديث بيانات المرفق"));

            return Task.FromResult(ResultDto<bool>.Succeeded(true));
        }

        /// <summary>
        /// التحقق من قواعد العمل
        /// </summary>
        private async Task<ResultDto<bool>> ValidateBusinessRulesAsync(
            UpdateAmenityCommand request,
            Amenity existing,
            CancellationToken cancellationToken)
        {
            // التحقق من عدم وجود مرفق آخر بنفس الاسم عند تغييره
            if (!string.Equals(existing.Name.Trim(), request.Name.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                var duplicate = await _unitOfWork.Repository<Amenity>()
                    .ExistsAsync(a => a.Name.ToLower() == request.Name.Trim().ToLower(), cancellationToken);
                if (duplicate)
                    return ResultDto<bool>.Failed("مرفق آخر بنفس الاسم موجود مسبقًا");
            }

            return ResultDto<bool>.Succeeded(true);
        }
    }
} 