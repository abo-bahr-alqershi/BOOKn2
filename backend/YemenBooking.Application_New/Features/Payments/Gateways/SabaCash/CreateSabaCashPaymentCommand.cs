using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Payments
{
    /// <summary>
    /// أمر إنشاء دفعة عبر سبأ كاش
    /// Create SabaCash payment command
    /// </summary>
    public class CreateSabaCashPayment : IRequest<ResultDto<Guid>>
    {
        /// <summary>
        /// معرف الحجز
        /// BookingDto ID
        /// </summary>
        public Guid BookingId { get; set; }

        /// <summary>
        /// المبلغ المدفوع
        /// Amount paid
        /// </summary>
        public decimal Amount { get; set; }

        /// <summary>
        /// معرف معاملة سبأ كاش
        /// SabaCash transaction ID
        /// </summary>
        public string SabaCashTransactionId { get; set; }

        /// <summary>
        /// رقم محفظة العميل
        /// Customer wallet number
        /// </summary>
        public string CustomerWallet { get; set; }

        /// <summary>
        /// ملاحظات إضافية
        /// Additional notes
        /// </summary>
        public string Notes { get; set; }
    }
}
