using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetTermsAndConditions;

/// <summary>
/// معالج استعلام الحصول على الشروط والأحكام
/// Handler for get terms and conditions query
/// </summary>
public class GetTermsAndConditionsQueryHandler : IRequestHandler<GetTermsAndConditionsQuery, ResultDto<LegalDocumentDto>>
{
    private readonly ILegalDocumentRepository _legalDocumentRepository;
    private readonly ILogger<GetTermsAndConditionsQueryHandler> _logger;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج استعلام الشروط والأحكام
    /// Constructor for get terms and conditions query handler
    /// </summary>
    /// <param name="legalDocumentRepository">مستودع المستندات القانونية</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetTermsAndConditionsQueryHandler(
        ILegalDocumentRepository legalDocumentRepository,
        ILogger<GetTermsAndConditionsQueryHandler> logger,
        ICurrentUserService currentUserService)
    {
        _legalDocumentRepository = legalDocumentRepository;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة استعلام الحصول على الشروط والأحكام
    /// Handle get terms and conditions query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>الشروط والأحكام</returns>
    public async Task<ResultDto<LegalDocumentDto>> Handle(GetTermsAndConditionsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام الشروط والأحكام. اللغة: {Language}", request.Language);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // تطبيع اللغة
            var language = NormalizeLanguage(request.Language);

            // الحصول على الشروط والأحكام من قاعدة البيانات
            var termsAndConditions = await _legalDocumentRepository.GetByTypeAndLanguageAsync(
                LegalDocumentType.TermsAndConditions, language, cancellationToken);

            if (termsAndConditions == null)
            {
                _logger.LogWarning("لم يتم العثور على الشروط والأحكام باللغة: {Language}", language);

                // محاولة الحصول على النسخة العربية كبديل
                if (language != "ar")
                {
                    termsAndConditions = await _legalDocumentRepository.GetByTypeAndLanguageAsync(
                        LegalDocumentType.TermsAndConditions, "ar", cancellationToken);
                }

                // إذا لم توجد أي نسخة، إنشاء محتوى افتراضي
                if (termsAndConditions == null)
                {
                    _logger.LogWarning("لم يتم العثور على الشروط والأحكام، إنشاء محتوى افتراضي");
                    
                    var defaultTermsAndConditions = CreateDefaultTermsAndConditions(language);
                    return ResultDto<LegalDocumentDto>.Ok(
                        defaultTermsAndConditions, 
                        "تم إرجاع الشروط والأحكام الافتراضية"
                    );
                }
            }

            // التحقق من أن المستند نشط
            if (!termsAndConditions.IsActive)
            {
                _logger.LogWarning("الشروط والأحكام غير نشطة");
                
                var defaultTermsAndConditions = CreateDefaultTermsAndConditions(language);
                return ResultDto<LegalDocumentDto>.Ok(
                    defaultTermsAndConditions, 
                    "الشروط والأحكام الحالية غير نشطة، تم إرجاع النسخة الافتراضية"
                );
            }

            // إنشاء DTO للاستجابة
            var termsAndConditionsDto = new LegalDocumentDto
            {
                Title = termsAndConditions.Title ?? GetDefaultTitle(language),
                Content = termsAndConditions.Content ?? GetDefaultContent(language),
                Version = termsAndConditions.Version ?? "1.0",
                LastUpdated = await _currentUserService.ConvertFromUtcToUserLocalAsync((termsAndConditions.UpdatedAt ?? termsAndConditions.CreatedAt))
            };

            _logger.LogInformation("تم الحصول على الشروط والأحكام بنجاح. الإصدار: {Version}, آخر تحديث: {LastUpdated}", 
                termsAndConditionsDto.Version, termsAndConditionsDto.LastUpdated);

            return ResultDto<LegalDocumentDto>.Ok(
                termsAndConditionsDto, 
                "تم الحصول على الشروط والأحكام بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على الشروط والأحكام. اللغة: {Language}", request.Language);
            return ResultDto<LegalDocumentDto>.Failed(
                $"حدث خطأ أثناء الحصول على الشروط والأحكام: {ex.Message}", 
                "GET_TERMS_CONDITIONS_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<LegalDocumentDto> ValidateRequest(GetTermsAndConditionsQuery request)
    {
        if (string.IsNullOrWhiteSpace(request.Language))
        {
            _logger.LogWarning("اللغة مطلوبة");
            return ResultDto<LegalDocumentDto>.Failed("اللغة مطلوبة", "LANGUAGE_REQUIRED");
        }

        var normalizedLanguage = NormalizeLanguage(request.Language);
        var supportedLanguages = new[] { "ar", "en" };
        
        if (!supportedLanguages.Contains(normalizedLanguage))
        {
            _logger.LogWarning("اللغة غير مدعومة: {Language}", request.Language);
            return ResultDto<LegalDocumentDto>.Failed(
                $"اللغة '{request.Language}' غير مدعومة. اللغات المدعومة: {string.Join(", ", supportedLanguages)}", 
                "UNSUPPORTED_LANGUAGE"
            );
        }

        return ResultDto<LegalDocumentDto>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// تطبيع اللغة
    /// Normalize language code
    /// </summary>
    /// <param name="language">رمز اللغة</param>
    /// <returns>رمز اللغة المطبع</returns>
    private string NormalizeLanguage(string language)
    {
        return language.ToLowerInvariant().Trim() switch
        {
            "ar" or "arabic" or "عربي" => "ar",
            "en" or "english" or "انجليزي" => "en",
            _ => "ar" // العربية كلغة افتراضية
        };
    }

    /// <summary>
    /// إنشاء شروط وأحكام افتراضية
    /// Create default terms and conditions
    /// </summary>
    /// <param name="language">اللغة</param>
    /// <returns>الشروط والأحكام الافتراضية</returns>
    private LegalDocumentDto CreateDefaultTermsAndConditions(string language)
    {
        var dto = new LegalDocumentDto
        {
            Title = GetDefaultTitle(language),
            Content = GetDefaultContent(language),
            Version = "1.0",
            LastUpdated = DateTime.UtcNow,
        };
        // Convert default LastUpdated for presentation
        dto.LastUpdated = _currentUserService.ConvertFromUtcToUserLocalAsync(dto.LastUpdated).GetAwaiter().GetResult();
        return dto;
    }

    /// <summary>
    /// الحصول على العنوان الافتراضي
    /// Get default title
    /// </summary>
    /// <param name="language">اللغة</param>
    /// <returns>العنوان الافتراضي</returns>
    private string GetDefaultTitle(string language)
    {
        return language switch
        {
            "en" => "Terms and Conditions",
            _ => "الشروط والأحكام"
        };
    }

    /// <summary>
    /// الحصول على المحتوى الافتراضي
    /// Get default content
    /// </summary>
    /// <param name="language">اللغة</param>
    /// <returns>المحتوى الافتراضي</returns>
    private string GetDefaultContent(string language)
    {
        return language switch
        {
            "en" => @"# Terms and Conditions

## Acceptance of Terms
By accessing and using Yemen BookingDto services, you accept and agree to be bound by the terms and provision of this agreement.

## Use License
Permission is granted to temporarily download one copy of Yemen BookingDto materials for personal, non-commercial transitory viewing only.

## Disclaimer
The materials on Yemen BookingDto's website are provided on an 'as is' basis. Yemen BookingDto makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.

## Limitations
In no event shall Yemen BookingDto or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on Yemen BookingDto's website.

## Accuracy of Materials
The materials appearing on Yemen BookingDto's website could include technical, typographical, or photographic errors. Yemen BookingDto does not warrant that any of the materials on its website are accurate, complete, or current.

## Links
Yemen BookingDto has not reviewed all of the sites linked to our website and is not responsible for the contents of any such linked site.

## Modifications
Yemen BookingDto may revise these terms of service for its website at any time without notice. By using this website, you are agreeing to be bound by the then current version of these terms of service.

## Governing Law
These terms and conditions are governed by and construed in accordance with the laws of Yemen and you irrevocably submit to the exclusive jurisdiction of the courts in that State or location.

## Contact Information
If you have any questions about these Terms and Conditions, please contact us at legal@yemenbooking.com.

Last updated: " + DateTime.UtcNow.ToString("yyyy-MM-dd"),

            _ => @"# الشروط والأحكام

## قبول الشروط
من خلال الوصول إلى خدمات يمن بوكنج واستخدامها، فإنك تقبل وتوافق على الالتزام بشروط وأحكام هذه الاتفاقية.

## ترخيص الاستخدام
يُمنح الإذن بتنزيل نسخة واحدة مؤقتة من مواد يمن بوكنج للعرض الشخصي وغير التجاري المؤقت فقط.

## إخلاء المسؤولية
المواد الموجودة على موقع يمن بوكنج مقدمة على أساس 'كما هي'. لا تقدم يمن بوكنج أي ضمانات، صريحة أو ضمنية، وتتنصل بموجب هذا من جميع الضمانات الأخرى بما في ذلك، على سبيل المثال لا الحصر، الضمانات الضمنية أو شروط القابلية للتسويق أو الملاءمة لغرض معين أو عدم انتهاك الملكية الفكرية أو أي انتهاك آخر للحقوق.

## القيود
في أي حال من الأحوال لن تكون يمن بوكنج أو مورديها مسؤولين عن أي أضرار (بما في ذلك، على سبيل المثال لا الحصر، الأضرار الناجمة عن فقدان البيانات أو الربح، أو بسبب انقطاع الأعمال) الناشئة عن استخدام أو عدم القدرة على استخدام المواد الموجودة على موقع يمن بوكنج.

## دقة المواد
قد تتضمن المواد الظاهرة على موقع يمن بوكنج أخطاء تقنية أو مطبعية أو فوتوغرافية. لا تضمن يمن بوكنج أن أي من المواد الموجودة على موقعها دقيقة أو كاملة أو حديثة.

## الروابط
لم تراجع يمن بوكنج جميع المواقع المرتبطة بموقعنا وليست مسؤولة عن محتويات أي موقع مرتبط من هذا القبيل.

## التعديلات
قد تراجع يمن بوكنج شروط الخدمة هذه لموقعها في أي وقت دون إشعار. باستخدام هذا الموقع، فإنك توافق على الالتزام بالإصدار الحالي من شروط الخدمة هذه.

## القانون الحاكم
تخضع هذه الشروط والأحكام وتُفسر وفقاً لقوانين اليمن وأنت تخضع بشكل لا رجعة فيه للاختصاص الحصري للمحاكم في تلك الولاية أو الموقع.

## معلومات الاتصال
إذا كان لديك أي أسئلة حول هذه الشروط والأحكام، يرجى الاتصال بنا على legal@yemenbooking.com.

آخر تحديث: " + DateTime.UtcNow.ToString("yyyy-MM-dd")
        };
    }
}
