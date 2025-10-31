using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Bookings;
using YemenBooking.Application.Features.Bookings.DTOs;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingsByProperty
{
    /// <summary>
    /// معالج استعلام الحصول على حجوزات كيان معين
    /// Query handler for GetBookingsByPropertyQuery
    /// </summary>
    public class GetBookingsByPropertyQueryHandler : IRequestHandler<GetBookingsByPropertyQuery, PaginatedResult<BookingDto>>
    {
        private readonly IBookingRepository _bookingRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;
        private readonly ILogger<GetBookingsByPropertyQueryHandler> _logger;

        public GetBookingsByPropertyQueryHandler(
            IBookingRepository bookingRepository,
            ICurrentUserService currentUserService,
            IMapper mapper,
            ILogger<GetBookingsByPropertyQueryHandler> logger)
        {
            _bookingRepository = bookingRepository;
            _currentUserService = currentUserService;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<PaginatedResult<BookingDto>> Handle(GetBookingsByPropertyQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام حجوزات الكيان: {PropertyId}, الصفحة: {PageNumber}, الحجم: {PageSize}", request.PropertyId, request.PageNumber, request.PageSize);

            if (request.PropertyId == Guid.Empty)
                return PaginatedResult<BookingDto>.Empty(request.PageNumber, request.PageSize);

            var roles = _currentUserService.UserRoles;
            if (!roles.Contains("Admin") && _currentUserService.PropertyId != request.PropertyId)
                throw new UnauthorizedAccessException("ليس لديك صلاحية لعرض حجوزات هذا الكيان");

            var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
            var pageSize = request.PageSize < 1 ? 10 : request.PageSize;

            var query = _bookingRepository.GetQueryable()
                .AsNoTracking()
                .Include(b => b.User)
                .Include(b => b.Unit).ThenInclude(u => u.Property)
                .Include(b => b.Payments)
                .Where(b => b.Unit.PropertyId == request.PropertyId);

            if (request.UserId.HasValue)
                query = query.Where(b => b.UserId == request.UserId.Value);

            if (request.PropertyTypeId.HasValue)
                query = query.Where(b => b.Unit.Property.TypeId == request.PropertyTypeId.Value);

            if (request.AmenityIds != null && request.AmenityIds.Any())
                query = query.Where(b => request.AmenityIds.All(id => b.Unit.Property.Amenities.Any(a => a.PropertyTypeAmenity.AmenityId == id && a.IsAvailable)));

            if (!string.IsNullOrWhiteSpace(request.Status) && Enum.TryParse<BookingStatus>(request.Status, true, out var statusEnum))
                query = query.Where(b => b.Status == statusEnum);

            if (!string.IsNullOrWhiteSpace(request.PaymentStatusDto) && Enum.TryParse<YemenBooking.Core.Enums.PaymentStatus>(request.PaymentStatusDto, true, out var payStatusEnum))
                query = query.Where(b => b.Payments.Any(p => p.Status == payStatusEnum));

            if (!string.IsNullOrWhiteSpace(request.GuestNameOrEmail))
            {
                var term = request.GuestNameOrEmail.Trim().ToLower();
                query = query.Where(b => b.User.Name.ToLower().Contains(term) || b.User.Email.ToLower().Contains(term));
            }

            if (!string.IsNullOrWhiteSpace(request.BookingSource))
                query = query.Where(b => b.BookingSource == request.BookingSource);

            if (request.IsWalkIn.HasValue)
                query = query.Where(b => b.IsWalkIn == request.IsWalkIn.Value);

            if (request.MinTotalPrice.HasValue)
                query = query.Where(b => b.TotalPrice.Amount >= request.MinTotalPrice.Value);

            if (request.MinGuestsCount.HasValue)
                query = query.Where(b => b.GuestsCount >= request.MinGuestsCount.Value);

            query = request.SortBy?.Trim().ToLower() switch
            {
                "check_in_date" => query.OrderBy(b => b.CheckIn),
                "booking_date" => query.OrderBy(b => b.BookedAt),
                "total_price" => query.OrderBy(b => b.TotalPrice.Amount),
                _ => query.OrderByDescending(b => b.BookedAt)
            };

            var totalCount = await query.CountAsync(cancellationToken);
            var bookings = await query
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var dtos = bookings.Select(b => _mapper.Map<BookingDto>(b)).ToList();
            for (int i = 0; i < dtos.Count; i++)
            {
                dtos[i].BookedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].BookedAt);
                dtos[i].CheckIn = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].CheckIn);
                dtos[i].CheckOut = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].CheckOut);
            }

            _logger.LogInformation("تم جلب {Count} حجز من إجمالي {TotalCount} لحجوزات الكيان: {PropertyId}", dtos.Count, totalCount, request.PropertyId);
            return new PaginatedResult<BookingDto>(dtos, pageNumber, pageSize, totalCount);
        }
    }
} 