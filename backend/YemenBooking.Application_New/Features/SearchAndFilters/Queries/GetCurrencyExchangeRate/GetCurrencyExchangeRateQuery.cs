using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetCurrencyExchangeRate;

/// <summary>
/// استعلام الحصول على سعر صرف العملة
/// Query to get currency exchange rate
/// </summary>
public class GetCurrencyExchangeRateQuery : IRequest<ResultDto<CurrencyExchangeRateDto>>
{
    /// <summary>
    /// العملة المصدر
    /// </summary>
    public string FromCurrency { get; set; } = "YER";
    
    /// <summary>
    /// العملة الهدف
    /// </summary>
    public string ToCurrency { get; set; } = "USD";
    
    /// <summary>
    /// المبلغ للتحويل (اختياري)
    /// </summary>
    public decimal? Amount { get; set; }
}

/// <summary>
/// بيانات سعر صرف العملة
/// </summary>
public class CurrencyExchangeRateDto
{
    /// <summary>
    /// العملة المصدر
    /// </summary>
    public string FromCurrency { get; set; } = string.Empty;
    
    /// <summary>
    /// العملة الهدف
    /// </summary>
    public string ToCurrency { get; set; } = string.Empty;
    
    /// <summary>
    /// سعر الصرف
    /// </summary>
    public decimal ExchangeRate { get; set; }
    
    /// <summary>
    /// المبلغ المحول (إذا تم تحديد مبلغ)
    /// </summary>
    public decimal? ConvertedAmount { get; set; }
    
    /// <summary>
    /// تاريخ آخر تحديث لسعر الصرف
    /// </summary>
    public DateTime LastUpdated { get; set; }
}