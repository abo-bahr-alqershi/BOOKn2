namespace YemenBooking.Core.Entities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;

    /// <summary>
    /// كيان رسالة داخل محادثة
    /// Represents a message in a chat conversation
    /// </summary>
    [Display(Name = "رسالة المحادثة")]
    public class ChatMessage : BaseEntity<Guid>
    {
        /// <summary>
        /// المحادثة التي تنتمي إليها الرسالة
        /// The conversation ID this message belongs to
        /// </summary>
        [Display(Name = "معرف المحادثة")]
        public Guid ConversationId { get; set; }

        /// <summary>
        /// المستخدم المرسل للرسالة
        /// ID of the user who sent the message
        /// </summary>
        [Display(Name = "مرسل الرسالة")]
        public Guid SenderId { get; set; }

        /// <summary>
        /// Navigation property للمستخدم المرسل
        /// Navigation property for the sender user
        /// </summary>
        [ForeignKey(nameof(SenderId))]
        public virtual User? Sender { get; set; }

        /// <summary>
        /// Navigation property للمحادثة
        /// Navigation property for the conversation
        /// </summary>
        [ForeignKey(nameof(ConversationId))]
        public virtual ChatConversation? Conversation { get; set; }

        /// <summary>
        /// نوع الرسالة (text, image, etc.)
        /// Type of message
        /// </summary>
        [Display(Name = "نوع الرسالة")]
        public string MessageType { get; set; } = string.Empty;

        /// <summary>
        /// محتوى الرسالة (للنصوص)
        /// Content of the message for text type
        /// </summary>
        [Display(Name = "محتوى الرسالة")]
        public string? Content { get; set; }

        /// <summary>
        /// بيانات الموقع إذا كانت رسالة موقع
        /// Location data if message type is location
        /// </summary>
        public string? LocationJson { get; set; }

        /// <summary>
        /// الرد على رسالة أخرى (MessageId)
        /// ReplyTo message ID if this is a reply
        /// </summary>
        [Display(Name = "معرّف الرسالة المرد عليها")]
        public Guid? ReplyToMessageId { get; set; }

        /// <summary>
        /// Navigation property للرسالة المرد عليها
        /// Navigation property for the replied message
        /// </summary>
        [ForeignKey(nameof(ReplyToMessageId))]
        public virtual ChatMessage? ReplyToMessage { get; set; }

        /// <summary>
        /// حالة الرسالة (SENT, DELIVERED, READ, FAILED)
        /// Status of the chat message
        /// </summary>
        public string Status { get; set; } = string.Empty;

        /// <summary>
        /// Indicates if the message was edited
        /// هل تم تعديل الرسالة
        /// </summary>
        public bool IsEdited { get; set; }

        /// <summary>
        /// Time when the message was edited
        /// وقت تعديل الرسالة
        /// </summary>
        public DateTime? EditedAt { get; set; }

        /// <summary>
        /// Time when the message was delivered
        /// وقت تسليم الرسالة
        /// </summary>
        public DateTime? DeliveredAt { get; set; }

        /// <summary>
        /// Time when the message was read
        /// وقت قراءة الرسالة
        /// </summary>
        public DateTime? ReadAt { get; set; }

        /// <summary>
        /// التفاعلات مع هذه الرسالة
        /// Reactions to this message
        /// </summary>
        public virtual ICollection<MessageReaction> Reactions { get; set; } = new List<MessageReaction>();

        /// <summary>
        /// المرفقات المرتبطة بهذه الرسالة
        /// Attachments for this message
        /// </summary>
        public virtual ICollection<ChatAttachment> Attachments { get; set; } = new List<ChatAttachment>();
    }
}