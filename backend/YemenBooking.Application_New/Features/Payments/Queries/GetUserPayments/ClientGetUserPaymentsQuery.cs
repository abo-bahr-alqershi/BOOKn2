using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Payments.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Payments.Queries.GetUserPayments;

/// <summary>
/// استعلام جلب مدفوعات المستخدم للعميل
/// Query to get user payments for client
/// </summary>
public class ClientGetUserPaymentsQuery : IRequest<ResultDto<PaginatedResult<ClientPaymentDto>>>
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// رقم الصفحة
    /// Page number
    /// </summary>
    public int PageNumber { get; set; } = 1;

    /// <summary>
    /// حجم الصفحة
    /// Page size
    /// </summary>
    public int PageSize { get; set; } = 10;

    /// <summary>
    /// فلتر حسب حالة الدفع
    /// Filter by payment status
    /// </summary>
    public string? Status { get; set; }

    /// <summary>
    /// فلتر حسب طريقة الدفع
    /// Filter by payment method
    /// </summary>
    public string? PaymentMethod { get; set; }

    /// <summary>
    /// تاريخ البداية للفلترة
    /// Start date for filtering
    /// </summary>
    public DateTime? FromDate { get; set; }

    /// <summary>
    /// تاريخ النهاية للفلترة
    /// End date for filtering
    /// </summary>
    public DateTime? ToDate { get; set; }

    /// <summary>
    /// الحد الأدنى للمبلغ
    /// Minimum amount
    /// </summary>
    public decimal? MinAmount { get; set; }

    /// <summary>
    /// الحد الأقصى للمبلغ
    /// Maximum amount
    /// </summary>
    public decimal? MaxAmount { get; set; }
}

/// <summary>
/// بيانات المدفوعات للعميل
/// Client payment data
/// </summary>
public class ClientPaymentDto
{
    /// <summary>
    /// معرف المدفوعة
    /// Payment ID
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// معرف الحجز
    /// BookingDto ID
    /// </summary>
    public Guid BookingId { get; set; }

    /// <summary>
    /// رقم الحجز
    /// BookingDto number
    /// </summary>
    public string BookingNumber { get; set; } = string.Empty;

    /// <summary>
    /// اسم العقار
    /// Property name
    /// </summary>
    public string PropertyName { get; set; } = string.Empty;

    /// <summary>
    /// اسم الوحدة
    /// Unit name
    /// </summary>
    public string UnitName { get; set; } = string.Empty;

    /// <summary>
    /// المبلغ
    /// Amount
    /// </summary>
    public decimal Amount { get; set; }

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = "YER";

    /// <summary>
    /// طريقة الدفع
    /// Payment method
    /// </summary>
    public string PaymentMethod { get; set; } = string.Empty;

    /// <summary>
    /// حالة الدفع
    /// Payment status
    /// </summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>
    /// تاريخ الدفع
    /// Payment date
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// تاريخ معالجة الدفع
    /// Processing date
    /// </summary>
    public DateTime? ProcessedAt { get; set; }

    /// <summary>
    /// رقم المرجع الخارجي
    /// External reference number
    /// </summary>
    public string? ExternalReference { get; set; }

    /// <summary>
    /// رقم الفاتورة
    /// Invoice number
    /// </summary>
    public string? InvoiceNumber { get; set; }

    /// <summary>
    /// ملاحظات
    /// Notes
    /// </summary>
    public string? Notes { get; set; }

    /// <summary>
    /// تفاصيل الفشل (إذا فشل الدفع)
    /// Failure details (if payment failed)
    /// </summary>
    public string? FailureReason { get; set; }

    /// <summary>
    /// الرسوم
    /// Fees
    /// </summary>
    public decimal Fees { get; set; }

    /// <summary>
    /// الضرائب
    /// Taxes
    /// </summary>
    public decimal Taxes { get; set; }

    /// <summary>
    /// المبلغ الصافي
    /// Net amount
    /// </summary>
    public decimal NetAmount { get; set; }

    /// <summary>
    /// هل يمكن استرداد المبلغ
    /// Can be refunded
    /// </summary>
    public bool CanRefund { get; set; }

    /// <summary>
    /// تاريخ انتهاء صلاحية الاسترداد
    /// Refund expiry date
    /// </summary>
    public DateTime? RefundExpiryDate { get; set; }
}