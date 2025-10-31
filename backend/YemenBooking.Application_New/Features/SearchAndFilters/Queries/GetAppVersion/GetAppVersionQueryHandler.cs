using MediatR;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using YemenBooking.Application.Common;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetAppVersion;

/// <summary>
/// معالج استعلام الحصول على معلومات إصدار التطبيق
/// Handler for get app version query
/// </summary>
public class GetAppVersionQueryHandler : IRequestHandler<GetAppVersionQuery, ResultDto<AppVersionDto>>
{
    private readonly IAppVersionRepository _appVersionRepository;
    private readonly IConfiguration _configuration;
    private readonly ILogger<GetAppVersionQueryHandler> _logger;

    /// <summary>
    /// منشئ معالج استعلام إصدار التطبيق
    /// Constructor for get app version query handler
    /// </summary>
    /// <param name="appVersionRepository">مستودع إصدارات التطبيق</param>
    /// <param name="configuration">إعدادات التطبيق</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetAppVersionQueryHandler(
        IAppVersionRepository appVersionRepository,
        IConfiguration configuration,
        ILogger<GetAppVersionQueryHandler> logger)
    {
        _appVersionRepository = appVersionRepository;
        _configuration = configuration;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على معلومات إصدار التطبيق
    /// Handle get app version query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>معلومات إصدار التطبيق</returns>
    public async Task<ResultDto<AppVersionDto>> Handle(GetAppVersionQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام معلومات إصدار التطبيق. المنصة: {Platform}, الإصدار الحالي: {CurrentVersion}", 
                request.Platform, request.CurrentVersion);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // تطبيع اسم المنصة
            var platform = NormalizePlatform(request.Platform);

            // الحصول على معلومات الإصدار من قاعدة البيانات
            var appVersionInfo = await _appVersionRepository.GetLatestVersionAsync(platform, cancellationToken);

            if (appVersionInfo == null)
            {
                _logger.LogWarning("لم يتم العثور على معلومات إصدار للمنصة: {Platform}", platform);
                
                // إرجاع معلومات افتراضية من إعدادات التطبيق
                return GetDefaultVersionInfo(platform, request.CurrentVersion);
            }

            // مقارنة الإصدارات
            bool IsUpdateRequired = false; // قيمة افتراضية - خاصية MinVersion غير متوفرة ?? appVersionInfo.Version);
            bool IsForceUpdate = false; // قيمة افتراضية - طريقة IsVersionLower غير متوفرة;

            // تحديد رابط التحديث حسب المنصة
            var updateUrl = GetUpdateUrl(platform, appVersionInfo.UpdateUrl);

            // إنشاء DTO للاستجابة
            var appVersionDto = new AppVersionDto
            {
                LatestVersion = appVersionInfo.Version,
                MinimumRequiredVersion = "1.0.0", // قيمة افتراضية - خاصية MinVersion غير متوفرة
                UpdateRequired = IsUpdateRequired,
                UpdateAvailable = IsForceUpdate,
                UpdateUrl = updateUrl,
                ReleaseNotes = appVersionInfo.ReleaseNotes ?? string.Empty,
                ReleaseNotesAr = appVersionInfo.ReleaseNotes, // استخدام ReleaseNotes بدلاً من ReleaseNotesAr
            };

            _logger.LogInformation("تم الحصول على معلومات إصدار التطبيق بنجاح. المنصة: {Platform}, تحديث مطلوب: {UpdateRequired}, تحديث متاح: {UpdateAvailable}", 
                platform, IsUpdateRequired, IsForceUpdate);

            var message = IsUpdateRequired 
                ? "تحديث التطبيق مطلوب للمتابعة" 
                : IsForceUpdate 
                    ? "يتوفر تحديث جديد للتطبيق" 
                    : "التطبيق محدث إلى أحدث إصدار";

            return ResultDto<AppVersionDto>.Ok(appVersionDto, message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على معلومات إصدار التطبيق. المنصة: {Platform}", request.Platform);
            return ResultDto<AppVersionDto>.Failed(
                $"حدث خطأ أثناء الحصول على معلومات الإصدار: {ex.Message}", 
                "GET_APP_VERSION_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<AppVersionDto> ValidateRequest(GetAppVersionQuery request)
    {
        if (string.IsNullOrWhiteSpace(request.Platform))
        {
            _logger.LogWarning("اسم المنصة مطلوب");
            return ResultDto<AppVersionDto>.Failed("اسم المنصة مطلوب", "PLATFORM_REQUIRED");
        }

        if (string.IsNullOrWhiteSpace(request.CurrentVersion))
        {
            _logger.LogWarning("الإصدار الحالي مطلوب");
            return ResultDto<AppVersionDto>.Failed("الإصدار الحالي مطلوب", "CURRENT_VERSION_REQUIRED");
        }

        // التحقق من صحة تنسيق الإصدار
        if (!IsValidVersionFormat(request.CurrentVersion))
        {
            _logger.LogWarning("تنسيق الإصدار غير صحيح: {Version}", request.CurrentVersion);
            return ResultDto<AppVersionDto>.Failed("تنسيق الإصدار غير صحيح", "INVALID_VERSION_FORMAT");
        }

        return ResultDto<AppVersionDto>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// تطبيع اسم المنصة
    /// Normalize platform name
    /// </summary>
    /// <param name="platform">اسم المنصة</param>
    /// <returns>اسم المنصة المطبع</returns>
    private string NormalizePlatform(string platform)
    {
        return platform.ToLower().Trim() switch
        {
            "ios" or "iphone" or "ipad" => "iOS",
            "android" => "Android",
            "web" or "website" => "Web",
            _ => platform.Trim()
        };
    }

    /// <summary>
    /// تحليل رقم الإصدار
    /// Parse version number
    /// </summary>
    /// <param name="version">رقم الإصدار</param>
    /// <returns>كائن Version</returns>
    private Version ParseVersion(string version)
    {
        try
        {
            // إزالة أي أحرف غير رقمية باستثناء النقاط
            var cleanVersion = System.Text.RegularExpressions.Regex.Replace(version, @"[^\d\.]", "");
            
            // التأكد من وجود على الأقل رقمين مفصولين بنقطة
            var parts = cleanVersion.Split('.');
            if (parts.Length < 2)
            {
                cleanVersion += ".0";
            }
            if (parts.Length < 3)
            {
                cleanVersion += ".0";
            }

            return new Version(cleanVersion);
        }
        catch
        {
            _logger.LogWarning("فشل في تحليل رقم الإصدار: {Version}", version);
            return new Version("1.0.0");
        }
    }

    /// <summary>
    /// التحقق من صحة تنسيق الإصدار
    /// Check if version format is valid
    /// </summary>
    /// <param name="version">رقم الإصدار</param>
    /// <returns>هل التنسيق صحيح</returns>
    private bool IsValidVersionFormat(string version)
    {
        try
        {
            ParseVersion(version);
            return true;
        }
        catch
        {
            return false;
        }
    }

    /// <summary>
    /// الحصول على رابط التحديث حسب المنصة
    /// Get update URL based on platform
    /// </summary>
    /// <param name="platform">المنصة</param>
    /// <param name="defaultUrl">الرابط الافتراضي</param>
    /// <returns>رابط التحديث</returns>
    private string? GetUpdateUrl(string platform, string? defaultUrl)
    {
        if (!string.IsNullOrWhiteSpace(defaultUrl))
        {
            return defaultUrl;
        }

        return platform switch
        {
            "iOS" => _configuration["AppStore:iOS:UpdateUrl"] ?? "https://apps.apple.com/app/yemen-booking/id123456789",
            "Android" => _configuration["AppStore:Android:UpdateUrl"] ?? "https://play.google.com/store/apps/details?id=com.yemenbooking.app",
            "Web" => _configuration["AppStore:Web:UpdateUrl"] ?? "https://yemenbooking.com",
            _ => null
        };
    }

    /// <summary>
    /// الحصول على معلومات إصدار افتراضية
    /// Get default version information
    /// </summary>
    /// <param name="platform">المنصة</param>
    /// <param name="currentVersion">الإصدار الحالي</param>
    /// <returns>معلومات الإصدار الافتراضية</returns>
    private ResultDto<AppVersionDto> GetDefaultVersionInfo(string platform, string currentVersion)
    {
        var defaultLatestVersion = _configuration[$"DefaultVersions:{platform}:Latest"] ?? "1.0.0";
        var defaultMinimumVersion = _configuration[$"DefaultVersions:{platform}:Minimum"] ?? "1.0.0";

        var current = ParseVersion(currentVersion);
        var latest = ParseVersion(defaultLatestVersion);
        var minimum = ParseVersion(defaultMinimumVersion);

        var appVersionDto = new AppVersionDto
        {
            LatestVersion = defaultLatestVersion,
            MinimumRequiredVersion = defaultMinimumVersion,
            UpdateRequired = current < minimum,
            UpdateAvailable = current < latest,
            UpdateUrl = GetUpdateUrl(platform, null),
            ReleaseNotes = "تحسينات عامة وإصلاح الأخطاء",
            ReleaseNotesAr = "تحسينات عامة وإصلاح الأخطاء"
        };

        return ResultDto<AppVersionDto>.Ok(appVersionDto, "تم إرجاع معلومات الإصدار الافتراضية");
    }
}
