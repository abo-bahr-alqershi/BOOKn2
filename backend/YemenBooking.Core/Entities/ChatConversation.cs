namespace YemenBooking.Core.Entities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;

    /// <summary>
    /// كيان المحادثة بين المستخدمين
    /// Represents a chat conversation between participants
    /// </summary>
    [Display(Name = "المحادثة")]
    public class ChatConversation : BaseEntity<Guid>
    {
        /// <summary>
        /// نوع المحادثة (direct أو group)
        /// Conversation type: direct or group
        /// </summary>
        [Display(Name = "نوع المحادثة")]
        public string ConversationType { get; set; } = string.Empty;

        /// <summary>
        /// عنوان المحادثة (للمجموعات)
        /// Title of conversation (for group chats)
        /// </summary>
        [Display(Name = "عنوان المحادثة")]
        public string? Title { get; set; }

        /// <summary>
        /// وصف المحادثة (اختياري)
        /// Description of conversation (optional)
        /// </summary>
        [Display(Name = "وصف المحادثة")]
        public string? Description { get; set; }

        /// <summary>
        /// مسار الصورة الرمزية للمحادثة (اختياري)
        /// Avatar path for conversation (optional)
        /// </summary>
        [Display(Name = "الصورة الرمزية")]
        public string? Avatar { get; set; }

        /// <summary>
        /// هل المحادثة مؤرشفة
        /// Indicates if the conversation is archived
        /// </summary>
        [Display(Name = "مؤرشفة")]
        public bool IsArchived { get; set; } = false;

        /// <summary>
        /// هل المحادثة صامتة
        /// Indicates if notifications are muted for this conversation
        /// </summary>
        [Display(Name = "صامتة")]
        public bool IsMuted { get; set; } = false;

        /// <summary>
        /// المرافق أو الفندق المرتبط بالمحادثة
        /// The property or hotel associated with the conversation
        /// </summary>
        [Display(Name = "معرف الفندق")]
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// الفندق المرتبط بالمحادثة
        /// Related hotel property entity
        /// </summary>
        public virtual Property? Property { get; set; }

        /// <summary>
        /// المرفقات الخاصة بهذه المحادثة
        /// Attachments in this conversation
        /// </summary>
        public virtual ICollection<ChatAttachment> Attachments { get; set; } = new List<ChatAttachment>();

        /// <summary>
        /// الرسائل المرتبطة بهذه المحادثة
        /// Messages in this conversation
        /// </summary>
        public virtual ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();

        /// <summary>
        /// المشاركون في المحادثة
        /// Participants in conversation
        /// </summary>
        public virtual ICollection<User> Participants { get; set; } = new List<User>();
    }
} 