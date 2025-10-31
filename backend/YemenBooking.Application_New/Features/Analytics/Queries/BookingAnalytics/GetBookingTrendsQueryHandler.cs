using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics
{
    /// <summary>
    /// معالج استعلام اتجاهات الحجوزات
    /// Handler for GetBookingTrendsQuery
    /// </summary>
    public class GetBookingTrendsQueryHandler : IRequestHandler<GetBookingTrendsQuery, IEnumerable<TimeSeriesDataDto>>
    {
        private readonly IBookingRepository _bookingRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetBookingTrendsQueryHandler> _logger;

        public GetBookingTrendsQueryHandler(
            IBookingRepository bookingRepository,
            ICurrentUserService currentUserService,
            ILogger<GetBookingTrendsQueryHandler> logger)
        {
            _bookingRepository = bookingRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<IEnumerable<TimeSeriesDataDto>> Handle(GetBookingTrendsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Processing BookingDto Trends Query for Property {PropertyId} Range {Start} - {End}",
                request.PropertyId, request.Range.StartDate, request.Range.EndDate);

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
                throw new UnauthorizedException("يجب تسجيل الدخول للوصول إلى اتجاهات الحجوزات");
            var role = _currentUserService.Role;
            if (request.PropertyId.HasValue)
            {
                if (role != "Admin" && _currentUserService.PropertyId != request.PropertyId)
                    throw new ForbiddenException("ليس لديك صلاحية لعرض اتجاهات الحجوزات لهذا الكيان");
            }
            else if (role != "Admin")
            {
                throw new ForbiddenException("ليس لديك صلاحية لعرض اتجاهات الحجوزات العامة");
            }

            // Convert incoming range from user local to UTC
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.Range.StartDate);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.Range.EndDate);

            IEnumerable<Booking> bookings;
            if (request.PropertyId.HasValue)
            {
                bookings = await _bookingRepository.GetBookingsByPropertyAsync(
                    request.PropertyId.Value,
                    startUtc,
                    endUtc,
                    cancellationToken);
            }
            else
            {
                bookings = await _bookingRepository.GetBookingsByDateRangeAsync(
                    startUtc,
                    endUtc,
                    cancellationToken);
            }

            // Convert each booking date to user's local date then group
            var localDateCounts = new Dictionary<DateTime, int>();
            foreach (var b in bookings)
            {
                var localDate = (await _currentUserService.ConvertFromUtcToUserLocalAsync(b.BookedAt)).Date;
                if (!localDateCounts.ContainsKey(localDate)) localDateCounts[localDate] = 0;
                localDateCounts[localDate]++;
            }

            var trends = localDateCounts
                .Select(kvp => new TimeSeriesDataDto { Date = kvp.Key, Value = kvp.Value })
                .OrderBy(t => t.Date)
                .ToList();

            return trends;
        }
    }
} 