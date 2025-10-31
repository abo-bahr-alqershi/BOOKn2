using System;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Payments.Services
{
    /// <summary>
    /// واجهة خدمة المدفوعات
    /// Payment service interface
    /// </summary>
    public interface IPaymentService
    {
        /// <summary>
        /// معالجة الدفع
        /// Process payment
        /// </summary>
        /// <param name="bookingId">معرف الحجز</param>
        /// <param name="paymentMethodId">معرف طريقة الدفع</param>
        /// <param name="amount">المبلغ</param>
        /// <param name="currency">العملة</param>
        /// <returns>نتيجة المعالجة</returns>
        Task<PaymentResult> ProcessPaymentAsync(Guid bookingId, Guid paymentMethodId, decimal amount, string currency);

        /// <summary>
        /// التحقق من صحة بيانات الدفع
        /// Validate payment data
        /// </summary>
        /// <param name="paymentMethodId">معرف طريقة الدفع</param>
        /// <param name="amount">المبلغ</param>
        /// <param name="currency">العملة</param>
        /// <returns>نتيجة التحقق</returns>
        Task<bool> ValidatePaymentDataAsync(Guid paymentMethodId, decimal amount, string currency);

        /// <summary>
        /// استرداد المبلغ
        /// Refund payment
        /// </summary>
        /// <param name="paymentId">معرف الدفعة</param>
        /// <param name="refundAmount">مبلغ الاسترداد</param>
        /// <param name="reason">سبب الاسترداد</param>
        /// <returns>نتيجة الاسترداد</returns>
        Task<RefundResult> RefundPaymentAsync(Guid paymentId, decimal refundAmount, string reason);

        /// <summary>
        /// التحقق من حالة الدفع
        /// Check payment status
        /// </summary>
        /// <param name="paymentId">معرف الدفعة</param>
        /// <returns>حالة الدفع</returns>
        Task<PaymentStatus> GetPaymentStatusAsync(Guid paymentId);

        /// <summary>
        /// حساب الرسوم
        /// Calculate fees
        /// </summary>
        /// <param name="amount">المبلغ الأساسي</param>
        /// <param name="paymentMethodType">نوع طريقة الدفع</param>
        /// <param name="currency">العملة</param>
        /// <returns>الرسوم المحسوبة</returns>
        Task<decimal> CalculateFeesAsync(decimal amount, PaymentMethodEnum paymentMethodType, string currency);

        /// <summary>
        /// إنشاء رابط دفع آمن
        /// Create secure payment link
        /// </summary>
        /// <param name="bookingId">معرف الحجز</param>
        /// <param name="amount">المبلغ</param>
        /// <param name="currency">العملة</param>
        /// <param name="returnUrl">رابط الإرجاع</param>
        /// <returns>رابط الدفع</returns>
        Task<string> CreatePaymentLinkAsync(Guid bookingId, decimal amount, string currency, string returnUrl);
    }

    /// <summary>
    /// نتيجة معالجة الدفع
    /// Payment processing result
    /// </summary>
    public class PaymentResult
    {
        public bool IsSuccess { get; set; }
        public string TransactionId { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public PaymentStatus Status { get; set; }
        public decimal ProcessedAmount { get; set; }
        public decimal Fees { get; set; }
        public DateTime ProcessedAt { get; set; }
    }

    /// <summary>
    /// نتيجة الاسترداد
    /// Refund result
    /// </summary>
    public class RefundResult
    {
        public bool IsSuccess { get; set; }
        public string RefundId { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public decimal RefundedAmount { get; set; }
        public DateTime RefundedAt { get; set; }
    }
}
