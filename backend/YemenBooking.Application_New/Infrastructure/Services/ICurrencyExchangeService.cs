namespace YemenBooking.Infrastructure.Services;

/// <summary>
/// واجهة خدمة أسعار صرف العملات الخارجية
/// External currency exchange service interface
/// </summary>
public interface ICurrencyExchangeService
{
    /// <summary>
    /// الحصول على سعر الصرف من خدمة خارجية
    /// Get exchange rate from external service
    /// </summary>
    /// <param name="fromCurrency">العملة المصدر</param>
    /// <param name="toCurrency">العملة الهدف</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>سعر الصرف</returns>
    Task<decimal?> GetExchangeRateAsync(string fromCurrency, string toCurrency, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على جميع أسعار الصرف لعملة معينة من خدمة خارجية
    /// Get all exchange rates for a currency from external service
    /// </summary>
    /// <param name="baseCurrency">العملة الأساسية</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قاموس أسعار الصرف</returns>
    Task<Dictionary<string, decimal>> GetAllExchangeRatesAsync(string baseCurrency, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من صحة رمز العملة
    /// Validate currency code
    /// </summary>
    /// <param name="currencyCode">رمز العملة</param>
    /// <returns>true إذا كان رمز العملة صحيح</returns>
    bool IsValidCurrencyCode(string currencyCode);

    /// <summary>
    /// الحصول على قائمة العملات المدعومة
    /// Get list of supported currencies
    /// </summary>
    /// <returns>قائمة رموز العملات المدعومة</returns>
    Task<IEnumerable<string>> GetSupportedCurrenciesAsync();
}
