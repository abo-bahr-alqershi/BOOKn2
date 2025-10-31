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

namespace YemenBooking.Application.Features.Favorites.Commands.ToFavorites;

/// <summary>
/// معالج أمر إضافة عقار إلى المفضلة من تطبيق الجوال
/// </summary>
public class AddToFavoritesCommandHandler : IRequestHandler<AddToFavoritesCommand, ResultDto<AddToFavoritesResponse>>
{
    private readonly IUserRepository _userRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IFavoriteRepository _favoriteRepository;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<AddToFavoritesCommandHandler> _logger;

    public AddToFavoritesCommandHandler(
        IUserRepository userRepository,
        IPropertyRepository propertyRepository,
        IFavoriteRepository favoriteRepository,
        IAuditService auditService,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<AddToFavoritesCommandHandler> logger)
    {
        _userRepository = userRepository;
        _propertyRepository = propertyRepository;
        _favoriteRepository = favoriteRepository;
        _auditService = auditService;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task<ResultDto<AddToFavoritesResponse>> Handle(AddToFavoritesCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("إضافة العقار {PropertyId} إلى مفضلة المستخدم {UserId}", request.PropertyId, request.UserId);

        // Validate user
        var user = await _userRepository.GetUserByIdAsync(request.UserId, cancellationToken);
        if (user == null)
            return ResultDto<AddToFavoritesResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");

        // Validate property
        var property = await _propertyRepository.GetByIdAsync(request.PropertyId, cancellationToken);
        if (property == null)
            return ResultDto<AddToFavoritesResponse>.Failed("العقار غير موجود", "PROPERTY_NOT_FOUND");

        // Check if exists (idempotent)
        var exists = await _favoriteRepository.ExistsAsync(request.UserId, request.PropertyId, cancellationToken);
        if (exists)
        {
            return ResultDto<AddToFavoritesResponse>.Ok(new AddToFavoritesResponse
            {
                Success = true,
                Message = "تمت الإضافة بنجاح"
            }, "تمت الإضافة بنجاح");
        }

        // Create favorite
        var favorite = new Favorite
        {
            Id = Guid.NewGuid(),
            UserId = request.UserId,
            PropertyId = request.PropertyId,
            DateAdded = DateTime.UtcNow,
            IsActive = true,
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _favoriteRepository.AddAsync(favorite, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Audit
        var performerName = _currentUserService.Username;
        var performerId = _currentUserService.UserId;
        var notes = $"تمت إضافة العقار {request.PropertyId} إلى المفضلة بواسطة {performerName} (ID={performerId})";
        await _auditService.LogAuditAsync(
            entityType: "Favorite",
            entityId: favorite.Id,
            action: AuditAction.CREATE,
            oldValues: null,
            newValues: System.Text.Json.JsonSerializer.Serialize(new { FavoriteAdded = request.PropertyId, UserId = user.Id }),
            performedBy: performerId,
            notes: notes,
            cancellationToken: cancellationToken);

        return ResultDto<AddToFavoritesResponse>.Ok(new AddToFavoritesResponse
        {
            Success = true,
            Message = "تمت الإضافة بنجاح"
        }, "تمت الإضافة بنجاح");
    }
}
