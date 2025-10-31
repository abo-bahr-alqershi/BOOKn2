using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using System.Text.RegularExpressions;

namespace YemenBooking.Application.Features.Authentication.Commands.UpdateUser;

/// <summary>
/// معالج أمر تحديث ملف المستخدم للعميل
/// Handler for client update user profile command
/// </summary>
public class ClientUpdateUserProfileCommandHandler : IRequestHandler<ClientUpdateUserProfileCommand, ResultDto<ClientUserProfileResponse>>
{
    private readonly IUserRepository _userRepository;
    private readonly IFileUploadService _fileUploadService;
    private readonly ILogger<ClientUpdateUserProfileCommandHandler> _logger;

    /// <summary>
    /// منشئ معالج أمر تحديث ملف المستخدم للعميل
    /// Constructor for client update user profile command handler
    /// </summary>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="fileUploadService">خدمة رفع الملفات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public ClientUpdateUserProfileCommandHandler(
        IUserRepository userRepository,
        IFileUploadService fileUploadService,
        ILogger<ClientUpdateUserProfileCommandHandler> logger)
    {
        _userRepository = userRepository;
        _fileUploadService = fileUploadService;
        _logger = logger;
    }

    /// <summary>
    /// معالجة أمر تحديث ملف المستخدم للعميل
    /// Handle client update user profile command
    /// </summary>
    /// <param name="request">طلب تحديث الملف الشخصي للعميل</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<ClientUserProfileResponse>> Handle(ClientUpdateUserProfileCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء عملية تحديث ملف المستخدم للعميل: {UserId}", request.UserId);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // البحث عن المستخدم
            var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
            if (user == null)
            {
                _logger.LogWarning("لم يتم العثور على المستخدم: {UserId}", request.UserId);
                return ResultDto<ClientUserProfileResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            // تحديث بيانات المستخدم
            await UpdateUserProfile(user, request, cancellationToken);

            // حفظ التغييرات
            user.UpdatedAt = DateTime.UtcNow;
            await _userRepository.UpdateUserAsync(user, cancellationToken);

            _logger.LogInformation("تم تحديث الملف الشخصي بنجاح للمستخدم: {UserId}", request.UserId);

            // إنشاء الاستجابة
            var response = CreateResponse(user);

            return ResultDto<ClientUserProfileResponse>.Ok(response, "تم تحديث الملف الشخصي بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء تحديث الملف الشخصي للعميل: {UserId}", request.UserId);
            return ResultDto<ClientUserProfileResponse>.Failed($"حدث خطأ أثناء تحديث الملف الشخصي: {ex.Message}", "UPDATE_PROFILE_ERROR");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate the input request
    /// </summary>
    /// <param name="request">طلب التحديث</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<ClientUserProfileResponse> ValidateRequest(ClientUpdateUserProfileCommand request)
    {
        if (request.UserId == Guid.Empty)
        {
            _logger.LogWarning("محاولة تحديث ملف شخصي بمعرف مستخدم غير صالح");
            return ResultDto<ClientUserProfileResponse>.Failed("معرف المستخدم غير صالح", "INVALID_USER_ID");
        }

        // التحقق من الاسم الأول
        if (string.IsNullOrWhiteSpace(request.FirstName))
        {
            return ResultDto<ClientUserProfileResponse>.Failed("الاسم الأول مطلوب", "FIRST_NAME_REQUIRED");
        }

        if (request.FirstName.Length < 2 || request.FirstName.Length > 50)
        {
            return ResultDto<ClientUserProfileResponse>.Failed("الاسم الأول يجب أن يكون بين 2 و 50 حرف", "INVALID_FIRST_NAME_LENGTH");
        }

        // التحقق من الاسم الأخير
        if (string.IsNullOrWhiteSpace(request.LastName))
        {
            return ResultDto<ClientUserProfileResponse>.Failed("الاسم الأخير مطلوب", "LAST_NAME_REQUIRED");
        }

        if (request.LastName.Length < 2 || request.LastName.Length > 50)
        {
            return ResultDto<ClientUserProfileResponse>.Failed("الاسم الأخير يجب أن يكون بين 2 و 50 حرف", "INVALID_LAST_NAME_LENGTH");
        }

        // التحقق من رقم الهاتف إذا تم توفيره
        if (!string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            var phoneRegex = new Regex(@"^(\+967|967|0)?[1-9]\d{7,8}$");
            if (!phoneRegex.IsMatch(request.PhoneNumber))
            {
                return ResultDto<ClientUserProfileResponse>.Failed("تنسيق رقم الهاتف غير صحيح", "INVALID_PHONE_FORMAT");
            }
        }

        // التحقق من تاريخ الميلاد إذا تم توفيره
        if (request.DateOfBirth.HasValue)
        {
            var age = DateTime.Now.Year - request.DateOfBirth.Value.Year;
            if (request.DateOfBirth.Value > DateTime.Now.AddYears(-age)) age--;

            if (age < 18 || age > 120)
            {
                return ResultDto<ClientUserProfileResponse>.Failed("العمر يجب أن يكون بين 18 و 120 سنة", "INVALID_AGE");
            }
        }

        // التحقق من الجنس إذا تم توفيره
        if (!string.IsNullOrWhiteSpace(request.Gender))
        {
            var validGenders = new[] { "male", "female", "other", "ذكر", "أنثى", "آخر" };
            if (!validGenders.Contains(request.Gender.ToLower()))
            {
                return ResultDto<ClientUserProfileResponse>.Failed("قيمة الجنس غير صحيحة", "INVALID_GENDER");
            }
        }

        // التحقق من اللغة المفضلة إذا تم توفيرها
        if (!string.IsNullOrWhiteSpace(request.PreferredLanguage))
        {
            var validLanguages = new[] { "ar", "en", "arabic", "english", "عربي", "إنجليزي" };
            if (!validLanguages.Contains(request.PreferredLanguage.ToLower()))
            {
                return ResultDto<ClientUserProfileResponse>.Failed("اللغة المفضلة غير مدعومة", "INVALID_LANGUAGE");
            }
        }

        // التحقق من العملة المفضلة إذا تم توفيرها
        if (!string.IsNullOrWhiteSpace(request.PreferredCurrency))
        {
            var validCurrencies = new[] { "YER", "USD", "SAR", "AED", "EUR" };
            if (!validCurrencies.Contains(request.PreferredCurrency.ToUpper()))
            {
                return ResultDto<ClientUserProfileResponse>.Failed("العملة المفضلة غير مدعومة", "INVALID_CURRENCY");
            }
        }

        return ResultDto<ClientUserProfileResponse>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// تحديث بيانات المستخدم
    /// Update user profile data
    /// </summary>
    /// <param name="user">المستخدم</param>
    /// <param name="request">طلب التحديث</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    private async Task UpdateUserProfile(dynamic user, ClientUpdateUserProfileCommand request, CancellationToken cancellationToken)
    {
        // تحديث الاسم الكامل
        user.Name = $"{request.FirstName.Trim()} {request.LastName.Trim()}";

        // تحديث رقم الهاتف
        if (!string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            user.PhoneNumber = request.PhoneNumber;
        }

        // تحديث تاريخ الميلاد
        if (request.DateOfBirth.HasValue)
        {
            user.DateOfBirth = request.DateOfBirth.Value;
        }

        // تحديث الجنس
        if (!string.IsNullOrWhiteSpace(request.Gender))
        {
            user.Gender = request.Gender;
        }

        // تحديث البلد والمدينة
        if (!string.IsNullOrWhiteSpace(request.Country))
        {
            user.Country = request.Country;
        }

        if (!string.IsNullOrWhiteSpace(request.City))
        {
            user.City = request.City;
        }

        // تحديث العنوان
        if (!string.IsNullOrWhiteSpace(request.Address))
        {
            user.Address = request.Address;
        }

        // تحديث صورة الملف الشخصي
        if (!string.IsNullOrWhiteSpace(request.ProfilePictureUrl))
        {
            user.ProfileImageUrl = request.ProfilePictureUrl;
        }

        // تحديث اللغة المفضلة
        if (!string.IsNullOrWhiteSpace(request.PreferredLanguage))
        {
            user.PreferredLanguage = request.PreferredLanguage;
        }

        // تحديث العملة المفضلة
        if (!string.IsNullOrWhiteSpace(request.PreferredCurrency))
        {
            user.PreferredCurrency = request.PreferredCurrency;
        }

        // تحديث إعدادات التنبيهات
        user.ReceiveNotifications = request.ReceiveNotifications;
        user.ReceivePromotions = request.ReceivePromotions;

        _logger.LogInformation("تم تحديث بيانات المستخدم: {UserId}", request.UserId);
    }

    /// <summary>
    /// إنشاء استجابة التحديث
    /// Create update response
    /// </summary>
    /// <param name="user">المستخدم</param>
    /// <returns>استجابة التحديث</returns>
    private ClientUserProfileResponse CreateResponse(dynamic user)
    {
        // حساب نسبة اكتمال الملف الشخصي
        var completionPercentage = CalculateProfileCompletion(user);

        return new ClientUserProfileResponse
        {
            UserId = user.Id,
            FullName = user.Name,
            Email = user.Email,
            PhoneNumber = user.PhoneNumber,
            ProfilePictureUrl = user.ProfileImageUrl,
            UpdatedAt = user.UpdatedAt,
            IsProfileComplete = completionPercentage >= 80m,
            CompletionPercentage = completionPercentage
        };
    }

    /// <summary>
    /// حساب نسبة اكتمال الملف الشخصي
    /// Calculate profile completion percentage
    /// </summary>
    /// <param name="user">المستخدم</param>
    /// <returns>نسبة الاكتمال</returns>
    private decimal CalculateProfileCompletion(dynamic user)
    {
        var fields = new[]
        {
            !string.IsNullOrWhiteSpace(user.Name),
                        !string.IsNullOrWhiteSpace(user.Email),
            !string.IsNullOrWhiteSpace(user.PhoneNumber),
            user.DateOfBirth != null,
            !string.IsNullOrWhiteSpace(user.Gender),
            !string.IsNullOrWhiteSpace(user.Country),
            !string.IsNullOrWhiteSpace(user.City),
            !string.IsNullOrWhiteSpace(user.ProfileImageUrl),
            user.IsEmailVerified
        };

        var completedFields = fields.Count(f => f);
        return Math.Round((decimal)completedFields / fields.Length * 100, 1);
    }
}
