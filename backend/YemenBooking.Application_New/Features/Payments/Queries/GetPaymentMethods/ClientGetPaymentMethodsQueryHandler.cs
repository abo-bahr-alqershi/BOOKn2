using MediatR;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using YemenBooking.Application.Features.Payments;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Payments.DTOs;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features;
using YemenBooking.Application.Features.Payments.DTOs;

namespace YemenBooking.Application.Features.Payments.Queries.GetPaymentMethods;

/// <summary>
/// معالج استعلام الحصول على طرق الدفع المتاحة للعميل
/// Handler for client get payment methods query
/// </summary>
public class ClientGetPaymentMethodsQueryHandler : IRequestHandler<ClientGetPaymentMethodsQuery, ResultDto<List<ClientPaymentMethodDto>>>
{
    private readonly IUserRepository _userRepository;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ClientGetPaymentMethodsQueryHandler> _logger;

    /// <summary>
    /// منشئ معالج استعلام طرق الدفع للعميل
    /// Constructor for client get payment methods query handler
    /// </summary>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="configuration">إعدادات التطبيق</param>
    /// <param name="logger">مسجل الأحداث</param>
    public ClientGetPaymentMethodsQueryHandler(
        IUserRepository userRepository,
        IConfiguration configuration,
        ILogger<ClientGetPaymentMethodsQueryHandler> logger)
    {
        _userRepository = userRepository;
        _configuration = configuration;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على طرق الدفع المتاحة للعميل
    /// Handle client get payment methods query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة طرق الدفع المتاحة</returns>
    public async Task<ResultDto<List<ClientPaymentMethodDto>>> Handle(ClientGetPaymentMethodsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام طرق الدفع المتاحة للعميل. معرف المستخدم: {UserId}, البلد: {Country}, العملة: {Currency}, المبلغ: {Amount}", 
                request.UserId, request.Country, request.Currency, request.Amount);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // تحديد البلد إذا لم يتم تحديده
            string userCountry = request.Country ?? "YE"; // اليمن كبلد افتراضي
            
            // إذا تم تحديد معرف المستخدم، جلب بيانات المستخدم
            if (request.UserId.HasValue)
            {
                var user = await _userRepository.GetByIdAsync(request.UserId.Value, cancellationToken);
                if (user != null)
                {
                    userCountry = "YE"; // افتراضي اليمن (سيتم تحديثه لاحقاً)
                }
            }
            
            var countryCode = "YE"; // افتراضي اليمن

            // إرجاع جميع طرق الدفع المتاحة من PaymentMethodEnum
            var availablePaymentMethods = GetAllPaymentMethods(request.Currency, userCountry, request.Amount);

            // ترتيب طرق الدفع
            availablePaymentMethods = availablePaymentMethods
                .OrderByDescending(pm => pm.IsRecommended)
                .ThenBy(pm => pm.DisplayOrder)
                .ThenBy(pm => pm.Name)
                .ToList();

            _logger.LogInformation("تم العثور على {Count} طريقة دفع متاحة", availablePaymentMethods.Count);

            return ResultDto<List<ClientPaymentMethodDto>>.Ok(
                availablePaymentMethods, 
                $"تم العثور على {availablePaymentMethods.Count} طريقة دفع متاحة"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على طرق الدفع المتاحة للعميل");
            return ResultDto<List<ClientPaymentMethodDto>>.Failed(
                $"حدث خطأ أثناء الحصول على طرق الدفع: {ex.Message}", 
                "GET_PAYMENT_METHODS_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<List<ClientPaymentMethodDto>> ValidateRequest(ClientGetPaymentMethodsQuery request)
    {
        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            _logger.LogWarning("العملة مطلوبة");
            return ResultDto<List<ClientPaymentMethodDto>>.Failed("العملة مطلوبة", "CURRENCY_REQUIRED");
        }

        if (request.Currency.Length != 3)
        {
            _logger.LogWarning("رمز العملة يجب أن يكون 3 أحرف");
            return ResultDto<List<ClientPaymentMethodDto>>.Failed("رمز العملة يجب أن يكون 3 أحرف", "INVALID_CURRENCY_CODE");
        }

        if (request.Amount.HasValue && request.Amount.Value < 0)
        {
            _logger.LogWarning("المبلغ لا يمكن أن يكون سالباً");
            return ResultDto<List<ClientPaymentMethodDto>>.Failed("المبلغ لا يمكن أن يكون سالباً", "INVALID_AMOUNT");
        }

        if (request.Amount.HasValue && request.Amount.Value > 10000000) // 10 مليون
        {
            _logger.LogWarning("المبلغ كبير جداً");
            return ResultDto<List<ClientPaymentMethodDto>>.Failed("المبلغ كبير جداً", "AMOUNT_TOO_LARGE");
        }

        return ResultDto<List<ClientPaymentMethodDto>>.Ok(null);
    }

    /// <summary>
    /// الحصول على جميع طرق الدفع المتاحة من PaymentMethodEnum
    /// </summary>
    private List<ClientPaymentMethodDto> GetAllPaymentMethods(string currency, string country, decimal? amount)
    {
        var methods = new List<ClientPaymentMethodDto>();
        
        foreach (PaymentMethodEnum paymentMethod in Enum.GetValues(typeof(PaymentMethodEnum)))
        {
            var methodDto = new ClientPaymentMethodDto
            {
                Id = ((int)paymentMethod).ToString(),
                Name = GetPaymentMethodName(paymentMethod),
                Description = GetPaymentMethodDescription(paymentMethod),
                IconUrl = GetPaymentMethodIcon(paymentMethod),
                LogoUrl = "/images/payment-default.png",
                IsAvailable = true,
                TransactionFee = 0,
                FeePercentage = GetPaymentMethodFeePercentage(paymentMethod),
                MinAmount = 0,
                MaxAmount = 1000000,
                SupportedCurrencies = new List<string> { "YER", "USD" },
                SupportedCountries = new List<string> { "YE" },
                ProcessingTime = "فوري",
                Type = paymentMethod.ToString(),
                RequiresVerification = false,
                SupportsRefunds = true,
                DisplayOrder = (int)paymentMethod,
                IsRecommended = paymentMethod == PaymentMethodEnum.Cash || paymentMethod == PaymentMethodEnum.JwaliWallet,
                WarningMessage = null
            };
            
            methods.Add(methodDto);
        }
        
        return methods;
    }
    
    private string GetPaymentMethodName(PaymentMethodEnum method)
    {
        return method switch
        {
            PaymentMethodEnum.JwaliWallet => "محفظة جوالي",
            PaymentMethodEnum.CashWallet => "محفظة كاش",
            PaymentMethodEnum.OneCashWallet => "محفظة ون كاش",
            PaymentMethodEnum.FloskWallet => "محفظة فلوس",
            PaymentMethodEnum.JaibWallet => "محفظة جيب",
            PaymentMethodEnum.Cash => "نقدي",
            PaymentMethodEnum.Paypal => "PayPal",
            PaymentMethodEnum.CreditCard => "بطاقة ائتمان",
            _ => method.ToString()
        };
    }
    
    private string GetPaymentMethodDescription(PaymentMethodEnum method)
    {
        return method switch
        {
            PaymentMethodEnum.JwaliWallet => "الدفع عبر محفظة جوالي الإلكترونية",
            PaymentMethodEnum.CashWallet => "الدفع عبر محفظة كاش الإلكترونية",
            PaymentMethodEnum.OneCashWallet => "الدفع عبر محفظة ون كاش",
            PaymentMethodEnum.FloskWallet => "الدفع عبر محفظة فلوس",
            PaymentMethodEnum.JaibWallet => "الدفع عبر محفظة جيب",
            PaymentMethodEnum.Cash => "الدفع نقداً عند الوصول",
            PaymentMethodEnum.Paypal => "الدفع عبر PayPal",
            PaymentMethodEnum.CreditCard => "الدفع بالبطاقة الائتمانية",
            _ => "طريقة دفع"
        };
    }
    
    private string GetPaymentMethodIcon(PaymentMethodEnum method)
    {
        return method switch
        {
            PaymentMethodEnum.JwaliWallet => "/images/payment-jwali.png",
            PaymentMethodEnum.CashWallet => "/images/payment-cash.png",
            PaymentMethodEnum.OneCashWallet => "/images/payment-onecash.png",
            PaymentMethodEnum.FloskWallet => "/images/payment-flosk.png",
            PaymentMethodEnum.JaibWallet => "/images/payment-jaib.png",
            PaymentMethodEnum.Cash => "/images/payment-cash.png",
            PaymentMethodEnum.Paypal => "/images/payment-paypal.png",
            PaymentMethodEnum.CreditCard => "/images/payment-card.png",
            _ => "/images/payment-default.png"
        };
    }
    
    private decimal GetPaymentMethodFeePercentage(PaymentMethodEnum method)
    {
        return method switch
        {
            PaymentMethodEnum.CreditCard => 2.5m,
            PaymentMethodEnum.Paypal => 3.0m,
            _ => 0
        };
    }



    /// <summary>
    /// الحصول على طرق دفع افتراضية
    /// Get default payment methods
    /// </summary>
    /// <param name="currency">العملة</param>
    /// <param name="country">البلد</param>
    /// <returns>قائمة طرق الدفع الافتراضية</returns>
    private List<ClientPaymentMethodDto> GetDefaultPaymentMethods(string currency, string country)
    {
        var defaultMethods = new List<ClientPaymentMethodDto>();

        // طرق دفع افتراضية للسوق اليمني
        if (country == "YE")
        {
            defaultMethods.AddRange(new[]
            {
                new ClientPaymentMethodDto
                {
                    Id = "cash_on_delivery",
                    Name = "الدفع عند الاستلام",
                    Description = "ادفع نقداً عند وصولك للعقار",
                    Type = "cash",
                    IsAvailable = true,
                    TransactionFee = 0,
                    FeePercentage = 0,
                    MinAmount = 1,
                    MaxAmount = 1000000,
                    SupportedCurrencies = new List<string> { "YER" },
                    SupportedCountries = new List<string> { "YE" },
                    ProcessingTime = "فوري",
                    SupportsRefunds = true,
                    DisplayOrder = 1,
                    IsRecommended = true
                },
                new ClientPaymentMethodDto
                {
                    Id = "bank_transfer",
                    Name = "تحويل بنكي",
                    Description = "حوّل المبلغ إلى حساب العقار مباشرة",
                    Type = "bank_transfer",
                    IsAvailable = true,
                    TransactionFee = 10,
                    FeePercentage = 0,
                    MinAmount = 100,
                    MaxAmount = 5000000,
                    SupportedCurrencies = new List<string> { "YER", "USD", "SAR" },
                    SupportedCountries = new List<string> { "YE", "SA", "AE" },
                    ProcessingTime = "1-3 أيام عمل",
                    SupportsRefunds = true,
                    DisplayOrder = 2
                },
                new ClientPaymentMethodDto
                {
                    Id = "mobile_wallet",
                    Name = "محفظة موبايل",
                    Description = "ادفع باستخدام محفظتك الرقمية",
                    Type = "digital_wallet",
                    IsAvailable = true,
                    TransactionFee = 5,
                    FeePercentage = 1.5m,
                    MinAmount = 10,
                    MaxAmount = 500000,
                    SupportedCurrencies = new List<string> { "YER" },
                    SupportedCountries = new List<string> { "YE" },
                    ProcessingTime = "فوري",
                    SupportsRefunds = true,
                    DisplayOrder = 3
                }
            });
        }

        // إضافة طرق دفع دولية إذا كانت العملة غير يمنية
        if (currency != "YER")
        {
            defaultMethods.Add(new ClientPaymentMethodDto
            {
                Id = "credit_card",
                Name = "بطاقة ائتمانية",
                Description = "ادفع باستخدام بطاقة فيزا أو ماستركارد",
                Type = "credit_card",
                MinAmount = 1,
                MaxAmount = 50000,
                SupportedCurrencies = new List<string> { "USD", "EUR", "SAR", "AED" },
                SupportedCountries = new List<string> { "YE", "SA", "AE", "US", "GB" },
                ProcessingTime = "فوري",
                RequiresVerification = true,
                SupportsRefunds = true,
                IsRecommended = true
            });
        }

        return defaultMethods;
    }
}
