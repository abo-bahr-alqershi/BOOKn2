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
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Features.Notifications.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Notifications.Queries.GetSystemNotifications
{
    /// <summary>
    /// معالج استعلام الحصول على إشعارات النظام
    /// Handles GetSystemNotificationsQuery and returns paginated system notifications
    /// </summary>
    public class GetSystemNotificationsQueryHandler : IRequestHandler<GetSystemNotificationsQuery, PaginatedResult<NotificationDto>>
    {
        private readonly INotificationRepository _notificationRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetSystemNotificationsQueryHandler> _logger;

        public GetSystemNotificationsQueryHandler(
            INotificationRepository notificationRepository,
            ICurrentUserService currentUserService,
            ILogger<GetSystemNotificationsQueryHandler> logger)
        {
            _notificationRepository = notificationRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<PaginatedResult<NotificationDto>> Handle(GetSystemNotificationsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب إشعارات النظام: الصفحة={Page}, الحجم={Size}", request.PageNumber, request.PageSize);

            if (_currentUserService.Role != "Admin")
            {
                _logger.LogWarning("ليس لدى المستخدم صلاحية الوصول إلى إشعارات النظام");
                throw new ForbiddenException("ليس لديك صلاحية الوصول إلى إشعارات النظام");
            }

            if (request.PageNumber <= 0 || request.PageSize <= 0)
                throw new BusinessRuleException("InvalidPagination", "رقم الصفحة وحجم الصفحة يجب أن يكونا أكبر من صفر");

            // Normalize incoming date filters (user-local -> UTC)
            if (request.SentAfter.HasValue)
                request.SentAfter = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.SentAfter.Value);
            if (request.SentBefore.HasValue)
                request.SentBefore = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.SentBefore.Value);

            Expression<Func<Notification, bool>> predicate = n =>
                (string.IsNullOrEmpty(request.NotificationType) || n.Type == request.NotificationType)
                && (!request.RecipientId.HasValue || n.RecipientId == request.RecipientId.Value)
                && (string.IsNullOrEmpty(request.Status) || n.Status == request.Status)
                && (!request.SentAfter.HasValue || n.CreatedAt >= request.SentAfter.Value)
                && (!request.SentBefore.HasValue || n.CreatedAt <= request.SentBefore.Value);

            // Build query with includes to enrich recipient/sender fields
            var query = _notificationRepository
                .GetQueryable()
                .Where(predicate)
                .Include(n => n.Recipient)
                .Include(n => n.Sender);

            var totalCount = await query.CountAsync(cancellationToken);

            var entities = await query
                .OrderByDescending(n => n.CreatedAt)
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

            // Localize output times (UTC -> user-local)
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