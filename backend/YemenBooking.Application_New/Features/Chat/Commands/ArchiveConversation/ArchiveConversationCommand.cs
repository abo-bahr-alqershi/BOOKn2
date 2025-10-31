namespace YemenBooking.Application.Features.Chat.Commands.ArchiveConversation
{
    using System;
    using MediatR;
    using YemenBooking.Application.Common.Models;

    /// <summary>
    /// أمر لأرشفة المحادثة
    /// Command to archive a chat conversation
    /// </summary>
    public class ArchiveConversationCommand : IRequest<ResultDto>
    {
        /// <summary>
        /// معرف المحادثة المراد أرشفتها
        /// Conversation ID to archive
        /// </summary>
        public Guid ConversationId { get; set; }
    }
} 