using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Favorites.Commands;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Application.Features.Favorites.Commands.FromFavorites;

/// <summary>
/// معالج أمر إزالة عقار من المفضلة عبر تطبيق الجوال
/// </summary>
public class RemoveFromFavoritesCommandHandler : IRequestHandler<RemoveFromFavoritesCommand, ResultDto<RemoveFromFavoritesResponse>>
{
    private readonly IUserRepository _userRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IFavoriteRepository _favoriteRepository;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<RemoveFromFavoritesCommandHandler> _logger;

    public RemoveFromFavoritesCommandHandler(
        IUserRepository userRepository,
        IPropertyRepository propertyRepository,
        IFavoriteRepository favoriteRepository,
        IAuditService auditService,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<RemoveFromFavoritesCommandHandler> logger)
    {
        _userRepository = userRepository;
        _propertyRepository = propertyRepository;
        _favoriteRepository = favoriteRepository;
        _auditService = auditService;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ResultDto<RemoveFromFavoritesResponse>> Handle(RemoveFromFavoritesCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("إزالة العقار {PropertyId} من مفضلة المستخدم {UserId}", request.PropertyId, request.UserId);

        var user = await _userRepository.GetUserByIdAsync(request.UserId, cancellationToken);
        if (user == null)
            return ResultDto<RemoveFromFavoritesResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");

        var property = await _propertyRepository.GetByIdAsync(request.PropertyId, cancellationToken);
        if (property == null)
            return ResultDto<RemoveFromFavoritesResponse>.Failed("العقار غير موجود", "PROPERTY_NOT_FOUND");

        var deleted = await _favoriteRepository.DeleteByUserAndPropertyAsync(request.UserId, request.PropertyId, cancellationToken);
        if (!deleted)
        {
            return ResultDto<RemoveFromFavoritesResponse>.Ok(new RemoveFromFavoritesResponse
            {
                Success = true,
                Message = "تمت الإزالة بنجاح"
            }, "تمت الإزالة بنجاح");
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Audit
        var performerName = _currentUserService.Username;
        var performerId = _currentUserService.UserId;
        var notes = $"تمت إزالة العقار {request.PropertyId} من المفضلة بواسطة {performerName} (ID={performerId})";
        await _auditService.LogAuditAsync(
            entityType: "Favorite",
            entityId: request.PropertyId,
            action: AuditAction.DELETE,
            oldValues: null,
            newValues: System.Text.Json.JsonSerializer.Serialize(new { FavoriteRemoved = request.PropertyId, UserId = user.Id }),
            performedBy: performerId,
            notes: notes,
            cancellationToken: cancellationToken);

        return ResultDto<RemoveFromFavoritesResponse>.Ok(new RemoveFromFavoritesResponse
        {
            Success = true,
            Message = "تمت الإزالة بنجاح"
        }, "تمت الإزالة بنجاح");
    }
}
