namespace YemenBooking.Application.Features.Chat.Commands.MessageStatus
{
    using System;
    using MediatR;
    using YemenBooking.Application.Common.Models;

    /// <summary>
    /// أمر لتحديث حالة الرسالة (sent, delivered, read, failed)
    /// Command to update a chat message's status
    /// </summary>
    public class UpdateMessageStatusCommand : IRequest<ResultDto>
    {
        /// <summary>
        /// معرف الرسالة
        /// Message ID
        /// </summary>
        public Guid MessageId { get; set; }

        /// <summary>
        /// الحالة الجديدة للرسالة
        /// New status of the message
        /// </summary>
        public string Status { get; set; } = string.Empty;

        /// <summary>
        /// المعرف الخاص بمن قام بالقراءة (اختياري)
        /// Read-by user ID (optional)
        /// </summary>
        public Guid? ReadBy { get; set; }
    }
} 