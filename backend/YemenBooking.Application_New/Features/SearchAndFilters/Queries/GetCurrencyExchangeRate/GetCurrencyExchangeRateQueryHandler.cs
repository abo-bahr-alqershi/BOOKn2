using MediatR;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using YemenBooking.Application.Common;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetCurrencyExchangeRate;

/// <summary>
/// معالج استعلام الحصول على سعر صرف العملة
/// Handler for get currency exchange rate query
/// </summary>
public class GetCurrencyExchangeRateQueryHandler : IRequestHandler<GetCurrencyExchangeRateQuery, ResultDto<CurrencyExchangeRateDto>>
{
    private readonly ICurrencyExchangeRepository _currencyExchangeRepository;
    private readonly ICurrencyExchangeService _currencyExchangeService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<GetCurrencyExchangeRateQueryHandler> _logger;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج استعلام سعر صرف العملة
    /// Constructor for get currency exchange rate query handler
    /// </summary>
    /// <param name="currencyExchangeRepository">مستودع أسعار صرف العملات</param>
    /// <param name="currencyExchangeService">خدمة أسعار صرف العملات</param>
    /// <param name="configuration">إعدادات التطبيق</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetCurrencyExchangeRateQueryHandler(
        ICurrencyExchangeRepository currencyExchangeRepository,
        ICurrencyExchangeService currencyExchangeService,
        IConfiguration configuration,
        ILogger<GetCurrencyExchangeRateQueryHandler> logger,
        ICurrentUserService currentUserService)
    {
        _currencyExchangeRepository = currencyExchangeRepository;
        _currencyExchangeService = currencyExchangeService;
        _configuration = configuration;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة استعلام الحصول على سعر صرف العملة
    /// Handle get currency exchange rate query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>سعر صرف العملة</returns>
    public async Task<ResultDto<CurrencyExchangeRateDto>> Handle(GetCurrencyExchangeRateQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام سعر صرف العملة. من: {FromCurrency} إلى: {ToCurrency}, المبلغ: {Amount}", 
                request.FromCurrency, request.ToCurrency, request.Amount);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // تطبيع أسماء العملات
            var fromCurrency = request.FromCurrency.ToUpperInvariant();
            var toCurrency = request.ToCurrency.ToUpperInvariant();

            // إذا كانت العملتان متشابهتان
            if (fromCurrency == toCurrency)
            {
                var sameRateDto = new CurrencyExchangeRateDto
                {
                    FromCurrency = fromCurrency,
                    ToCurrency = toCurrency,
                    ExchangeRate = 1.0m,
                    ConvertedAmount = request.Amount,
                    LastUpdated = await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow)
                };

                _logger.LogInformation("العملتان متشابهتان، إرجاع سعر صرف 1.0");
                return ResultDto<CurrencyExchangeRateDto>.Ok(sameRateDto, "سعر الصرف 1:1 للعملة نفسها");
            }

            // محاولة الحصول على سعر الصرف من قاعدة البيانات أولاً
            var cachedRate = await _currencyExchangeRepository.GetLatestExchangeRateAsync(
                fromCurrency, toCurrency, cancellationToken);

            CurrencyExchangeRateDto exchangeRateDto;

            // التحقق من صلاحية البيانات المحفوظة (خلال آخر 24 ساعة)
            var cacheExpiryHours = _configuration.GetValue<int>("CurrencyExchange:CacheExpiryHours", 24);
            var isCacheValid = cachedRate != null && 
                               cachedRate.LastUpdated > DateTime.UtcNow.AddHours(-cacheExpiryHours);

            if (isCacheValid)
            {
                _logger.LogInformation("استخدام سعر الصرف المحفوظ. آخر تحديث: {LastUpdated}", cachedRate!.LastUpdated);
                
                exchangeRateDto = new CurrencyExchangeRateDto
                {
                    FromCurrency = fromCurrency,
                    ToCurrency = toCurrency,
                    ExchangeRate = cachedRate.Rate,
                    ConvertedAmount = request.Amount.HasValue ? request.Amount.Value * cachedRate.Rate : null,
                    LastUpdated = await _currentUserService.ConvertFromUtcToUserLocalAsync(cachedRate.LastUpdated)
                };
            }
            else
            {
                _logger.LogInformation("سعر الصرف المحفوظ غير صالح أو منتهي الصلاحية، جلب سعر جديد من الخدمة الخارجية");
                
                // جلب سعر صرف جديد من الخدمة الخارجية
                var freshRate = await _currencyExchangeService.GetExchangeRateAsync(
                    fromCurrency, toCurrency, cancellationToken);

                if (freshRate == null)
                {
                    // في حالة فشل الخدمة الخارجية، استخدم السعر المحفوظ إن وجد
                    if (cachedRate != null)
                    {
                        _logger.LogWarning("فشل جلب سعر صرف جديد، استخدام السعر المحفوظ القديم");
                        
                        exchangeRateDto = new CurrencyExchangeRateDto
                        {
                            FromCurrency = fromCurrency,
                            ToCurrency = toCurrency,
                            ExchangeRate = cachedRate.Rate,
                            ConvertedAmount = request.Amount.HasValue ? request.Amount.Value * cachedRate.Rate : null,
                            LastUpdated = await _currentUserService.ConvertFromUtcToUserLocalAsync(cachedRate.LastUpdated)
                        };
                    }
                    else
                    {
                        // استخدام أسعار افتراضية للعملات الشائعة
                        var defaultRate = GetDefaultExchangeRate(fromCurrency, toCurrency);
                        if (defaultRate.HasValue)
                        {
                            _logger.LogWarning("استخدام سعر صرف افتراضي: {Rate}", defaultRate.Value);
                            
                            exchangeRateDto = new CurrencyExchangeRateDto
                            {
                                FromCurrency = fromCurrency,
                                ToCurrency = toCurrency,
                                ExchangeRate = defaultRate.Value,
                                ConvertedAmount = request.Amount.HasValue ? request.Amount.Value * defaultRate.Value : null,
                                LastUpdated = await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow)
                            };
                        }
                        else
                        {
                            _logger.LogError("لم يتم العثور على سعر صرف للعملتين: {FromCurrency} -> {ToCurrency}", 
                                fromCurrency, toCurrency);
                            return ResultDto<CurrencyExchangeRateDto>.Failed(
                                $"لم يتم العثور على سعر صرف للعملتين {fromCurrency} إلى {toCurrency}", 
                                "EXCHANGE_RATE_NOT_FOUND"
                            );
                        }
                    }
                }
                else
                {
                    // حفظ السعر الجديد في قاعدة البيانات
                    await _currencyExchangeRepository.SaveExchangeRateAsync(
                        fromCurrency, toCurrency, freshRate.Value, DateTime.UtcNow, cancellationToken);

                    exchangeRateDto = new CurrencyExchangeRateDto
                    {
                        FromCurrency = fromCurrency,
                        ToCurrency = toCurrency,
                        ExchangeRate = freshRate.Value,
                        ConvertedAmount = request.Amount.HasValue ? request.Amount.Value * freshRate.Value : null,
                        LastUpdated = await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow)
                    };

                    _logger.LogInformation("تم جلب وحفظ سعر صرف جديد: {Rate}", freshRate.Value);
                }
            }

            _logger.LogInformation("تم الحصول على سعر صرف العملة بنجاح. السعر: {Rate}, المبلغ المحول: {ConvertedAmount}", 
                exchangeRateDto.ExchangeRate, exchangeRateDto.ConvertedAmount);

            return ResultDto<CurrencyExchangeRateDto>.Ok(
                exchangeRateDto, 
                "تم الحصول على سعر صرف العملة بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على سعر صرف العملة. من: {FromCurrency} إلى: {ToCurrency}", 
                request.FromCurrency, request.ToCurrency);
            return ResultDto<CurrencyExchangeRateDto>.Failed(
                $"حدث خطأ أثناء الحصول على سعر صرف العملة: {ex.Message}", 
                "GET_EXCHANGE_RATE_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<CurrencyExchangeRateDto> ValidateRequest(GetCurrencyExchangeRateQuery request)
    {
        if (string.IsNullOrWhiteSpace(request.FromCurrency))
        {
            _logger.LogWarning("العملة المصدر مطلوبة");
            return ResultDto<CurrencyExchangeRateDto>.Failed("العملة المصدر مطلوبة", "FROM_CURRENCY_REQUIRED");
        }

        if (string.IsNullOrWhiteSpace(request.ToCurrency))
        {
            _logger.LogWarning("العملة الهدف مطلوبة");
            return ResultDto<CurrencyExchangeRateDto>.Failed("العملة الهدف مطلوبة", "TO_CURRENCY_REQUIRED");
        }

        if (request.FromCurrency.Length != 3 || request.ToCurrency.Length != 3)
        {
            _logger.LogWarning("رمز العملة يجب أن يكون 3 أحرف");
            return ResultDto<CurrencyExchangeRateDto>.Failed("رمز العملة يجب أن يكون 3 أحرف", "INVALID_CURRENCY_CODE");
        }

        if (request.Amount.HasValue && request.Amount.Value < 0)
        {
            _logger.LogWarning("المبلغ لا يمكن أن يكون سالباً");
            return ResultDto<CurrencyExchangeRateDto>.Failed("المبلغ لا يمكن أن يكون سالباً", "INVALID_AMOUNT");
        }

        if (request.Amount.HasValue && request.Amount.Value > 1000000000) // مليار
        {
            _logger.LogWarning("المبلغ كبير جداً");
            return ResultDto<CurrencyExchangeRateDto>.Failed("المبلغ كبير جداً", "AMOUNT_TOO_LARGE");
        }

        return ResultDto<CurrencyExchangeRateDto>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// الحصول على سعر صرف افتراضي للعملات الشائعة
    /// Get default exchange rate for common currencies
    /// </summary>
    /// <param name="fromCurrency">العملة المصدر</param>
    /// <param name="toCurrency">العملة الهدف</param>
    /// <returns>السعر الافتراضي إن وجد</returns>
    private decimal? GetDefaultExchangeRate(string fromCurrency, string toCurrency)
    {
        // أسعار افتراضية تقريبية (يجب تحديثها دورياً)
        var defaultRates = new Dictionary<string, Dictionary<string, decimal>>
        {
            ["YER"] = new Dictionary<string, decimal>
            {
                ["USD"] = 0.004m,  // 1 YER = 0.004 USD (تقريبي)
                ["SAR"] = 0.015m,  // 1 YER = 0.015 SAR (تقريبي)
                ["EUR"] = 0.0037m, // 1 YER = 0.0037 EUR (تقريبي)
                ["GBP"] = 0.0032m  // 1 YER = 0.0032 GBP (تقريبي)
            },
            ["USD"] = new Dictionary<string, decimal>
            {
                ["YER"] = 250m,    // 1 USD = 250 YER (تقريبي)
                ["SAR"] = 3.75m,   // 1 USD = 3.75 SAR
                ["EUR"] = 0.92m,   // 1 USD = 0.92 EUR (تقريبي)
                ["GBP"] = 0.79m    // 1 USD = 0.79 GBP (تقريبي)
            },
            ["SAR"] = new Dictionary<string, decimal>
            {
                ["YER"] = 66.67m,  // 1 SAR = 66.67 YER (تقريبي)
                ["USD"] = 0.267m,  // 1 SAR = 0.267 USD
                ["EUR"] = 0.245m,  // 1 SAR = 0.245 EUR (تقريبي)
                ["GBP"] = 0.211m   // 1 SAR = 0.211 GBP (تقريبي)
            }
        };

        if (defaultRates.ContainsKey(fromCurrency) && 
            defaultRates[fromCurrency].ContainsKey(toCurrency))
        {
            return defaultRates[fromCurrency][toCurrency];
        }

        // محاولة العكس
        if (defaultRates.ContainsKey(toCurrency) && 
            defaultRates[toCurrency].ContainsKey(fromCurrency))
        {
            var reverseRate = defaultRates[toCurrency][fromCurrency];
            return reverseRate > 0 ? 1 / reverseRate : null;
        }

        return null;
    }
}
