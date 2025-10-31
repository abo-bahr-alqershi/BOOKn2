using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories
{
    /// <summary>
    /// واجهة مستودع أسعار صرف العملات
    /// Currency exchange repository interface
    /// </summary>
    public interface ICurrencyExchangeRepository : IRepository<CurrencyExchangeRate>
    {
        /// <summary>
        /// الحصول على سعر الصرف بين عملتين
        /// Get exchange rate between two currencies
        /// </summary>
        /// <param name="fromCurrency">العملة المصدر</param>
        /// <param name="toCurrency">العملة الهدف</param>
        /// <returns>سعر الصرف</returns>
        Task<CurrencyExchangeRate?> GetExchangeRateAsync(string fromCurrency, string toCurrency);

        /// <summary>
        /// الحصول على أحدث أسعار الصرف لعملة معينة
        /// Get latest exchange rates for a specific currency
        /// </summary>
        /// <param name="baseCurrency">العملة الأساسية</param>
        /// <returns>قائمة أسعار الصرف</returns>
        Task<List<CurrencyExchangeRate>> GetLatestRatesForCurrencyAsync(string baseCurrency);

        /// <summary>
        /// الحصول على جميع أسعار الصرف الحالية
        /// Get all current exchange rates
        /// </summary>
        /// <returns>قائمة أسعار الصرف</returns>
        Task<List<CurrencyExchangeRate>> GetAllCurrentRatesAsync();

        /// <summary>
        /// تحديث سعر الصرف
        /// Update exchange rate
        /// </summary>
        /// <param name="fromCurrency">العملة المصدر</param>
        /// <param name="toCurrency">العملة الهدف</param>
        /// <param name="rate">السعر الجديد</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> UpdateExchangeRateAsync(string fromCurrency, string toCurrency, decimal rate);

        /// <summary>
        /// تحديث أسعار الصرف بالجملة
        /// Bulk update exchange rates
        /// </summary>
        /// <param name="rates">قائمة أسعار الصرف الجديدة</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> BulkUpdateRatesAsync(List<CurrencyExchangeRate> rates);

        /// <summary>
        /// الحصول على تاريخ آخر تحديث لأسعار الصرف
        /// Get last update date for exchange rates
        /// </summary>
        /// <returns>تاريخ آخر تحديث</returns>
        Task<DateTime?> GetLastUpdateDateAsync();

        /// <summary>
        /// التحقق من انتهاء صلاحية أسعار الصرف
        /// Check if exchange rates are expired
        /// </summary>
        /// <param name="maxAgeHours">الحد الأقصى للعمر بالساعات</param>
        /// <returns>true إذا كانت منتهية الصلاحية</returns>
        Task<bool> AreRatesExpiredAsync(int maxAgeHours = 24);

        /// <summary>
        /// حساب المبلغ المحول
        /// Calculate converted amount
        /// </summary>
        /// <param name="amount">المبلغ الأصلي</param>
        /// <param name="fromCurrency">العملة المصدر</param>
        /// <param name="toCurrency">العملة الهدف</param>
        /// <returns>المبلغ المحول</returns>
        Task<decimal> ConvertAmountAsync(decimal amount, string fromCurrency, string toCurrency);

        /// <summary>
        /// الحصول على العملات المدعومة
        /// Get supported currencies
        /// </summary>
        /// <returns>قائمة العملات المدعومة</returns>
        Task<List<string>> GetSupportedCurrenciesAsync();
    }

    /// <summary>
    /// كيان سعر صرف العملة
    /// Currency exchange rate entity
    /// </summary>
    public class CurrencyExchangeRate : BaseEntity<Guid>
    {
        /// <summary>
        /// العملة المصدر
        /// From currency
        /// </summary>
        public string FromCurrency { get; set; } = string.Empty;

        /// <summary>
        /// العملة الهدف
        /// To currency
        /// </summary>
        public string ToCurrency { get; set; } = string.Empty;

        /// <summary>
        /// سعر الصرف
        /// Exchange rate
        /// </summary>
        public decimal Rate { get; set; }

        /// <summary>
        /// تاريخ آخر تحديث
        /// Last updated date
        /// </summary>
        public DateTime LastUpdated { get; set; }

        /// <summary>
        /// مصدر البيانات
        /// Data source
        /// </summary>
        public string Source { get; set; } = string.Empty;

        /// <summary>
        /// هل السعر نشط
        /// Whether the rate is active
        /// </summary>
        public bool IsActive { get; set; } = true;
    }
}
