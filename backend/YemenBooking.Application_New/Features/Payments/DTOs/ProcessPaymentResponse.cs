using System;

namespace YemenBooking.Application.Features.Payments.DTOs
{
    /// <summary>
    /// استجابة معالجة الدفع
    /// Process payment response
    /// </summary>
    public class ProcessPaymentResponse
    {
        /// <summary>
        /// معرف المعاملة
        /// Transaction identifier
        /// </summary>
        public string TransactionId { get; set; } = string.Empty;

        /// <summary>
        /// هل تمت المعالجة بنجاح
        /// Whether processing was successful
        /// </summary>
        public bool Success { get; set; }

        /// <summary>
        /// رسالة النتيجة
        /// Result message
        /// </summary>
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// المبلغ المعالج
        /// Processed amount
        /// </summary>
        public decimal ProcessedAmount { get; set; }

        /// <summary>
        /// الرسوم
        /// Fees
        /// </summary>
        public decimal Fees { get; set; }

        /// <summary>
        /// العملة
        /// Currency
        /// </summary>
        public string Currency { get; set; } = string.Empty;

        /// <summary>
        /// تاريخ المعالجة
        /// Processing timestamp
        /// </summary>
        public DateTime ProcessedAt { get; set; }

        /// <summary>
        /// حالة الدفع
        /// Payment status
        /// </summary>
        public string PaymentStatusDto { get; set; } = string.Empty;
    }
}
