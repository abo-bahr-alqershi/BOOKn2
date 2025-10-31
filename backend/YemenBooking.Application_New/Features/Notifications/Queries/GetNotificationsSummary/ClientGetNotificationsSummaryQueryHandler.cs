using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Notifications.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Notifications.Queries.GetNotificationsSummary;

/// <summary>
/// معالج استعلام ملخص الإشعارات للعميل
/// Handler for client get notifications summary query
/// </summary>
public class ClientGetNotificationsSummaryQueryHandler : IRequestHandler<ClientGetNotificationsSummaryQuery, ResultDto<ClientNotificationsSummaryDto>>
{
    private readonly INotificationRepository _notificationRepository;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<ClientGetNotificationsSummaryQueryHandler> _logger;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج استعلام ملخص الإشعارات
    /// Constructor for client get notifications summary query handler
    /// </summary>
    /// <param name="notificationRepository">مستودع الإشعارات</param>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="logger">مسجل الأحداث</param>
    public ClientGetNotificationsSummaryQueryHandler(
        INotificationRepository notificationRepository,
        IUserRepository userRepository,
        ILogger<ClientGetNotificationsSummaryQueryHandler> logger,
        ICurrentUserService currentUserService)
    {
        _notificationRepository = notificationRepository;
        _userRepository = userRepository;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة استعلام ملخص الإشعارات للعميل
    /// Handle client get notifications summary query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>ملخص الإشعارات</returns>
    public async Task<ResultDto<ClientNotificationsSummaryDto>> Handle(ClientGetNotificationsSummaryQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام ملخص الإشعارات للعميل. معرف المستخدم: {UserId}", request.UserId);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // التحقق من وجود المستخدم
            var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
            if (user == null)
            {
                _logger.LogWarning("لم يتم العثور على المستخدم: {UserId}", request.UserId);
                return ResultDto<ClientNotificationsSummaryDto>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            // الحصول على إحصائيات الإشعارات
            // الحصول على عدد الإشعارات غير المقروءة
            var unreadCount = await _notificationRepository.GetUnreadNotificationsCountAsync(request.UserId, cancellationToken);
            
            // الحصول على جميع الإشعارات للمستخدم (مع تحديد عدد أكبر للحصول على الإحصائيات)
            var allNotifications = (await _notificationRepository.GetUserNotificationsAsync(request.UserId, null, 1, 1000, cancellationToken))
                ?.ToList() ?? new List<Notification>();
            
            var totalCount = allNotifications.Count;
            var readCount = totalCount - unreadCount;

            // إحصائيات حسب النوع
            var countByType = allNotifications
                .GroupBy(n => n.Type ?? "Unknown")
                .ToDictionary(g => g.Key, g => g.Count());

            // إحصائيات حسب الأولوية
            var countByPriority = allNotifications
                .GroupBy(n => n.Priority ?? "MEDIUM")
                .ToDictionary(g => g.Key, g => g.Count());

            // آخر إشعار
            var lastNotification = allNotifications
                .OrderByDescending(n => n.CreatedAt)
                .FirstOrDefault();
            
            ClientNotificationDto? lastNotificationDto = null;
            if (lastNotification != null)
            {
                lastNotificationDto = MapToClientNotificationDto(lastNotification);
                // Localize times for last notification
                lastNotificationDto.CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(lastNotificationDto.CreatedAt);
                if (lastNotificationDto.ReadAt.HasValue)
                    lastNotificationDto.ReadAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(lastNotificationDto.ReadAt.Value);
            }

            // الحصول على الإشعارات عالية الأولوية غير المقروءة
            var highPriorityNotifications = allNotifications
                .Where(n => !n.IsRead && (n.Priority == "HIGH" || n.Priority == "URGENT"))
                .OrderByDescending(n => n.CreatedAt)
                .Take(5)
                .ToList();

            var highPriorityUnreadDtos = highPriorityNotifications
                .Select(MapToClientNotificationDto)
                .ToList();
            for (int i = 0; i < highPriorityUnreadDtos.Count; i++)
            {
                highPriorityUnreadDtos[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(highPriorityUnreadDtos[i].CreatedAt);
                if (highPriorityUnreadDtos[i].ReadAt.HasValue)
                    highPriorityUnreadDtos[i].ReadAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(highPriorityUnreadDtos[i].ReadAt.Value);
            }

            // إنشاء DTO للاستجابة
            var summaryDto = new ClientNotificationsSummaryDto
            {
                TotalCount = totalCount,
                UnreadCount = unreadCount,
                ReadCount = readCount,
                CountByType = countByType,
                CountByPriority = countByPriority,
                LastNotification = lastNotificationDto,
                HighPriorityUnread = highPriorityUnreadDtos
            };

            _logger.LogInformation("تم الحصول على ملخص الإشعارات بنجاح. المستخدم: {UserId}, إجمالي: {Total}, غير مقروء: {Unread}", 
                request.UserId, totalCount, unreadCount);

            return ResultDto<ClientNotificationsSummaryDto>.Ok(
                summaryDto, 
                "تم الحصول على ملخص الإشعارات بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على ملخص الإشعارات. معرف المستخدم: {UserId}", request.UserId);
            return ResultDto<ClientNotificationsSummaryDto>.Failed(
                $"حدث خطأ أثناء الحصول على ملخص الإشعارات: {ex.Message}", 
                "GET_NOTIFICATIONS_SUMMARY_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<ClientNotificationsSummaryDto> ValidateRequest(ClientGetNotificationsSummaryQuery request)
    {
        if (request.UserId == Guid.Empty)
        {
            _logger.LogWarning("معرف المستخدم مطلوب");
            return ResultDto<ClientNotificationsSummaryDto>.Failed("معرف المستخدم مطلوب", "USER_ID_REQUIRED");
        }

        return ResultDto<ClientNotificationsSummaryDto>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// تحويل كيان الإشعار إلى DTO للعميل
    /// Map notification entity to client DTO
    /// </summary>
    /// <param name="notification">كيان الإشعار</param>
    /// <returns>DTO الإشعار للعميل</returns>
    private ClientNotificationDto MapToClientNotificationDto(Notification notification)
    {
        return new ClientNotificationDto
        {
            Id = notification.Id,
            Title = notification.Title ?? string.Empty,
            Content = notification.Message ?? string.Empty,
            Type = notification.Type ?? string.Empty,
            Priority = notification.Priority ?? "MEDIUM",
            IsRead = notification.IsRead,
            CreatedAt = notification.CreatedAt,
            ReadAt = notification.ReadAt,
            IconUrl = null, // يمكن إضافة هذه الخاصية لاحقاً إذا لزم الأمر
            ImageUrl = null, // يمكن إضافة هذه الخاصية لاحقاً إذا لزم الأمر
            AdditionalData = notification.Data,
            ActionUrl = null, // يمكن إضافة هذه الخاصية لاحقاً إذا لزم الأمر
            CanDismiss = notification.CanDismiss
        };
    }
}
