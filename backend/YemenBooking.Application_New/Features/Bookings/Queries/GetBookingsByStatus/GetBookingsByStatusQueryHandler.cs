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

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingsByStatus
{
    /// <summary>
    /// معالج استعلام الحصول على الحجوزات حسب الحالة
    /// Query handler for GetBookingsByStatusQuery
    /// </summary>
    public class GetBookingsByStatusQueryHandler : IRequestHandler<GetBookingsByStatusQuery, PaginatedResult<BookingDto>>
    {
        private readonly IBookingRepository _bookingRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;
        private readonly ILogger<GetBookingsByStatusQueryHandler> _logger;

        public GetBookingsByStatusQueryHandler(
            IBookingRepository bookingRepository,
            ICurrentUserService currentUserService,
            IMapper mapper,
            ILogger<GetBookingsByStatusQueryHandler> logger)
        {
            _bookingRepository = bookingRepository;
            _currentUserService = currentUserService;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<PaginatedResult<BookingDto>> Handle(GetBookingsByStatusQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام الحجوزات بالحالة: {Status}, الصفحة: {PageNumber}, الحجم: {PageSize}", request.Status, request.PageNumber, request.PageSize);

            if (!Enum.TryParse<BookingStatus>(request.Status, true, out var statusEnum))
                return PaginatedResult<BookingDto>.Empty(request.PageNumber, request.PageSize);

            var roles = _currentUserService.UserRoles;
            var propertyId = _currentUserService.PropertyId;

            var query = _bookingRepository.GetQueryable()
                .AsNoTracking()
                .Include(b => b.User)
                .Include(b => b.Unit)
                .Where(b => b.Status == statusEnum);

            if (!roles.Contains("Admin"))
            {
                if (propertyId.HasValue)
                    query = query.Where(b => b.Unit.PropertyId == propertyId.Value);
                else
                    throw new UnauthorizedAccessException("ليس لديك صلاحية لعرض الحجوزات حسب الحالة");
            }

            var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
            var pageSize = request.PageSize < 1 ? 10 : request.PageSize;

            var totalCount = await query.CountAsync(cancellationToken);
            var bookings = await query
                .OrderByDescending(b => b.BookedAt)
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
            _logger.LogInformation("تم جلب {Count} حجز من إجمالي {TotalCount} بالحالة: {Status}", dtos.Count, totalCount, request.Status);

            return new PaginatedResult<BookingDto>(dtos, pageNumber, pageSize, totalCount);
        }
    }
} 