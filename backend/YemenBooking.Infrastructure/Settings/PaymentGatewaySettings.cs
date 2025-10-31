namespace YemenBooking.Infrastructure.Settings
{
    /// <summary>
    /// إعدادات خدمة بوابة الدفع
    /// Payment gateway service settings
    /// </summary>
    public class PaymentGatewaySettings
    {
        /// <summary>
        /// عنوان API لعملية الشحن
        /// Charge API endpoint
        /// </summary>
        public string ChargeUrl { get; set; } = string.Empty;

        /// <summary>
        /// عنوان API لعملية الاسترداد
        /// Refund API endpoint
        /// </summary>
        public string RefundUrl { get; set; } = string.Empty;

        /// <summary>
        /// مفتاح API
        /// API key
        /// </summary>
        public string ApiKey { get; set; } = string.Empty;

        /// <summary>
        /// طرق الدفع المتاحة افتراضيًا
        /// Available payment methods
        /// </summary>
        public string[] AvailableMethods { get; set; } = new[] { "CreditCard", "PayPal", "BankTransfer" };
    }
} 