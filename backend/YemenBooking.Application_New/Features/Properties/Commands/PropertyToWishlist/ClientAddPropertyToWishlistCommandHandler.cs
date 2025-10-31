using MediatR;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Application_New.Core.Enums;

namespace YemenBooking.Application.Features.Properties.Commands.PropertyToWishlist;

/// <summary>
/// معالج أمر إضافة العقار لقائمة الأمنيات للعميل
/// Handler for client add property to wishlist command
/// </summary>
public class ClientAddPropertyToWishlistCommandHandler : IRequestHandler<ClientAddPropertyToWishlistCommand, ResultDto<bool>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

    public ClientAddPropertyToWishlistCommandHandler(IUnitOfWork unitOfWork, IAuditService auditService, ICurrentUserService currentUserService)
    {
        _unitOfWork = unitOfWork;
        _auditService = auditService;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة أمر إضافة العقار لقائمة الأمنيات
    /// Handle add property to wishlist command
    /// </summary>
    /// <param name="request">الطلب</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<bool>> Handle(ClientAddPropertyToWishlistCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // التحقق من وجود العقار
            // Check if property exists
            var property = await _unitOfWork.Repository<Core.Entities.Property>()
                .GetByIdAsync(request.PropertyId);

            if (property == null)
            {
                return ResultDto<bool>.Failed("العقار غير موجود", "PROPERTY_NOT_FOUND");
            }

            // التحقق من وجود المستخدم
            // Check if user exists
            var user = await _unitOfWork.Users.GetByIdAsync(request.UserId);

            if (user == null)
            {
                return ResultDto<bool>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            // البحث عن أول وحدة في العقار للاستخدام كرمز للمفضلة
            // Find first unit in property to use as wishlist identifier
            var unitRepo = _unitOfWork.Repository<Core.Entities.Unit>();
            var units = await unitRepo.GetAllAsync();
            var firstUnit = units.FirstOrDefault(u => u.PropertyId == request.PropertyId);

            if (firstUnit == null)
            {
                return ResultDto<bool>.Failed("العقار لا يحتوي على وحدات متاحة", "NO_UNITS_AVAILABLE");
            }

            // التحقق من عدم وجود العقار مسبقاً في المفضلة
            // Check if property is not already in favorites
            var bookingRepo = _unitOfWork.Repository<Core.Entities.Booking>();
            var bookings = await bookingRepo.GetAllAsync();
            var existingFavorite = bookings.FirstOrDefault(b => 
                b.UserId == request.UserId && 
                b.UnitId == firstUnit.Id && 
                b.BookingSource == "Wishlist");

            if (existingFavorite != null)
            {
                return ResultDto<bool>.Failed("العقار موجود بالفعل في قائمة الأمنيات", "ALREADY_IN_WISHLIST");
            }

            // إنشاء سجل جديد في المفضلة (استخدام جدول BookingDto مع BookingSource خاص)
            // Create new favorite record (using BookingDto table with special BookingSource)
            var wishlistItem = new Core.Entities.Booking
            {
                Id = Guid.NewGuid(),
                UserId = request.UserId,
                UnitId = firstUnit.Id,
                Status = BookingStatus.Pending,
                BookingSource = "Wishlist",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                CheckIn = request.DesiredVisitDate.HasValue ? await _currentUserService.ConvertFromUserLocalToUtcAsync(request.DesiredVisitDate.Value) : DateTime.UtcNow.AddDays(30),
                CheckOut = request.DesiredVisitDate.HasValue ? await _currentUserService.ConvertFromUserLocalToUtcAsync(request.DesiredVisitDate.Value.AddDays(1)) : DateTime.UtcNow.AddDays(31),
                TotalPrice = new Core.ValueObjects.Money(request.ExpectedBudget ?? 0, request.Currency ?? "YER"),
                GuestsCount = 1,
                BookedAt = DateTime.UtcNow
            };

            await bookingRepo.AddAsync(wishlistItem);

            // حفظ التغييرات
            // Save changes
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // تدقيق يدوي: إضافة إلى الأمنيات
            var performerName = _currentUserService.Username;
            var performerId = _currentUserService.UserId;
            var notes = $"تمت إضافة العقار {request.PropertyId} إلى قائمة الأمنيات بواسطة {performerName} (ID={performerId})";
            await _auditService.LogAuditAsync(
                entityType: "Wishlist",
                entityId: wishlistItem.Id,
                action: YemenBooking.Core.Entities.AuditAction.CREATE,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new { wishlistItem.Id, request.PropertyId, request.UserId }),
                performedBy: performerId,
                notes: notes,
                cancellationToken: cancellationToken);

            return ResultDto<bool>.Ok(true, "تم إضافة العقار لقائمة الأمنيات بنجاح");
        }
        catch (Exception ex)
        {
            return ResultDto<bool>.Failed($"حدث خطأ أثناء إضافة العقار لقائمة الأمنيات: {ex.Message}", "ADD_TO_WISHLIST_ERROR");
        }
    }
}