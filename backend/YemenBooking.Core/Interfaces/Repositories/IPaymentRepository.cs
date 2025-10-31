using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع المدفوعات
/// Payment repository interface
/// </summary>
public interface IPaymentRepository : IRepository<Payment>
{
    /// <summary>
    /// معالجة الدفع
    /// Process payment
    /// </summary>
    Task<Payment> ProcessPaymentAsync(Payment payment, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على دفع بواسطة المعرف
    /// Get payment by id
    /// </summary>
    Task<Payment?> GetPaymentByIdAsync(Guid paymentId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث الدفع
    /// Update payment
    /// </summary>
    Task<Payment> UpdatePaymentAsync(Payment payment, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث حالة الدفع
    /// Update payment status
    /// </summary>
    Task<bool> UpdatePaymentStatusAsync(Guid paymentId, string status, CancellationToken cancellationToken = default);

    /// <summary>
    /// حفظ الدفع
    /// Save payment
    /// </summary>
    Task<Payment> SavePaymentAsync(Payment payment, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مدفوعات الحجز
    /// Get payments by booking
    /// </summary>
    Task<IEnumerable<Payment>> GetPaymentsByBookingAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مدفوعات المستخدم
    /// Get payments by user
    /// </summary>
    Task<IEnumerable<Payment>> GetPaymentsByUserAsync(Guid userId, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على المدفوعات حسب الحالة
    /// Get payments by status
    /// </summary>
    Task<IEnumerable<Payment>> GetPaymentsByStatusAsync(string status, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على المدفوعات حسب طريقة الدفع
    /// Get payments by method
    /// </summary>
    Task<IEnumerable<Payment>> GetPaymentsByMethodAsync(string method, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الحجز بواسطة المعرف
    /// Get booking by id
    /// </summary>
    Task<Booking?> GetBookingByIdAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// معالجة الاسترداد
    /// Process refund
    /// </summary>
    Task<bool> ProcessRefundAsync(Guid paymentId, decimal amount, string reason, CancellationToken cancellationToken = default);

    /// <summary>
    /// حساب تفصيل الإيرادات
    /// Calculate revenue breakdown
    /// </summary>
    Task<object> CalculateRevenueBreakdownAsync(
        DateTime fromDate, 
        DateTime toDate, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// حساب هوامش الربح
    /// Calculate profit margins
    /// </summary>
    Task<object> CalculateProfitMarginsAsync(
        DateTime fromDate, 
        DateTime toDate, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على إجمالي المبلغ المدفوع لحجز معين
    /// Get total paid amount for a booking
    /// </summary>
    Task<decimal> GetTotalPaidAmountAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// عمليات الاسترداد المرتبطة بالدفع
    /// Get refunds for a payment
    /// </summary>
    Task<IEnumerable<Payment>> GetRefundsForPaymentAsync(Guid paymentId, CancellationToken cancellationToken = default);
}
