using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Chat.Commands.Conversation
{
    /// <summary>
    /// أمر حذف محادثة
    /// Command to delete a chat conversation by ID
    /// </summary>
    public class DeleteConversationCommand : IRequest<ResultDto>
    {
        /// <summary>
        /// معرف المحادثة
        /// Conversation identifier
        /// </summary>
        public Guid ConversationId { get; set; }
    }
} 