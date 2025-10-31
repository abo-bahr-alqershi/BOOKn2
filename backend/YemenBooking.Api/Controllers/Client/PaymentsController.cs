using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Payments.Commands.ProcessPayment;
using YemenBooking.Application.Features.Payments.Queries.GetPaymentMethods;
using YemenBooking.Application.Features.Payments.Queries.GetUserPayments;
using YemenBooking.Application.Features.Payments.DTOs;
using YemenBooking.Application.Common.Models;
using System.Collections.Generic;

namespace YemenBooking.Api.Controllers.Client
{
    /// <summary>
    /// كونترولر إدارة المدفوعات للعملاء
    /// Client Payments Management Controller
    /// </summary>
    public class PaymentsController : BaseClientController
    {
        public PaymentsController(IMediator mediator) : base(mediator)
        {
        }

        /// <summary>
        /// معالجة دفعة جديدة
        /// Process new payment
        /// </summary>
        /// <param name="command">بيانات الدفع</param>
        /// <returns>نتيجة معالجة الدفع</returns>
        [HttpPost("process")]
        public async Task<ActionResult<ResultDto<ProcessPaymentResponse>>> ProcessPayment([FromBody] ProcessPaymentCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }


        /// <summary>
        /// الحصول على تاريخ مدفوعات المستخدم
        /// Get user payment history
        /// </summary>
        /// <param name="query">معايير البحث</param>
        /// <returns>تاريخ المدفوعات</returns>
        [HttpGet("history")]
        public async Task<ActionResult<ResultDto<PaginatedResult<ClientPaymentDto>>>> GetUserPayments([FromQuery] ClientGetUserPaymentsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
}
