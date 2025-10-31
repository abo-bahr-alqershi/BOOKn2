using MediatR;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Notifications;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Entities;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Notifications.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Notifications.Queries.GetUserNotifications;

/// <summary>
/// معالج استعلام الحصول على إشعارات المستخدم للعميل
/// Handler for client get user notifications query
/// </summary>
public class ClientGetUserNotificationsQueryHandler : IRequestHandler<ClientGetUserNotificationsQuery, ResultDto<PaginatedResult<ClientNotificationDto>>>
{
    private readonly INotificationRepository _notificationRepository;
    private readonly IUserRepository _userRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<ClientGetUserNotificationsQueryHandler> _logger;

    public ClientGetUserNotificationsQueryHandler(
        INotificationRepository notificationRepository,
        IUserRepository userRepository,
        ILogger<ClientGetUserNotificationsQueryHandler> logger,
        ICurrentUserService currentUserService)
    {
        _notificationRepository = notificationRepository;
        _userRepository = userRepository;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على إشعارات المستخدم
    /// Handle get user notifications query
    /// </summary>
    /// <param name="request">الطلب</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة مُقسمة من الإشعارات</returns>
    public async Task<ResultDto<PaginatedResult<ClientNotificationDto>>> Handle(ClientGetUserNotificationsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام إشعارات المستخدم. معرف المستخدم: {UserId}", request.UserId);

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
                return ResultDto<PaginatedResult<ClientNotificationDto>>.Failed(
                    "المستخدم غير موجود",
                    "USER_NOT_FOUND");
            }

            // بناء الاستعلام مع جميع الفلاتر قبل التقطيع والعد
            var query = _notificationRepository
                .GetQueryable()
                .Where(n => n.RecipientId == request.UserId && !n.IsDismissed);

            if (!string.IsNullOrWhiteSpace(request.Type))
            {
                var t = request.Type!.Trim();
                query = query.Where(n => n.Type == t);
            }

            if (!string.IsNullOrWhiteSpace(request.Status))
            {
                var status = request.Status!.Trim().ToLower();
                if (status == "read") query = query.Where(n => n.IsRead);
                else if (status == "unread") query = query.Where(n => !n.IsRead);
            }

            if (request.UnreadOnly == true)
            {
                query = query.Where(n => !n.IsRead);
            }

            if (request.FromDate.HasValue)
            {
                var fromUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.FromDate.Value);
                query = query.Where(n => n.CreatedAt >= fromUtc);
            }

            if (request.ToDate.HasValue)
            {
                var toUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.ToDate.Value);
                query = query.Where(n => n.CreatedAt <= toUtc);
            }

            var totalCount = await query.CountAsync(cancellationToken);

            var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
            var pageSize = request.PageSize < 1 ? 20 : request.PageSize;

            var items = await query
                .OrderByDescending(n => n.CreatedAt)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var notificationDtos = items.Select(MapToClientNotificationDto).ToList();
            for (int i = 0; i < notificationDtos.Count; i++)
            {
                notificationDtos[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(notificationDtos[i].CreatedAt);
                if (notificationDtos[i].ReadAt.HasValue)
                    notificationDtos[i].ReadAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(notificationDtos[i].ReadAt.Value);
            }

            var paginatedResult = new PaginatedResult<ClientNotificationDto>
            {
                Items = notificationDtos,
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize,
            };

            _logger.LogInformation("تم الحصول على {Count} إشعار للمستخدم: {UserId}",
                notificationDtos.Count, request.UserId);

            return ResultDto<PaginatedResult<ClientNotificationDto>>.Ok(
                paginatedResult,
                "تم الحصول على الإشعارات بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على إشعارات المستخدم: {UserId}", request.UserId);
            return ResultDto<PaginatedResult<ClientNotificationDto>>.Failed(
                $"حدث خطأ أثناء جلب الإشعارات: {ex.Message}",
                "GET_USER_NOTIFICATIONS_ERROR");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<PaginatedResult<ClientNotificationDto>> ValidateRequest(ClientGetUserNotificationsQuery request)
    {
        if (request.UserId == Guid.Empty)
        {
            _logger.LogWarning("معرف المستخدم مطلوب");
            return ResultDto<PaginatedResult<ClientNotificationDto>>.Failed(
                "معرف المستخدم مطلوب", 
                "USER_ID_REQUIRED");
        }

        if (request.PageNumber < 1)
        {
            _logger.LogWarning("رقم الصفحة يجب أن يكون 1 أو أكبر");
            return ResultDto<PaginatedResult<ClientNotificationDto>>.Failed(
                "رقم الصفحة يجب أن يكون 1 أو أكبر", 
                "INVALID_PAGE_NUMBER");
        }

        if (request.PageSize < 1 || request.PageSize > 100)
        {
            _logger.LogWarning("حجم الصفحة يجب أن يكون بين 1 و 100");
            return ResultDto<PaginatedResult<ClientNotificationDto>>.Failed(
                "حجم الصفحة يجب أن يكون بين 1 و 100", 
                "INVALID_PAGE_SIZE");
        }

        if (request.FromDate.HasValue && request.ToDate.HasValue && request.FromDate >= request.ToDate)
        {
            _logger.LogWarning("تاريخ البداية يجب أن يكون قبل تاريخ النهاية");
            return ResultDto<PaginatedResult<ClientNotificationDto>>.Failed(
                "تاريخ البداية يجب أن يكون قبل تاريخ النهاية", 
                "INVALID_DATE_RANGE");
        }

        return ResultDto<PaginatedResult<ClientNotificationDto>>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// تطبيق الفلاتر على الإشعارات
    /// Apply filters to notifications
    /// </summary>
    /// <param name="notifications">قائمة الإشعارات</param>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>الإشعارات المفلترة</returns>
    private List<Notification> ApplyFilters(List<Notification> notifications, ClientGetUserNotificationsQuery request)
    {
        // لم تعد مستخدمة في المسار الرئيسي، تُترك للاستخدام المستقبلي أو للاختبارات
        var query = notifications.AsQueryable();
        if (!string.IsNullOrEmpty(request.Type))
            query = query.Where(n => n.Type == request.Type);
        if (request.FromDate.HasValue)
            query = query.Where(n => n.CreatedAt >= request.FromDate.Value);
        if (request.ToDate.HasValue)
            query = query.Where(n => n.CreatedAt <= request.ToDate.Value);
        if (!string.IsNullOrWhiteSpace(request.Status))
        {
            var status = request.Status!.Trim().ToLower();
            if (status == "read") query = query.Where(n => n.IsRead);
            else if (status == "unread") query = query.Where(n => !n.IsRead);
        }
        if (request.UnreadOnly == true)
            query = query.Where(n => !n.IsRead);
        return query.OrderByDescending(n => n.CreatedAt).ToList();
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