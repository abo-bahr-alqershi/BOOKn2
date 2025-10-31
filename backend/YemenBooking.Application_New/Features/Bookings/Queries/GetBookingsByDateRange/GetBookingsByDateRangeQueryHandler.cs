using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Bookings.DTOs;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingsByDateRange
{
    /// <summary>
    /// معالج استعلام الحصول على الحجوزات ضمن نطاق زمني
    /// Query handler for GetBookingsByDateRangeQuery
    /// </summary>
    public class GetBookingsByDateRangeQueryHandler : IRequestHandler<GetBookingsByDateRangeQuery, PaginatedResult<BookingDto>>
    {
        private readonly IBookingRepository _bookingRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;
        private readonly ILogger<GetBookingsByDateRangeQueryHandler> _logger;

        public GetBookingsByDateRangeQueryHandler(
            IBookingRepository bookingRepository,
            ICurrentUserService currentUserService,
            IMapper mapper,
            ILogger<GetBookingsByDateRangeQueryHandler> logger)
        {
            _bookingRepository = bookingRepository;
            _currentUserService = currentUserService;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<PaginatedResult<BookingDto>> Handle(GetBookingsByDateRangeQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام الحجوزات من {StartDate} إلى {EndDate}, الصفحة: {PageNumber}, الحجم: {PageSize}",
                request.StartDate, request.EndDate, request.PageNumber, request.PageSize);

            if (request.EndDate < request.StartDate)
                return PaginatedResult<BookingDto>.Empty(request.PageNumber, request.PageSize);

            var roles = _currentUserService.UserRoles;
            var propertyId = _currentUserService.PropertyId;

            var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
            var pageSize = request.PageSize < 1 ? 10 : request.PageSize;

            // Normalize incoming range to UTC for querying
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.StartDate);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.EndDate);

            var query = _bookingRepository.GetQueryable()
                .AsNoTracking()
                .Include(b => b.User)
                .Include(b => b.Unit)
                .Where(b => b.BookedAt >= startUtc && b.BookedAt <= endUtc);

            if (!roles.Contains("Admin") && propertyId.HasValue)
            {
                // للملاك أو الموظفين، عرض الحجوزات المتعلقة بالكيان فقط
                query = query.Where(b => b.Unit.PropertyId == propertyId.Value);
            }

            if (request.UserId.HasValue)
                query = query.Where(b => b.UserId == request.UserId.Value);

            if (!string.IsNullOrWhiteSpace(request.GuestNameOrEmail))
            {
                var term = request.GuestNameOrEmail.Trim().ToLower();
                query = query.Where(b => b.User.Name.ToLower().Contains(term)
                                      || b.User.Email.ToLower().Contains(term));
            }

            if (request.UnitId.HasValue)
                query = query.Where(b => b.UnitId == request.UnitId.Value);

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

            // Convert outgoing DateTimes to user's local time
            for (int i = 0; i < dtos.Count; i++)
            {
                dtos[i].BookedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].BookedAt);
                dtos[i].CheckIn = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].CheckIn);
                dtos[i].CheckOut = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].CheckOut);
            }

            _logger.LogInformation("تم جلب {Count} حجز من إجمالي {TotalCount} ضمن النطاق الزمني", dtos.Count, totalCount);
            var result = new PaginatedResult<BookingDto>(dtos, pageNumber, pageSize, totalCount);
            if (pageNumber == 1)
            {
                var successful = await query.CountAsync(b => b.Status == BookingStatus.Confirmed, cancellationToken);
                var pending = await query.CountAsync(b => b.Status == BookingStatus.Pending, cancellationToken);
                var cancelled = await query.CountAsync(b => b.Status == BookingStatus.Cancelled, cancellationToken);
                result.Metadata = new
                {
                    totalBookings = totalCount,
                    successfulBookings = successful,
                    pendingBookings = pending,
                    cancelledBookings = cancelled
                };
            }
            return result;
        }
    }
} 