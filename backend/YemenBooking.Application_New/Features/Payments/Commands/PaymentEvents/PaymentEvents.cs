using System;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Events;
using YemenBooking.Core.ValueObjects;

namespace YemenBooking.Application.Features.Payments.Commands.PaymentEvents
{
    /// <summary>
    /// Event for processed payments
    /// </summary>
    public class PaymentProcessedEvent : IPaymentProcessedEvent
    {
        public Guid PaymentId { get; set; }
        public Guid BookingId { get; set; }
        public Money Amount { get; set; }
        public string Method { get; set; } = null!;
        public string TransactionId { get; set; } = null!;
        public string Status { get; set; } = null!;
        public DateTime ProcessedAt { get; set; }
        public string Currency { get; set; } = null!;
        public string? Notes { get; set; }

        public Guid EventId { get; set; }

        public DateTime OccurredOn { get; set; }

        public string EventType { get; set; }

        public int Version { get; set; }

        public Guid? UserId { get; set; }

        public string? CorrelationId { get; set; }
    }

    /// <summary>
    /// Event for refunded payments
    /// </summary>
    public class PaymentRefundedEvent : IPaymentRefundedEvent
    {
        public Guid PaymentId { get; set; }
        public Guid BookingId { get; set; }
        public decimal RefundAmount { get; set; }
        public string RefundReason { get; set; } = null!;
        public string RefundTransactionId { get; set; } = null!;
        public DateTime RefundedAt { get; set; }
        public PaymentMethodEnum RefundMethod { get; set; }
        public YemenBooking.Core.Enums.PaymentStatus RefundStatus { get; set; }
        public decimal OriginalAmount { get; set; }
        public string Currency { get; set; } = null!;
        public string? Notes { get; set; }
        public Guid EventId { get; set; }
        public DateTime OccurredOn { get; set; }
        public string EventType { get; set; }
        public int Version { get; set; }
        public Guid? UserId { get; set; }
        public string? CorrelationId { get; set; }

    }

    /// <summary>
    /// Event for updated payment status
    /// </summary>
    public class PaymentStatusUpdatedEvent : IPaymentStatusUpdatedEvent
    {
        public Guid PaymentId { get; set; }
        public Guid BookingId { get; set; }
        public YemenBooking.Core.Enums.PaymentStatus PreviousStatus { get; set; }
        public YemenBooking.Core.Enums.PaymentStatus NewStatus { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string? UpdateReason { get; set; }
        public Guid? UpdatedByUserId { get; set; }
        public decimal Amount { get; set; }
        public string TransactionId { get; set; } = null!;
        public string? Notes { get; set; }
        public Guid EventId { get; set; }
        public DateTime OccurredOn { get; set; }
        public string EventType { get; set; }
        public int Version { get; set; }
        public Guid? UserId { get; set; }
        public string? CorrelationId { get; set; }

    }

    /// <summary>
    /// Event for voided payments
    /// </summary>
    public class PaymentVoidedEvent : IPaymentFailedEvent
    {
        public Guid PaymentId { get; set; }
        public Guid BookingId { get; set; }
        public DateTime AttemptedAt { get; set; } = DateTime.UtcNow;
        public Guid? UserId { get; set; }
        public Money AttemptedAmount { get; set; }
        public string Method { get; set; } = null!;
        public string FailureReason { get; set; } = null!;
        public string? ErrorCode { get; set; }
                public Guid EventId { get; set; }
        public DateTime OccurredOn { get; set; }
        public string EventType { get; set; }
        public int Version { get; set; }
        public string? CorrelationId { get; set; }

    }
} 