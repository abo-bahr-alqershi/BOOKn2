using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Authentication.Commands.UpdateUser;

/// <summary>
/// أمر تحديث ملف المستخدم للعميل
/// Command to update user profile for client
/// </summary>
public class ClientUpdateUserProfileCommand : IRequest<ResultDto<ClientUserProfileResponse>>
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// الاسم الأول
    /// First name
    /// </summary>
    public string FirstName { get; set; } = string.Empty;

    /// <summary>
    /// الاسم الأخير
    /// Last name
    /// </summary>
    public string LastName { get; set; } = string.Empty;

    /// <summary>
    /// رقم الهاتف
    /// Phone number
    /// </summary>
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// تاريخ الميلاد
    /// Date of birth
    /// </summary>
    public DateTime? DateOfBirth { get; set; }

    /// <summary>
    /// الجنس
    /// Gender
    /// </summary>
    public string? Gender { get; set; }

    /// <summary>
    /// البلد
    /// Country
    /// </summary>
    public string? Country { get; set; }

    /// <summary>
    /// المدينة
    /// City
    /// </summary>
    public string? City { get; set; }

    /// <summary>
    /// العنوان
    /// Address
    /// </summary>
    public string? Address { get; set; }

    /// <summary>
    /// رابط صورة الملف الشخصي
    /// Profile picture URL
    /// </summary>
    public string? ProfilePictureUrl { get; set; }

    /// <summary>
    /// اللغة المفضلة
    /// Preferred language
    /// </summary>
    public string? PreferredLanguage { get; set; }

    /// <summary>
    /// العملة المفضلة
    /// Preferred currency
    /// </summary>
    public string? PreferredCurrency { get; set; }

    /// <summary>
    /// هل يرغب في تلقي التنبيهات
    /// Wants to receive notifications
    /// </summary>
    public bool ReceiveNotifications { get; set; } = true;

    /// <summary>
    /// هل يرغب في تلقي العروض الترويجية
    /// Wants to receive promotional offers
    /// </summary>
    public bool ReceivePromotions { get; set; } = true;
}

/// <summary>
/// استجابة تحديث ملف المستخدم
/// User profile update response
/// </summary>
public class ClientUserProfileResponse
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// الاسم الكامل
    /// Full name
    /// </summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// البريد الإلكتروني
    /// Email
    /// </summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// رقم الهاتف
    /// Phone number
    /// </summary>
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// صورة الملف الشخصي
    /// Profile picture URL
    /// </summary>
    public string? ProfilePictureUrl { get; set; }

    /// <summary>
    /// تاريخ آخر تحديث
    /// Last update date
    /// </summary>
    public DateTime UpdatedAt { get; set; }

    /// <summary>
    /// هل الملف مكتمل
    /// Is profile complete
    /// </summary>
    public bool IsProfileComplete { get; set; }

    /// <summary>
    /// نسبة اكتمال الملف
    /// Profile completion percentage
    /// </summary>
    public decimal CompletionPercentage { get; set; }
}