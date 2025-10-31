namespace YemenBooking.Application.Features.Chat.DTOs {
    using System;

    /// <summary>
    /// DTO لتمثيل تفاعل على رسالة
    /// DTO for MessageReaction entity
    /// </summary>
    public class MessageReactionDto
    {
        public Guid Id { get; set; }
        public Guid MessageId { get; set; }
        public Guid UserId { get; set; }
        public string ReactionType { get; set; } = string.Empty;
    }
} 