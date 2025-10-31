using MediatR;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Units.Commands.CheckUnitAvailability;

/// <summary>
/// معالج أمر فحص توفر الوحدة للعميل
/// Handler for client check unit availability command
/// </summary>
public class ClientCheckUnitAvailabilityCommandHandler : IRequestHandler<ClientCheckUnitAvailabilityCommand, ResultDto<ClientUnitAvailabilityResponse>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

    public ClientCheckUnitAvailabilityCommandHandler(IUnitOfWork unitOfWork, IAuditService auditService, ICurrentUserService currentUserService)
    {
        _unitOfWork = unitOfWork;
        _auditService = auditService;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة أمر فحص توفر الوحدة
    /// Handle check unit availability command
    /// </summary>
    /// <param name="request">الطلب</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<ClientUnitAvailabilityResponse>> Handle(ClientCheckUnitAvailabilityCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // Normalize incoming dates from user-local to UTC
            request.CheckInDate = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckInDate);
            request.CheckOutDate = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckOutDate);

            // التحقق من وجود الوحدة
            // Check if unit exists
            var unitRepo = _unitOfWork.Repository<Core.Entities.Unit>();
            var unit = await unitRepo.GetByIdAsync(request.UnitId);

            if (unit == null)
            {
                return ResultDto<ClientUnitAvailabilityResponse>.Failed("الوحدة غير موجودة", "UNIT_NOT_FOUND");
            }

            // فحص التوفر للفترة المطلوبة
            // Check availability for requested period
            var bookingRepo = _unitOfWork.Repository<Core.Entities.Booking>();
            var bookings = await bookingRepo.GetAllAsync();
            var conflictingBookings = bookings.Where(b => 
                b.UnitId == request.UnitId &&
                b.Status != BookingStatus.Cancelled &&
                !(request.CheckOutDate <= b.CheckIn || request.CheckInDate >= b.CheckOut)
            ).ToList();

            bool isAvailable = !conflictingBookings.Any();

            // حساب السعر للفترة
            // Calculate price for period
            decimal totalPrice = 0;
            var nights = (request.CheckOutDate - request.CheckInDate).Days;
            if (nights > 0)
            {
                totalPrice = unit.BasePrice.Amount * nights;
            }

            var response = new ClientUnitAvailabilityResponse
            {
                UnitId = request.UnitId,
                IsAvailable = isAvailable,
                TotalPrice = totalPrice,
                Currency = unit.BasePrice.Currency,
                PricePerNight = unit.BasePrice.Amount,
                NumberOfNights = nights,
                AdditionalFees = new List<ClientAdditionalFeeDto>(),
                TaxAmount = 0, // يمكن حسابها لاحقاً
                UnavailabilityReason = isAvailable ? null : "الوحدة محجوزة في هذه التواريخ",
                AlternativeDates = new List<ClientAlternativeDateDto>()
            };

            // سجل تدقيق: فحص توفر
            var performerName = _currentUserService.Username;
            var performerId = _currentUserService.UserId;
            var notes = $"تم فحص توفر الوحدة {request.UnitId} من {request.CheckInDate:yyyy-MM-dd} إلى {request.CheckOutDate:yyyy-MM-dd} بواسطة {performerName} (ID={performerId})";
            await _auditService.LogAuditAsync(
                entityType: "Unit",
                entityId: request.UnitId,
                action: AuditAction.VIEW,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new { request.CheckInDate, request.CheckOutDate, isAvailable, totalPrice, nights }),
                performedBy: performerId,
                notes: notes,
                cancellationToken: cancellationToken);

            return ResultDto<ClientUnitAvailabilityResponse>.Ok(response, 
                isAvailable ? "الوحدة متاحة للحجز" : "الوحدة غير متاحة للفترة المطلوبة");
        }
        catch (Exception ex)
        {
            return ResultDto<ClientUnitAvailabilityResponse>.Failed($"حدث خطأ أثناء فحص التوفر: {ex.Message}", "CHECK_AVAILABILITY_ERROR");
        }
    }
}