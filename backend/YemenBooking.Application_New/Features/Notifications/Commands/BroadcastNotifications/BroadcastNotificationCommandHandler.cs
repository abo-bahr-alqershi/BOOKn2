using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using System.Collections.Generic;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Notifications.Services;

namespace YemenBooking.Application.Features.Notifications.Commands.BroadcastNotifications
{
    /// <summary>
    /// معالج بث الإشعارات للمستخدمين المستهدفين
    /// </summary>
    public class BroadcastNotificationCommandHandler : IRequestHandler<BroadcastNotificationCommand, ResultDto<int>>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IUserRepository _userRepository;
        private readonly ILogger<BroadcastNotificationCommandHandler> _logger;
        private readonly INotificationService _notificationService;
        private readonly IFirebaseService _firebaseService;
        private readonly ICurrentUserService _currentUserService;
        private readonly INotificationChannelService _channelService;

        public BroadcastNotificationCommandHandler(
            IUnitOfWork unitOfWork,
            IUserRepository userRepository,
            ILogger<BroadcastNotificationCommandHandler> logger,
            INotificationService notificationService,
            IFirebaseService firebaseService,
            ICurrentUserService currentUserService,
            INotificationChannelService channelService)
        {
            _unitOfWork = unitOfWork;
            _userRepository = userRepository;
            _logger = logger;
            _notificationService = notificationService;
            _firebaseService = firebaseService;
            _currentUserService = currentUserService;
            _channelService = channelService;
        }

        public async Task<ResultDto<int>> Handle(BroadcastNotificationCommand request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.Title) || string.IsNullOrWhiteSpace(request.Message) || string.IsNullOrWhiteSpace(request.Type))
                return ResultDto<int>.Failed("النوع والعنوان والمحتوى مطلوبة");

            // Check if targeting a specific channel
            if (request.TargetChannelId.HasValue)
            {
                // Send notification through channel
                var senderId = _currentUserService.UserId != Guid.Empty ? _currentUserService.UserId : (Guid?)null;
                
                var history = await _channelService.SendChannelNotificationAsync(
                    request.TargetChannelId.Value,
                    request.Title,
                    request.Message,
                    request.Type,
                    senderId,
                    request.Data,
                    cancellationToken);
                
                _logger.LogInformation("تم إرسال الإشعار عبر القناة {ChannelId}. المستلمين: {Recipients}", 
                    request.TargetChannelId.Value, history.RecipientsCount);
                
                return new ResultDto<int> { Success = true, Data = history.RecipientsCount, Message = "تم إرسال الإشعار بنجاح" };
            }
            
            // Resolve recipients
            var recipients = Enumerable.Empty<User>();
            if (request.TargetAllUsers)
            {
                recipients = await _userRepository.GetAllUsersAsync(cancellationToken);
            }
            else if (request.TargetUserIds != null && request.TargetUserIds.Length > 0)
            {
                var ids = request.TargetUserIds.Distinct().ToArray();
                var queryable = _userRepository.GetQueryable();
                recipients = queryable.Where(u => ids.Contains(u.Id)).ToList();
            }
            else if (request.TargetRoles != null && request.TargetRoles.Length > 0)
            {
                var roleNamesLower = request.TargetRoles
                    .Where(r => !string.IsNullOrWhiteSpace(r))
                    .Select(r => r.Trim().ToLowerInvariant())
                    .ToArray();
                var queryable = _userRepository.GetQueryable();
                recipients = queryable
                    .Where(u => u.UserRoles.Any(ur => ur.Role != null && roleNamesLower.Contains(ur.Role.Name.ToLower())))
                    .ToList();
            }
            else
            {
                return ResultDto<int>.Failed("لم يتم تحديد المستلمين");
            }

            var now = DateTime.UtcNow;
            DateTime? scheduledUtc = null;
            if (request.ScheduledFor.HasValue)
            {
                // Convert incoming local schedule time to UTC for storage/processing
                scheduledUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.ScheduledFor.Value);
            }
            var notifications = recipients.Select(u => new Notification
            {
                RecipientId = u.Id,
                Type = request.Type,
                Title = request.Title,
                Message = request.Message,
                Priority = request.Priority,
                Status = request.ScheduledFor.HasValue ? "PENDING" : "PENDING",
                ScheduledFor = scheduledUtc,
                CreatedAt = now
            }).ToList();

            await _unitOfWork.Repository<Notification>().AddRangeAsync(notifications, cancellationToken);
            var inserted = notifications.Count;
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("تم إنشاء {Count} إشعار للبث", inserted);
            // إذا لم يكن هناك موعد مجدول، أرسل الإشعارات فوراً عبر قنواتها (بما فيها FCM)
            if (!request.ScheduledFor.HasValue)
            {
                // إذا كان الهدف جميع المستخدمين، استخدم موضوع "all"
                if (request.TargetAllUsers)
                {
                    var ok = await _firebaseService.SendNotificationAsync("/topics/all", request.Title, request.Message, null, cancellationToken);
                    _logger.LogInformation("تم إرسال بث موضوع all عبر FCM: {Status}", ok);
                    foreach (var n in notifications)
                    {
                        n.MarkAsSent("PUSH");
                        n.MarkAsDelivered();
                    }
                }
                // إذا كانت بواسطة أدوار، أرسل لكل موضوع دور بشكل منفصل لتفادي حدود الرسائل
                else if (request.TargetRoles != null && request.TargetRoles.Length > 0)
                {
                    var roles = request.TargetRoles.Where(r => !string.IsNullOrWhiteSpace(r))
                        .Select(r => r.Trim().ToLowerInvariant())
                        .Distinct()
                        .ToArray();

                    foreach (var role in roles)
                    {
                        var topic = $"/topics/role_{role}";
                        var ok = await _firebaseService.SendNotificationAsync(topic, request.Title, request.Message, null, cancellationToken);
                        _logger.LogInformation("تم إرسال بث دور {Role} عبر FCM: {Status}", role, ok);
                    }

                    foreach (var n in notifications)
                    {
                        n.MarkAsSent("PUSH");
                        n.MarkAsDelivered();
                    }
                }
                // إذا كانت قائمة مستلمين محددين، أرسل لكل مستخدم عبر موضوع user_{id}
                else if (request.TargetUserIds != null && request.TargetUserIds.Length > 0)
                {
                    foreach (var n in notifications)
                    {
                        try
                        {
                            var topic = $"/topics/user_{n.RecipientId}";
                            await _firebaseService.SendNotificationAsync(topic, n.Title, n.Message, null, cancellationToken);
                            n.MarkAsSent("PUSH");
                            n.MarkAsDelivered();
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "فشل إرسال إشعار البث الفوري للمستخدم {UserId}", n.RecipientId);
                            n.MarkAsFailed(ex.Message);
                        }
                    }
                }
                else
                {
                    // fallback: أرسل فردياً كما كان
                    foreach (var n in notifications)
                    {
                        try
                        {
                            await _notificationService.SendAsync(new YemenBooking.Core.Notifications.NotificationRequest
                            {
                                UserId = n.RecipientId,
                                Title = n.Title,
                                Message = n.Message,
                                Type = Enum.TryParse<YemenBooking.Core.Notifications.NotificationType>(n.Type, true, out var t)
                                    ? t : YemenBooking.Core.Notifications.NotificationType.System,
                                Data = null
                            }, cancellationToken);
                            n.MarkAsSent("PUSH");
                            n.MarkAsDelivered();
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "فشل إرسال إشعار البث الفوري للمستخدم {UserId}", n.RecipientId);
                            n.MarkAsFailed(ex.Message);
                        }
                    }
                }
                await _unitOfWork.SaveChangesAsync(cancellationToken);
            }

            return ResultDto<int>.Succeeded(inserted, $"تم إنشاء {inserted} إشعار");
        }
    }
}

