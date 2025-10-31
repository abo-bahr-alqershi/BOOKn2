using System;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Payments.Services;
using YemenBooking.Application.Features.Payments.DTOs;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// خدمة المدفوعات
    /// Implements IPaymentService by delegating to IPaymentGatewayService
    /// </summary>
    public class PaymentService : IPaymentService
    {
        private readonly IPaymentGatewayService _gatewayService;

        public PaymentService(IPaymentGatewayService gatewayService)
        {
            _gatewayService = gatewayService;
        }

        /// <summary>
        /// معالجة الدفع (ستب)
        /// </summary>
        public Task<PaymentResult> ProcessPaymentAsync(Guid bookingId, Guid paymentMethodId, decimal amount, string currency)
        {
            throw new NotImplementedException("PaymentService.ProcessPaymentAsync is not implemented yet.");
        }

        /// <summary>
        /// التحقق من صحة بيانات الدفع (ستب)
        /// </summary>
        public Task<bool> ValidatePaymentDataAsync(Guid paymentMethodId, decimal amount, string currency)
        {
            throw new NotImplementedException("PaymentService.ValidatePaymentDataAsync is not implemented yet.");
        }

        /// <summary>
        /// استرداد الدفع (ستب)
        /// </summary>
        public Task<RefundResult> RefundPaymentAsync(Guid paymentId, decimal refundAmount, string reason)
        {
            throw new NotImplementedException("PaymentService.RefundPaymentAsync is not implemented yet.");
        }

        /// <summary>
        /// الحصول على حالة الدفع (ستب)
        /// </summary>
        public Task<PaymentStatus> GetPaymentStatusAsync(Guid paymentId)
        {
            throw new NotImplementedException("PaymentService.GetPaymentStatusAsync is not implemented yet.");
        }

        /// <summary>
        /// حساب الرسوم (ستب)
        /// </summary>
        public Task<decimal> CalculateFeesAsync(decimal amount, PaymentMethodEnum paymentMethodType, string currency)
        {
            throw new NotImplementedException("PaymentService.CalculateFeesAsync is not implemented yet.");
        }

        /// <summary>
        /// إنشاء رابط الدفع (ستب)
        /// </summary>
        public Task<string> CreatePaymentLinkAsync(Guid bookingId, decimal amount, string currency, string returnUrl)
        {
            throw new NotImplementedException("PaymentService.CreatePaymentLinkAsync is not implemented yet.");
        }
    }
}