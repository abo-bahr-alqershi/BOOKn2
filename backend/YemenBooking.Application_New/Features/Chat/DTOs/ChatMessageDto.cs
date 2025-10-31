using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Chat.DTOs {
    using System;
    using System.Collections.Generic;
    using System.Text.Json.Serialization;

    /// <summary>
    /// DTO لتمثيل رسالة المحادثة
    /// DTO for ChatMessage entity
    /// </summary>
    public class ChatMessageDto
    {
        [JsonPropertyName("message_id")]
        public Guid Id { get; set; }
        public Guid ConversationId { get; set; }
        public Guid SenderId { get; set; }
        public string MessageType { get; set; } = string.Empty;
        public string? Content { get; set; }
        public LocationDto? Location { get; set; }
        public Guid? ReplyToMessageId { get; set; }
        public IEnumerable<MessageReactionDto> Reactions { get; set; } = new List<MessageReactionDto>();
        public IEnumerable<ChatAttachmentDto> Attachments { get; set; } = new List<ChatAttachmentDto>();
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        /// <summary>
        /// حالة الرسالة (sent, delivered, read, failed)
        /// Message status
        /// </summary>
        public string Status { get; set; } = string.Empty;

        /// <summary>
        /// Indicates if the message was edited
        /// ما إذا كانت الرسالة معدلة
        /// </summary>
        public bool IsEdited { get; set; }

        /// <summary>
        /// Timestamp when the message was edited
        /// وقت تعديل الرسالة
        /// </summary>
        public DateTime? EditedAt { get; set; }

        /// <summary>
        /// إيصال التسليم والقراءة
        /// Delivery and read receipt
        /// </summary>
        public DeliveryReceiptDto? DeliveryReceipt { get; set; }
    }

    /// <summary>
    /// DTO لإيصال التسليم والقراءة
    /// DTO for delivery and read receipt
    /// </summary>
    public class DeliveryReceiptDto
    {
        /// <summary>
        /// وقت تسليم الرسالة
        /// Delivered timestamp
        /// </summary>
        public DateTime? DeliveredAt { get; set; }

        /// <summary>
        /// وقت قراءة الرسالة
        /// Read timestamp
        /// </summary>
        public DateTime? ReadAt { get; set; }

        /// <summary>
        /// قائمة معرفات المستخدمين الذين قرأوا الرسالة
        /// List of user IDs who read the message
        /// </summary>
        public IEnumerable<string>? ReadBy { get; set; }
    }
} 