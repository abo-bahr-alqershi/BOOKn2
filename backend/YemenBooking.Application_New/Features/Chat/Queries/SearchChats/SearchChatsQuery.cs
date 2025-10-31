using YemenBooking.Application.Features.Chat.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.SearchChats
{
    using System;
    using global::YemenBooking.Application.Common.Models;
    using MediatR;

    /// <summary>
    /// استعلام البحث في المحادثات والرسائل
    /// Query for searching chats and messages
    /// </summary>
    public class SearchChatsQuery : IRequest<ResultDto<SearchChatsResultDto>>
    {
        public string Query { get; set; } = string.Empty;
        public Guid? ConversationId { get; set; }
        public string? MessageType { get; set; }
        public Guid? SenderId { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
        public int Page { get; set; } = 1;
        public int Limit { get; set; } = 20;
    }
} 