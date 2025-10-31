using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Accounting.Commands.Payouts
{
    /// <summary>
    /// أمر تحويل مستحقات الملاك
    /// Process owner payouts command
    /// </summary>
    public class ProcessOwnerPayoutsCommand : IRequest<ResultDto<ProcessOwnerPayoutsResult>>
    {
        /// <summary>
        /// معرفات الملاك المحددين (اختياري)
        /// Specific owner IDs (optional)
        /// </summary>
        public List<Guid> OwnerIds { get; set; }

        /// <summary>
        /// الحد الأدنى للمبلغ للتحويل
        /// Minimum amount threshold for payout
        /// </summary>
        public decimal MinimumAmountThreshold { get; set; } = 1000;

        /// <summary>
        /// تضمين المعاملات المعلقة
        /// Include pending transactions
        /// </summary>
        public bool IncludePendingTransactions { get; set; } = false;

        /// <summary>
        /// وضع المعاينة فقط (بدون تنفيذ فعلي)
        /// Preview mode only (no actual execution)
        /// </summary>
        public bool PreviewOnly { get; set; } = false;

        /// <summary>
        /// ملاحظات التحويل
        /// Payout notes
        /// </summary>
        public string Notes { get; set; }
    }

    /// <summary>
    /// نتيجة تحويل مستحقات الملاك
    /// Process owner payouts result
    /// </summary>
    public class ProcessOwnerPayoutsResult
    {
        /// <summary>
        /// عدد التحويلات المعالجة
        /// Number of payouts processed
        /// </summary>
        public int PayoutsProcessed { get; set; }

        /// <summary>
        /// إجمالي المبلغ المحول
        /// Total amount transferred
        /// </summary>
        public decimal TotalAmountTransferred { get; set; }

        /// <summary>
        /// تفاصيل التحويلات
        /// Payout details
        /// </summary>
        public List<OwnerPayoutDetail> PayoutDetails { get; set; } = new List<OwnerPayoutDetail>();

        /// <summary>
        /// الأخطاء (إن وجدت)
        /// Errors (if any)
        /// </summary>
        public List<string> Errors { get; set; } = new List<string>();
    }

    /// <summary>
    /// تفاصيل تحويل المالك
    /// Owner payout detail
    /// </summary>
    public class OwnerPayoutDetail
    {
        /// <summary>
        /// معرف المالك
        /// Owner ID
        /// </summary>
        public Guid OwnerId { get; set; }

        /// <summary>
        /// اسم المالك
        /// Owner name
        /// </summary>
        public string OwnerName { get; set; }

        /// <summary>
        /// المبلغ المحول
        /// Amount transferred
        /// </summary>
        public decimal Amount { get; set; }

        /// <summary>
        /// رقم المعاملة
        /// Transaction number
        /// </summary>
        public string TransactionNumber { get; set; }

        /// <summary>
        /// الحالة
        /// Status
        /// </summary>
        public string Status { get; set; }

        /// <summary>
        /// رسالة الخطأ (إن وجدت)
        /// Error message (if any)
        /// </summary>
        public string ErrorMessage { get; set; }
    }
}
