using YemenBooking.Application.Features.Chat.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.GetMessagesByConversation
{
    using System;
    using MediatR;
    using YemenBooking.Application.Common.Models;

    /// <summary>
    /// استعلام لجلب الرسائل داخل محادثة محددة مع التقسيم
    /// Query to get messages by conversation with pagination
    /// </summary>
    public class GetMessagesByConversationQuery : IRequest<PaginatedResult<ChatMessageDto>>
    {
        /// <summary>
        /// معرف المحادثة
        /// Conversation ID
        /// </summary>
        public Guid ConversationId { get; set; }

        /// <summary>
        /// رقم الصفحة
        /// Page number
        /// </summary>
        public int PageNumber { get; set; } = 1;

        /// <summary>
        /// حجم الصفحة
        /// Page size
        /// </summary>
        public int PageSize { get; set; } = 50;

        /// <summary>
        /// تحميل الرسائل الأقدم من معرّف رسالة محددة
        /// Load messages before a specific message ID
        /// </summary>
        public Guid? BeforeMessageId { get; set; }
    }
} 