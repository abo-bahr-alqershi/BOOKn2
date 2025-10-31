using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Bookings.DTOs;

namespace YemenBooking.Application.Features.Payments.DTOs
{
    /// <summary>
    /// تفاصيل الدفع
    /// Payment details DTO
    /// </summary>
    public class PaymentDetailsDto
    {
        /// <summary>
        /// بيانات الدفع
        /// Payment data
        /// </summary>
        public PaymentDto Payment { get; set; }

        /// <summary>
        /// قائمة الاستردادات
        /// List of refunds
        /// </summary>
        public List<RefundDto> Refunds { get; set; } = new List<RefundDto>();

        /// <summary>
        /// قائمة الأنشطة
        /// List of activities
        /// </summary>
        public List<PaymentActivityDto> Activities { get; set; } = new List<PaymentActivityDto>();

        /// <summary>
        /// معلومات الحجز
        /// BookingDto information
        /// </summary>
        public BookingInfoDto? BookingInfo { get; set; }

        /// <summary>
        /// معلومات بوابة الدفع
        /// Payment gateway information
        /// </summary>
        public PaymentGatewayInfoDto? GatewayInfo { get; set; }
    }

    /// <summary>
    /// معلومات نشاط الدفع
    /// Payment activity DTO
    /// </summary>
    public class PaymentActivityDto
    {
        public string Id { get; set; }
        public string Action { get; set; }
        public string Description { get; set; }
        public DateTime Timestamp { get; set; }
        public string? UserId { get; set; }
        public string? UserName { get; set; }
        public Dictionary<string, object>? Data { get; set; }
    }

    /// <summary>
    /// معلومات الاسترداد
    /// Refund DTO
    /// </summary>
    public class RefundDto
    {
        public string Id { get; set; }
        public string PaymentId { get; set; }
        public MoneyDto Amount { get; set; }
        public string Reason { get; set; }
        public string Status { get; set; }
        public DateTime RequestedAt { get; set; }
        public DateTime? ProcessedAt { get; set; }
        public string? TransactionId { get; set; }
        public string? ProcessedBy { get; set; }
        public string? Notes { get; set; }
        public string? Type { get; set; }
        public Dictionary<string, object>? Metadata { get; set; }
    }

    /// <summary>
    /// معلومات الحجز
    /// BookingDto information DTO
    /// </summary>
    public class BookingInfoDto
    {
        public string BookingId { get; set; }
        public string BookingReference { get; set; }
        public DateTime CheckIn { get; set; }
        public DateTime CheckOut { get; set; }
        public string UnitName { get; set; }
        public string PropertyName { get; set; }
        public int GuestsCount { get; set; }
    }

    /// <summary>
    /// معلومات بوابة الدفع
    /// Payment gateway information DTO
    /// </summary>
    public class PaymentGatewayInfoDto
    {
        public string GatewayName { get; set; }
        public string GatewayTransactionId { get; set; }
        public string? AuthorizationCode { get; set; }
        public string? ResponseCode { get; set; }
        public string? ResponseMessage { get; set; }
        public Dictionary<string, object>? RawResponse { get; set; }
    }
} 