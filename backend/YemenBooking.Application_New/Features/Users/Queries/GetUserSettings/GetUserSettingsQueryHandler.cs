using MediatR;
using Microsoft.Extensions.Logging;
// using YemenBooking.Application.Features.Settings; // غير موجود
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Users.Queries.GetUserSettings;

/// <summary>
/// معالج استعلام الحصول على إعدادات المستخدم
/// Handler for get user settings query
/// </summary>
public class GetUserSettingsQueryHandler : IRequestHandler<GetUserSettingsQuery, ResultDto<UserSettingsDto>>
{
    private readonly IUserSettingsRepository _userSettingsRepository;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<GetUserSettingsQueryHandler> _logger;

    /// <summary>
    /// منشئ معالج استعلام إعدادات المستخدم
    /// Constructor for get user settings query handler
    /// </summary>
    /// <param name="userSettingsRepository">مستودع إعدادات المستخدم</param>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetUserSettingsQueryHandler(
        IUserSettingsRepository userSettingsRepository,
        IUserRepository userRepository,
        ILogger<GetUserSettingsQueryHandler> logger)
    {
        _userSettingsRepository = userSettingsRepository;
        _userRepository = userRepository;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على إعدادات المستخدم
    /// Handle get user settings query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>إعدادات المستخدم</returns>
    public async Task<ResultDto<UserSettingsDto>> Handle(GetUserSettingsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام إعدادات المستخدم. معرف المستخدم: {UserId}", request.UserId);

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
                return ResultDto<UserSettingsDto>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            // الحصول على إعدادات المستخدم
            var userSettings = await _userSettingsRepository.GetByUserIdAsync(request.UserId, cancellationToken);

            // إنشاء إعدادات افتراضية إذا لم توجد
            if (userSettings == null)
            {
                _logger.LogInformation("لم يتم العثور على إعدادات للمستخدم {UserId}، سيتم إرجاع الإعدادات الافتراضية", request.UserId);
                
                var defaultSettings = CreateDefaultSettings();
                
                return ResultDto<UserSettingsDto>.Ok(
                    defaultSettings, 
                    "تم إرجاع الإعدادات الافتراضية"
                );
            }

            // تحويل البيانات إلى DTO مع fallback لقراءة SettingsJson من جدول المستخدم عند غياب UserSettings
            var userSettingsDto = new UserSettingsDto
            {
                PreferredLanguage = userSettings.PreferredLanguage ?? "ar",
                PreferredCurrency = userSettings.PreferredCurrency ?? "YER",
                TimeZone = userSettings.TimeZone ?? "Asia/Aden",
                DarkMode = userSettings.DarkMode,
                NotificationSettings = new NotificationSettingsDto
                {
                    BookingNotifications = userSettings.BookingNotifications,
                    PromotionalNotifications = userSettings.PromotionalNotifications,
                    EmailNotifications = userSettings.EmailNotifications,
                    SmsNotifications = userSettings.SmsNotifications,
                    PushNotifications = userSettings.PushNotifications
                },
                AdditionalSettings = userSettings.AdditionalSettings ?? new Dictionary<string, object>()
            };

            // Ensure biometricEnabled key exists in additional settings for clients
            if (!userSettingsDto.AdditionalSettings.ContainsKey("biometricEnabled"))
            {
                userSettingsDto.AdditionalSettings["biometricEnabled"] = false;
            }

            _logger.LogInformation("تم الحصول على إعدادات المستخدم بنجاح. معرف المستخدم: {UserId}", request.UserId);

            return ResultDto<UserSettingsDto>.Ok(
                userSettingsDto, 
                "تم الحصول على إعدادات المستخدم بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على إعدادات المستخدم. معرف المستخدم: {UserId}", request.UserId);
            return ResultDto<UserSettingsDto>.Failed(
                $"حدث خطأ أثناء الحصول على إعدادات المستخدم: {ex.Message}", 
                "GET_USER_SETTINGS_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<UserSettingsDto> ValidateRequest(GetUserSettingsQuery request)
    {
        if (request.UserId == Guid.Empty)
        {
            _logger.LogWarning("معرف المستخدم مطلوب");
            return ResultDto<UserSettingsDto>.Failed("معرف المستخدم مطلوب", "USER_ID_REQUIRED");
        }

        return ResultDto<UserSettingsDto>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// إنشاء إعدادات افتراضية
    /// Create default settings
    /// </summary>
    /// <returns>الإعدادات الافتراضية</returns>
    private UserSettingsDto CreateDefaultSettings()
    {
        return new UserSettingsDto
        {
            PreferredLanguage = "ar",
            PreferredCurrency = "YER",
            TimeZone = "Asia/Aden",
            DarkMode = false,
            NotificationSettings = new NotificationSettingsDto
            {
                BookingNotifications = true,
                PromotionalNotifications = true,
                EmailNotifications = true,
                SmsNotifications = false,
                PushNotifications = true
            },
            AdditionalSettings = new Dictionary<string, object>
            {
                { "AutoSave", true },
                { "ShowTips", true },
                { "DataSaver", false },
                { "LocationServices", true }
            }
        };
    }
}
