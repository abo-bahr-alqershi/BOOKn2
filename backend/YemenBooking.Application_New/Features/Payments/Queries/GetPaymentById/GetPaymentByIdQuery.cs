using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Payments.DTOs;

namespace YemenBooking.Application.Features.Payments.Queries.GetPaymentById
{
    /// <summary>
    /// استعلام لجلب تفاصيل دفعة واحدة حسب المعرف
    /// Query to get a single payment by ID with details
    /// </summary>
    public class GetPaymentByIdQuery : IRequest<PaymentDetailsDto>
    {
        /// <summary>معرف الدفعة</summary>
        public Guid PaymentId { get; set; }

        public GetPaymentByIdQuery(Guid paymentId)
        {
            PaymentId = paymentId;
        }
    }
}
