namespace YemenBooking.Application.Features.Chat.Commands.UnarchiveConversation
{
    using System;
    using MediatR;
    using YemenBooking.Application.Common.Models;

    /// <summary>
    /// أمر لإلغاء أرشفة المحادثة
    /// Command to unarchive a chat conversation
    /// </summary>
    public class UnarchiveConversationCommand : IRequest<ResultDto>
    {
        /// <summary>
        /// معرف المحادثة المراد إلغاء أرشفتها
        /// Conversation ID to unarchive
        /// </summary>
        public Guid ConversationId { get; set; }
    }
} 