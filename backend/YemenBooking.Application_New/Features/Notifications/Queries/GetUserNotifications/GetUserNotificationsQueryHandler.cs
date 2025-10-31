using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Notifications;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Features.Notifications.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Notifications.Queries.GetUserNotifications
{
    /// <summary>
    /// معالج استعلام الحصول على إشعارات المستخدم
    /// Handles GetUserNotificationsQuery and returns paginated user notifications
    /// </summary>
    public class GetUserNotificationsQueryHandler : IRequestHandler<GetUserNotificationsQuery, PaginatedResult<NotificationDto>>
    {
        private readonly INotificationRepository _notificationRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetUserNotificationsQueryHandler> _logger;

        public GetUserNotificationsQueryHandler(
            INotificationRepository notificationRepository,
            ICurrentUserService currentUserService,
            ILogger<GetUserNotificationsQueryHandler> logger)
        {
            _notificationRepository = notificationRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<PaginatedResult<NotificationDto>> Handle(GetUserNotificationsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب إشعارات المستخدم: {UserId}, Page={Page}, Size={Size}", request.UserId, request.PageNumber, request.PageSize);

            if (request.PageNumber <= 0 || request.PageSize <= 0)
                throw new BusinessRuleException("InvalidPagination", "رقم الصفحة وحجم الصفحة يجب أن يكونا أكبر من صفر");

            if (request.UserId == Guid.Empty)
            {
                _logger.LogWarning("معرف المستخدم غير صالح");
                return PaginatedResult<NotificationDto>.Create(new List<NotificationDto>(), request.PageNumber, request.PageSize, 0);
            }

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                _logger.LogWarning("محاولة الوصول بدون تسجيل دخول");
                return PaginatedResult<NotificationDto>.Create(new List<NotificationDto>(), request.PageNumber, request.PageSize, 0);
            }

            if (currentUser.Id != request.UserId && _currentUserService.Role != "Admin")
            {
                _logger.LogWarning("ليس لدى المستخدم صلاحية للوصول إلى هذه الإشعارات");
                return PaginatedResult<NotificationDto>.Create(new List<NotificationDto>(), request.PageNumber, request.PageSize, 0);
            }

            Expression<Func<Notification, bool>> predicate = n => n.RecipientId == request.UserId;
            if (request.IsRead.HasValue)
                predicate = n => n.RecipientId == request.UserId && n.IsRead == request.IsRead.Value;

            // Include recipient/sender
            var query = _notificationRepository
                .GetQueryable()
                .Where(predicate)
                .Include(n => n.Recipient)
                .Include(n => n.Sender)
                .OrderByDescending(n => n.CreatedAt);

            var totalCount = await query.CountAsync(cancellationToken);
            var entities = await query
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToListAsync(cancellationToken);

            var items = entities.Select(n => new NotificationDto
            {
                Id = n.Id,
                Type = n.Type,
                Title = n.GetTitle("ar"),
                Message = n.GetMessage("ar"),
                Priority = n.Priority,
                Status = n.Status,
                RecipientId = n.RecipientId,
                RecipientName = n.Recipient?.Name ?? string.Empty,
                RecipientEmail = n.Recipient?.Email ?? string.Empty,
                RecipientPhone = n.Recipient?.Phone ?? string.Empty,
                SenderId = n.SenderId,
                SenderName = n.Sender?.Name ?? string.Empty,
                IsRead = n.IsRead,
                ReadAt = n.ReadAt,
                CreatedAt = n.CreatedAt
            }).ToList();

            // Localize times
            for (int i = 0; i < items.Count; i++)
            {
                items[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(items[i].CreatedAt);
                if (items[i].ReadAt.HasValue)
                    items[i].ReadAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(items[i].ReadAt.Value);
            }

            return PaginatedResult<NotificationDto>.Create(items, request.PageNumber, request.PageSize, totalCount);
        }
    }
} 