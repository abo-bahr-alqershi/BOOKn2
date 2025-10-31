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
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features;
using YemenBooking.Application.Features.Bookings.DTOs;

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingsByUnit
{
    /// <summary>
    /// معالج استعلام الحصول على حجوزات وحدة معينة
    /// Query handler for GetBookingsByUnitQuery
    /// </summary>
    public class GetBookingsByUnitQueryHandler : IRequestHandler<GetBookingsByUnitQuery, PaginatedResult<BookingDto>>
    {
        private readonly IBookingRepository _bookingRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;
        private readonly ILogger<GetBookingsByUnitQueryHandler> _logger;

        public GetBookingsByUnitQueryHandler(
            IBookingRepository bookingRepository,
            ICurrentUserService currentUserService,
            IMapper mapper,
            ILogger<GetBookingsByUnitQueryHandler> logger)
        {
            _bookingRepository = bookingRepository;
            _currentUserService = currentUserService;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<PaginatedResult<BookingDto>> Handle(GetBookingsByUnitQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام حجوزات الوحدة: {UnitId}, الصفحة: {PageNumber}, الحجم: {PageSize}", request.UnitId, request.PageNumber, request.PageSize);

            if (request.UnitId == Guid.Empty)
                return PaginatedResult<BookingDto>.Empty(request.PageNumber, request.PageSize);

            var roles = _currentUserService.UserRoles;
            var propertyId = _currentUserService.PropertyId;
            if (!roles.Contains("Admin") && propertyId.HasValue)
            {
                // التحقق من صلاحية عرض الحجوزات لهذه الوحدة
                // نفترض أن الCurrentUserService.PropertyId يحدد الكيان المملوك
            }

            var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
            var pageSize = request.PageSize < 1 ? 10 : request.PageSize;

            var query = _bookingRepository.GetQueryable()
                .AsNoTracking()
                .Include(b => b.User)
                .Where(b => b.UnitId == request.UnitId);

            if (request.StartDate.HasValue)
            {
                var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.StartDate.Value);
                query = query.Where(b => b.CheckIn >= startUtc);
            }

            if (request.EndDate.HasValue)
            {
                var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.EndDate.Value);
                query = query.Where(b => b.CheckOut <= endUtc);
            }

            query = query.OrderByDescending(b => b.CheckIn);

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

            _logger.LogInformation("تم جلب {Count} حجز من إجمالي {TotalCount} لوحدة: {UnitId}", dtos.Count, totalCount, request.UnitId);
            return new PaginatedResult<BookingDto>(dtos, pageNumber, pageSize, totalCount);
        }
    }
} 