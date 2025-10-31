using MediatR;
using System;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Chat.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.GetConversationById
{
    /// <summary>
    /// استعلام جلب محادثة واحدة بناءً على المعرف
    /// Query for retrieving a single chat conversation by its ID
    /// </summary>
    public class GetConversationByIdQuery : IRequest<ResultDto<ChatConversationDto>>
    {
        /// <summary>
        /// معرف المحادثة
        /// Conversation identifier
        /// </summary>
        public Guid ConversationId { get; set; }
    }
} 