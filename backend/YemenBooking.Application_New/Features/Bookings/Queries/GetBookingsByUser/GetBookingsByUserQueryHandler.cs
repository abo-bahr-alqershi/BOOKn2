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

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingsByUser
{
    /// <summary>
    /// معالج استعلام الحصول على حجوزات مستخدم محدد
    /// Retrieves paginated list of bookings for a specific user
    /// </summary>
    public class GetBookingsByUserQueryHandler : IRequestHandler<GetBookingsByUserQuery, PaginatedResult<BookingDto>>
    {
        private readonly IBookingRepository _bookingRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IMapper _mapper;
        private readonly ILogger<GetBookingsByUserQueryHandler> _logger;

        public GetBookingsByUserQueryHandler(
            IBookingRepository bookingRepository,
            ICurrentUserService currentUserService,
            IMapper mapper,
            ILogger<GetBookingsByUserQueryHandler> logger)
        {
            _bookingRepository = bookingRepository;
            _currentUserService = currentUserService;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<PaginatedResult<BookingDto>> Handle(GetBookingsByUserQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام حجوزات المستخدم: {UserId}, الصفحة: {PageNumber}, الحجم: {PageSize}", request.UserId, request.PageNumber, request.PageSize);

            // صحة معاملات الصفحة
            var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
            var pageSize = request.PageSize < 1 ? 10 : request.PageSize;

            // التحقق من الصلاحيات: المستخدم نفسه أو المسؤول
            var currentUserId = _currentUserService.UserId;
            var userRoles = _currentUserService.UserRoles;
            if (currentUserId != request.UserId && !userRoles.Contains("Admin"))
            {
                throw new UnauthorizedAccessException("ليس لديك صلاحية لعرض حجوزات هذا المستخدم");
            }

            // بناء الاستعلام الأساسي
            var query = _bookingRepository.GetQueryable()
                .AsNoTracking()
                .Include(b => b.User)
                .Include(b => b.Unit)
                .Where(b => b.UserId == request.UserId);

            // تطبيق الفلاتر الاختيارية
            if (!string.IsNullOrWhiteSpace(request.Status))
            {
                if (Enum.TryParse<BookingStatus>(request.Status, true, out var statusEnum))
                    query = query.Where(b => b.Status == statusEnum);
                else
                    throw new ArgumentException("حالة الحجز غير صالحة", nameof(request.Status));
            }

            if (request.UnitId.HasValue)
                query = query.Where(b => b.UnitId == request.UnitId.Value);

            if (!string.IsNullOrWhiteSpace(request.GuestNameOrEmail))
            {
                var term = request.GuestNameOrEmail.Trim().ToLower();
                query = query.Where(b => b.User.Name.ToLower().Contains(term)
                                      || b.User.Email.ToLower().Contains(term));
            }

            if (!string.IsNullOrWhiteSpace(request.BookingSource))
                query = query.Where(b => b.BookingSource == request.BookingSource);

            if (request.IsWalkIn.HasValue)
                query = query.Where(b => b.IsWalkIn == request.IsWalkIn.Value);

            if (request.MinTotalPrice.HasValue)
                query = query.Where(b => b.TotalPrice.Amount >= request.MinTotalPrice.Value);

            if (request.MinGuestsCount.HasValue)
                query = query.Where(b => b.GuestsCount >= request.MinGuestsCount.Value);

            // تطبيق الترتيب
            query = request.SortBy?.Trim().ToLower() switch
            {
                "check_in_date" => query.OrderBy(b => b.CheckIn),
                "booking_date"   => query.OrderBy(b => b.BookedAt),
                "total_price"    => query.OrderBy(b => b.TotalPrice.Amount),
                _                 => query.OrderByDescending(b => b.BookedAt)
            };

            // تنفيذ العد والتصفح
            var totalCount = await query.CountAsync(cancellationToken);
            var bookings = await query
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            // التحويل إلى DTO
            var dtos = bookings.Select(b => _mapper.Map<BookingDto>(b)).ToList();
            for (int i = 0; i < dtos.Count; i++)
            {
                dtos[i].BookedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].BookedAt);
                dtos[i].CheckIn = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].CheckIn);
                dtos[i].CheckOut = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].CheckOut);
            }

            _logger.LogInformation("تم جلب {Count} حجز من إجمالي {TotalCount} للمستخدم: {UserId}", dtos.Count, totalCount, request.UserId);

            return new PaginatedResult<BookingDto>
            {
                Items = dtos,
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalCount = totalCount
            };
        }
    }
} 