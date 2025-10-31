// namespace YemenBooking.Application.Infrastructure.Services;

// /// <summary>
// /// واجهة خدمة بوابة الدفع
// /// Payment gateway service interface
// /// </summary>
// public interface IPaymentGatewayService
// {
//     /// <summary>
//     /// شحن الدفع
//     /// Charge payment
//     /// </summary>
//     Task<(bool IsSuccess, string TransactionId, string ErrorMessage)> ChargePaymentAsync(
//         decimal amount,
//         string currency,
//         string paymentMethod,
//         Dictionary<string, object>? metadata = null,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// معالجة الاسترداد عبر البوابة
//     /// Process refund via gateway
//     /// </summary>
//     Task<(bool IsSuccess, string RefundId, string ErrorMessage)> ProcessRefundAsync(
//         string originalTransactionId,
//         decimal refundAmount,
//         string reason,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// التحقق من حالة المعاملة
//     /// Verify transaction status
//     /// </summary>
//     Task<(string Status, Dictionary<string, object> Details)> VerifyTransactionAsync(
//         string transactionId,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// إلغاء المعاملة
//     /// Cancel transaction
//     /// </summary>
//     Task<bool> CancelTransactionAsync(
//         string transactionId,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// الحصول على طرق الدفع المتاحة
//     /// Get available payment methods
//     /// </summary>
//     Task<IEnumerable<string>> GetAvailablePaymentMethodsAsync(
//         string? countryCode = null,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// التحقق من صحة بيانات الدفع
//     /// Validate payment data
//     /// </summary>
//     Task<(bool IsValid, string[] Errors)> ValidatePaymentDataAsync(
//         string paymentMethod,
//         Dictionary<string, object> paymentData,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// إبطال الدفع (alias for CancelTransactionAsync)
//     /// Void payment asynchronously
//     /// </summary>
//     Task<bool> VoidPaymentAsync(string transactionId,
//         CancellationToken cancellationToken = default);

//     /// <summary>
//     /// معالجة دفعة سبأ كاش
//     /// Process SabaCash payment
//     /// </summary>
//     Task<(bool IsSuccess, string TransactionId, string ErrorMessage)> ProcessSabaCashPaymentAsync(
//         string sabaCashTransactionId,
//         decimal amount,
//         CancellationToken cancellationToken = default);
// }
