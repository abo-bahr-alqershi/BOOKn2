using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using System.Text.Json.Serialization;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Payments.DTOs
{
    /// <summary>
    /// DTO لبيانات الدفع
    /// DTO for payment data
    /// </summary>
    public class PaymentDto
    {
        /// <summary>معرف الدفعة</summary>
        public Guid Id { get; set; }

        /// <summary>معرف الحجز</summary>
        public Guid BookingId { get; set; }

        /// <summary>المبلغ المدفوع</summary>
        public decimal Amount { get; set; }
        
        /// <summary>المبلغ بصيغة MoneyDto</summary>
        public MoneyDto AmountMoney { get; set; }

        /// <summary>رقم المعاملة</summary>
        public string TransactionId { get; set; }

        /// <summary>طريقة الدفع</summary>
        [JsonPropertyName("paymentMethod")]
        public PaymentMethodEnum Method { get; set; }

        /// <summary>العملة</summary>
        public string Currency { get; set; } = "YER";

        /// <summary>حالة الدفع</summary>
        public PaymentStatus Status { get; set; }

        /// <summary>تاريخ الدفع</summary>
        public DateTime PaymentDate { get; set; }

        // 🎯 حقول المستخدم والحجز
        public Guid? UserId { get; set; }
        public string? UserName { get; set; }
        public string? UserEmail { get; set; }

        // 🎯 حقول الوحدة والعقار
        public Guid? UnitId { get; set; }
        public string? UnitName { get; set; }
        public Guid? PropertyId { get; set; }
        public string? PropertyName { get; set; }

        // 🎯 حقول إضافية
        public string? Description { get; set; }
        public string? Notes { get; set; }
        public string? ReceiptUrl { get; set; }
        public string? InvoiceNumber { get; set; }
        public string? GatewayTransactionId { get; set; }

        // 🎯 حقول المعالجة
        public Guid? ProcessedBy { get; set; }
        public string? ProcessedByName { get; set; }
        public DateTime? ProcessedAt { get; set; }

        // 🎯 حقول الاسترداد
        public bool? IsRefundable { get; set; }
        public DateTime? RefundDeadline { get; set; }
        public decimal? RefundedAmount { get; set; }
        public DateTime? RefundedAt { get; set; }
        public string? RefundReason { get; set; }
        public string? RefundTransactionId { get; set; }

        // 🎯 حقول الإلغاء
        public bool? IsVoided { get; set; }
        public DateTime? VoidedAt { get; set; }
        public string? VoidReason { get; set; }

        // 🎯 Metadata
        public Dictionary<string, object>? Metadata { get; set; }
    }
} 