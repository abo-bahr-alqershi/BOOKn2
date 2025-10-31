using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Commands;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Commands.NotificationSettings;

/// <summary>
/// معالج أمر تحديث إعدادات الإشعارات للمستخدم (موبايل)
/// </summary>
public class UpdateNotificationSettingsCommandHandler : IRequestHandler<UpdateNotificationSettingsCommand, UpdateNotificationSettingsResponse>
{
    private readonly IUserRepository _userRepository;
    private readonly IUserSettingsRepository _userSettingsRepository;
    private readonly ILogger<UpdateNotificationSettingsCommandHandler> _logger;

    public UpdateNotificationSettingsCommandHandler(IUserRepository userRepository, IUserSettingsRepository userSettingsRepository, ILogger<UpdateNotificationSettingsCommandHandler> logger)
    {
        _userRepository = userRepository;
        _userSettingsRepository = userSettingsRepository;
        _logger = logger;
    }

    public async Task<UpdateNotificationSettingsResponse> Handle(UpdateNotificationSettingsCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("تحديث إعدادات الإشعارات للمستخدم {UserId}", request.UserId);

        var user = await _userRepository.GetUserByIdAsync(request.UserId, cancellationToken);
        if (user == null)
            return new UpdateNotificationSettingsResponse { Success = false, Message = "المستخدم غير موجود" };

        // 1) حفظ الإعدادات بصيغة JSON داخل المستخدم لضمان التوافق القديم
        var jsonSettings = new
        {
            request.BookingNotifications,
            request.PromotionalNotifications,
            request.ReviewResponseNotifications,
            request.EmailNotifications,
            request.SmsNotifications,
            request.PushNotifications
        };
        user.SettingsJson = System.Text.Json.JsonSerializer.Serialize(jsonSettings);
        await _userRepository.UpdateUserAsync(user, cancellationToken);

        // 2) تحديث/إنشاء سجل UserSettings ليتم قراءته من /api/client/settings
        var existing = await _userSettingsRepository.GetByUserIdAsync(request.UserId, cancellationToken);
        if (existing == null)
        {
            var newSettings = new UserSettings
            {
                Id = Guid.NewGuid(),
                UserId = request.UserId,
                PreferredLanguage = "ar",
                PreferredCurrency = "YER",
                TimeZone = "Asia/Aden",
                DarkMode = false,
                BookingNotifications = request.BookingNotifications,
                PromotionalNotifications = request.PromotionalNotifications,
                EmailNotifications = request.EmailNotifications,
                SmsNotifications = request.SmsNotifications,
                PushNotifications = request.PushNotifications,
                AdditionalSettings = new Dictionary<string, object>(),
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            await _userSettingsRepository.CreateAsync(newSettings, cancellationToken);
        }
        else
        {
            existing.BookingNotifications = request.BookingNotifications;
            existing.PromotionalNotifications = request.PromotionalNotifications;
            existing.EmailNotifications = request.EmailNotifications;
            existing.SmsNotifications = request.SmsNotifications;
            existing.PushNotifications = request.PushNotifications;
            existing.UpdatedAt = DateTime.UtcNow;
            await _userSettingsRepository.UpdateAsync(existing, cancellationToken);
        }

        return new UpdateNotificationSettingsResponse { Success = true, Message = "تم التحديث بنجاح" };
    }
}
