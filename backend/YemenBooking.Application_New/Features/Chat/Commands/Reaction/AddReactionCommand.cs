namespace YemenBooking.Application.Features.Chat.Commands.Reaction
{
    using System;
    using MediatR;
    using YemenBooking.Application.Common.Models;

    /// <summary>
    /// أمر لإضافة تفاعل على رسالة
    /// Command to add a reaction to a chat message
    /// </summary>
    public class AddReactionCommand : IRequest<ResultDto>
    {
        /// <summary>
        /// معرف الرسالة
        /// Message ID
        /// </summary>
        public Guid MessageId { get; set; }

        /// <summary>
        /// نوع التفاعل (like, love, laugh, etc.)
        /// Reaction type
        /// </summary>
        public string ReactionType { get; set; } = string.Empty;
    }
} 