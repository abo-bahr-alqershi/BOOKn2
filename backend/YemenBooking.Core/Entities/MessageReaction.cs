namespace YemenBooking.Core.Entities
{
    using System;
    using System.ComponentModel.DataAnnotations;

    /// <summary>
    /// كيان تفاعل على رسالة
    /// Represents a reaction to a chat message
    /// </summary>
    [Display(Name = "تفاعل الرسالة")]
    public class MessageReaction : BaseEntity<Guid>
    {
        /// <summary>
        /// الرسالة التي ينتمي إليها التفاعل
        /// Message ID this reaction belongs to
        /// </summary>
        [Display(Name = "معرف الرسالة")]
        public Guid MessageId { get; set; }

        /// <summary>
        /// المستخدم الذي قام بالتفاعل
        /// User who reacted
        /// </summary>
        [Display(Name = "معرف المستخدم")]
        public Guid UserId { get; set; }

        /// <summary>
        /// نوع التفاعل (like, love, ...)
        /// Reaction type
        /// </summary>
        [Display(Name = "نوع التفاعل")]
        public string ReactionType { get; set; } = string.Empty;
    }
} 