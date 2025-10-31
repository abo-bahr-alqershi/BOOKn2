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
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Application.Features.Amenities.Commands.ManageAmenities
{
    /// <summary>
    /// معالج أمر حذف المرفق
    /// </summary>
    public class DeleteAmenityCommandHandler : IRequestHandler<DeleteAmenityCommand, ResultDto<bool>>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<DeleteAmenityCommandHandler> _logger;
        private readonly IMediator _mediator;
        private readonly IIndexingService _indexingService;

        public DeleteAmenityCommandHandler(
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<DeleteAmenityCommandHandler> logger,
            IMediator mediator,
            IIndexingService indexingService)
        {
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
            _mediator = mediator;
            _indexingService = indexingService;
        }

        /// <summary>
        /// تنفيذ منطق حذف المرفق
        /// </summary>
        public async Task<ResultDto<bool>> Handle(DeleteAmenityCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء معالجة أمر حذف المرفق: {AmenityId}", request.AmenityId);

            try
            {
                // التحقق من صحة المدخلات
                var errors = new List<string>();
                if (request.AmenityId == Guid.Empty)
                    errors.Add("معرف المرفق مطلوب");

                if (errors.Count > 0)
                    return ResultDto<bool>.Failed(errors, "بيانات المدخلات غير صحيحة");

                // التحقق من وجود المرفق
                var existingAmenity = await _unitOfWork.Repository<Amenity>()
                    .GetByIdAsync(request.AmenityId, cancellationToken);
                if (existingAmenity == null)
                    return ResultDto<bool>.Failed("المرفق غير موجود");

                // التحقق من الصلاحيات
                if (_currentUserService.Role != "Admin")
                    return ResultDto<bool>.Failed("غير مصرح لك بحذف المرفق");

                // التحقق من عدم استخدام المرفق بأنواع الكيانات أو الكيانات نفسها
                var isUsedInType = await _unitOfWork.Repository<PropertyTypeAmenity>()
                    .ExistsAsync(pta => pta.AmenityId == request.AmenityId, cancellationToken);
                if (isUsedInType)
                    return ResultDto<bool>.Failed("لا يمكن حذف المرفق لأنه مرتبط بأنواع الكيانات");

                // إذا كانت هناك وسيلة من هذا النوع مخصصة لعقار، نرفض الحذف
                var ptaIds = await _unitOfWork.Repository<PropertyTypeAmenity>()
                    .FindAsync(x => x.AmenityId == request.AmenityId, cancellationToken);
                if (ptaIds.Any())
                {
                    var hasPropertyAmenity = await _unitOfWork.Repository<PropertyAmenity>()
                        .ExistsAsync(pa => ptaIds.Select(p => p.Id).Contains(pa.PtaId), cancellationToken);
                    if (hasPropertyAmenity)
                        return ResultDto<bool>.Failed("لا يمكن حذف المرفق لأنه مستخدم في عقارات حالية");
                }

                // التنفيذ: الحذف الناعم
                existingAmenity.IsDeleted = true;
                existingAmenity.DeletedAt = DateTime.UtcNow;
                existingAmenity.DeletedBy = _currentUserService.UserId;

                await _unitOfWork.Repository<Amenity>()
                    .UpdateAsync(existingAmenity, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // الآثار الجانبية: تسجيل العملية في السجل (يدوي) مع اسم المستخدم والمعرف
                var notes = $"تم حذف المرفق بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
                await _auditService.LogAuditAsync(
                    entityType: nameof(Amenity),
                    entityId: existingAmenity.Id,
                    action: AuditAction.DELETE,
                    oldValues: System.Text.Json.JsonSerializer.Serialize(new { existingAmenity.Id, existingAmenity.Name }),
                    newValues: null,
                    performedBy: _currentUserService.UserId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                // تحديث مباشر لفهرس العقارات المتأثرة
                try
                {
                    var _ptaIds = await _unitOfWork.Repository<PropertyTypeAmenity>()
                        .FindAsync(x => x.AmenityId == existingAmenity.Id, cancellationToken);
                    var propertyAmenities = await _unitOfWork.Repository<PropertyAmenity>()
                        .FindAsync(x => _ptaIds.Select(p => p.Id).Contains(x.PtaId), cancellationToken);

                    foreach (var pa in propertyAmenities)
                    {
                        await _indexingService.OnPropertyUpdatedAsync(pa.PropertyId, cancellationToken);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "تعذرت الفهرسة المباشرة للعقارات بعد حذف المرفق {AmenityId}", existingAmenity.Id);
                }

                _logger.LogInformation("تم حذف المرفق بالمعرف {AmenityId}", existingAmenity.Id);
                return ResultDto<bool>.Succeeded(true, "تم حذف المرفق بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في معالجة أمر حذف المرفق: {AmenityId}", request.AmenityId);
                return ResultDto<bool>.Failed("حدث خطأ أثناء حذف المرفق");
            }
        }
    }
} 