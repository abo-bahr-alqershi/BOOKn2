using MediatR;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.Properties.Commands.UpdateProperty;

/// <summary>
/// معالج أمر تحديث عدد المشاهدات للعقار للعميل
/// Handler for client update property view count command
/// </summary>
public class ClientUpdatePropertyViewCountCommandHandler : IRequestHandler<ClientUpdatePropertyViewCountCommand, ResultDto<bool>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

    public ClientUpdatePropertyViewCountCommandHandler(IUnitOfWork unitOfWork, IAuditService auditService, ICurrentUserService currentUserService)
    {
        _unitOfWork = unitOfWork;
        _auditService = auditService;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة أمر تحديث عدد المشاهدات للعقار
    /// Handle update property view count command
    /// </summary>
    /// <param name="request">الطلب</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<bool>> Handle(ClientUpdatePropertyViewCountCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // التحقق من وجود العقار
            // Check if property exists
            var propertyRepo = _unitOfWork.Repository<Core.Entities.Property>();
            var property = await propertyRepo.GetByIdAsync(request.PropertyId);

            if (property == null)
            {
                return ResultDto<bool>.Failed("العقار غير موجود", "PROPERTY_NOT_FOUND");
            }

            // زيادة عدد المشاهدات
            // Increment view count
            property.ViewCount++;
            property.UpdatedAt = DateTime.UtcNow;

            // تحديث العقار
            // Update property
            await propertyRepo.UpdateAsync(property);

            // حفظ التغييرات
            // Save changes
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // تدقيق يدوي: زيادة عدد المشاهدات
            var performerName = _currentUserService.Username;
            var performerId = _currentUserService.UserId;
            var notes = $"تم تحديث عدد المشاهدات للعقار {request.PropertyId} بواسطة {performerName} (ID={performerId})";
            await _auditService.LogAuditAsync(
                entityType: "Property",
                entityId: request.PropertyId,
                action: AuditAction.UPDATE,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new { ViewCount = property.ViewCount }),
                performedBy: performerId,
                notes: notes,
                cancellationToken: cancellationToken);

            return ResultDto<bool>.Ok(true, "تم تحديث عدد المشاهدات بنجاح");
        }
        catch (Exception ex)
        {
            return ResultDto<bool>.Failed($"حدث خطأ أثناء تحديث عدد المشاهدات: {ex.Message}", "UPDATE_VIEW_COUNT_ERROR");
        }
    }
}