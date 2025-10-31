using System;
using MediatR;

namespace YemenBooking.Core.Interfaces
{
    /// <summary>
    /// الواجهة الرئيسية لأحداث النطاق - تمثل جميع الأحداث التي تحدث في النظام
    /// Main interface for domain events - represents all events that occur in the system
    /// </summary>
    public interface IDomainEvent : INotification
    {
        /// <summary>
        /// معرف فريد للحدث
        /// Unique identifier for the event
        /// </summary>
        Guid EventId { get; }

        /// <summary>
        /// تاريخ ووقت حدوث الحدث
        /// Date and time when the event occurred
        /// </summary>
        DateTime OccurredOn { get; }

        /// <summary>
        /// نوع الحدث (اسم الفئة)
        /// Event type (class name)
        /// </summary>
        string EventType { get; }

        /// <summary>
        /// إصدار الحدث للتوافق مع الإصدارات السابقة
        /// Event version for backward compatibility
        /// </summary>
        int Version { get; }

        /// <summary>
        /// معرف المستخدم الذي تسبب في الحدث (إن وجد)
        /// ID of the user who caused the event (if any)
        /// </summary>
        Guid? UserId { get; }

        /// <summary>
        /// معرف الجلسة أو السياق الذي حدث فيه الحدث
        /// Session or context ID where the event occurred
        /// </summary>
        string? CorrelationId { get; }
    }
}
