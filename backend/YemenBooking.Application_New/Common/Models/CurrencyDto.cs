using System;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// Data transfer object for currency settings
    /// </summary>
    public class CurrencyDto
    {
        /// <summary>
        /// Currency code (e.g. USD)
        /// </summary>
        public string Code { get; set; }

        /// <summary>
        /// Arabic currency code
        /// </summary>
        public string ArabicCode { get; set; }

        /// <summary>
        /// Currency name (e.g. US Dollar)
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Currency name in Arabic
        /// </summary>
        public string ArabicName { get; set; }

        /// <summary>
        /// Whether this is the default currency
        /// </summary>
        public bool IsDefault { get; set; }

        /// <summary>
        /// Exchange rate relative to default currency; null for default currency
        /// </summary>
        public decimal? ExchangeRate { get; set; }

        /// <summary>
        /// Last update timestamp for the exchange rate
        /// </summary>
        public DateTime? LastUpdated { get; set; }
    }
} 