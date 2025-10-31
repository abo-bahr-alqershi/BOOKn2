using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Payments.Queries.GetPaymentMethods;

/// <summary>
/// استعلام جلب طرق الدفع المتاحة للعميل
/// Query to get available payment methods for client
/// </summary>
public class ClientGetPaymentMethodsQuery : IRequest<ResultDto<List<ClientPaymentMethodDto>>>
{
    /// <summary>
    /// معرف المستخدم (اختياري)
    /// User ID (optional)
    /// </summary>
    public Guid? UserId { get; set; }

    /// <summary>
    /// البلد (لتحديد طرق الدفع المتاحة)
    /// Country (to determine available payment methods)
    /// </summary>
    public string? Country { get; set; }

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = "YER";

    /// <summary>
    /// المبلغ (لتحديد طرق الدفع المتاحة حسب المبلغ)
    /// Amount (to determine available methods based on amount)
    /// </summary>
    public decimal? Amount { get; set; }
}

/// <summary>
/// بيانات طريقة الدفع للعميل
/// Client payment method data
/// </summary>
public class ClientPaymentMethodDto
{
    /// <summary>
    /// معرف طريقة الدفع
    /// Payment method ID
    /// </summary>
    public string Id { get; set; } = string.Empty;

    /// <summary>
    /// اسم طريقة الدفع
    /// Payment method name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// الوصف
    /// Description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// أيقونة طريقة الدفع
    /// Payment method icon
    /// </summary>
    public string IconUrl { get; set; } = string.Empty;

    /// <summary>
    /// شعار طريقة الدفع
    /// Payment method logo
    /// </summary>
    public string LogoUrl { get; set; } = string.Empty;

    /// <summary>
    /// هل متاحة
    /// Is available
    /// </summary>
    public bool IsAvailable { get; set; }

    /// <summary>
    /// رسوم المعاملة
    /// Transaction fees
    /// </summary>
    public decimal TransactionFee { get; set; }

    /// <summary>
    /// نسبة الرسوم
    /// Fee percentage
    /// </summary>
    public decimal FeePercentage { get; set; }

    /// <summary>
    /// الحد الأدنى للمبلغ
    /// Minimum amount
    /// </summary>
    public decimal MinAmount { get; set; }

    /// <summary>
    /// الحد الأقصى للمبلغ
    /// Maximum amount
    /// </summary>
    public decimal MaxAmount { get; set; }

    /// <summary>
    /// العملات المدعومة
    /// Supported currencies
    /// </summary>
    public List<string> SupportedCurrencies { get; set; } = new();

    /// <summary>
    /// البلدان المدعومة
    /// Supported countries
    /// </summary>
    public List<string> SupportedCountries { get; set; } = new();

    /// <summary>
    /// وقت المعالجة المتوقع
    /// Expected processing time
    /// </summary>
    public string ProcessingTime { get; set; } = string.Empty;

    /// <summary>
    /// النوع (بطاقة ائتمان، محفظة رقمية، تحويل بنكي، إلخ)
    /// Type (credit card, digital wallet, bank transfer, etc.)
    /// </summary>
    public string Type { get; set; } = string.Empty;

    /// <summary>
    /// هل تحتاج إلى تحقق إضافي
    /// Requires additional verification
    /// </summary>
    public bool RequiresVerification { get; set; }

    /// <summary>
    /// هل تدعم الاسترداد
    /// Supports refunds
    /// </summary>
    public bool SupportsRefunds { get; set; }

    /// <summary>
    /// ترتيب العرض
    /// Display order
    /// </summary>
    public int DisplayOrder { get; set; }

    /// <summary>
    /// هل موصى بها
    /// Is recommended
    /// </summary>
    public bool IsRecommended { get; set; }

    /// <summary>
    /// رسالة تحذيرية (إذا وجدت)
    /// Warning message (if any)
    /// </summary>
    public string? WarningMessage { get; set; }
}