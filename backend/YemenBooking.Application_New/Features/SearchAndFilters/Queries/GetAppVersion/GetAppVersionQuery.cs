using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetAppVersion;

/// <summary>
/// استعلام الحصول على معلومات إصدار التطبيق
/// Query to get app version information
/// </summary>
public class GetAppVersionQuery : IRequest<ResultDto<AppVersionDto>>
{
    /// <summary>
    /// نظام التشغيل (iOS, Android)
    /// </summary>
    public string Platform { get; set; } = string.Empty;
    
    /// <summary>
    /// الإصدار الحالي للتطبيق
    /// </summary>
    public string CurrentVersion { get; set; } = string.Empty;
}

/// <summary>
/// بيانات إصدار التطبيق
/// </summary>
public class AppVersionDto
{
    /// <summary>
    /// أحدث إصدار متاح
    /// </summary>
    public string LatestVersion { get; set; } = string.Empty;
    
    /// <summary>
    /// الحد الأدنى المطلوب للإصدار
    /// </summary>
    public string MinimumRequiredVersion { get; set; } = string.Empty;
    
    /// <summary>
    /// هل التحديث مطلوب
    /// </summary>
    public bool UpdateRequired { get; set; }
    
    /// <summary>
    /// هل التحديث متاح
    /// </summary>
    public bool UpdateAvailable { get; set; }
    
    /// <summary>
    /// رابط التحديث
    /// </summary>
    public string? UpdateUrl { get; set; }
    
    /// <summary>
    /// ملاحظات الإصدار
    /// </summary>
    public string? ReleaseNotes { get; set; }
    
    /// <summary>
    /// ملاحظات الإصدار بالعربية
    /// </summary>
    public string? ReleaseNotesAr { get; set; }
}