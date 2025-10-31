// Create new DTO for search result
using YemenBooking.Application.Common.Models;
namespace YemenBooking.Application.Features.Chat.DTOs {
    using System;
    using System.Collections.Generic;

    /// <summary>
    /// نتيجة البحث في المحادثات والرسائل
    /// Search result DTO for chats and messages
    /// </summary>
    public class SearchChatsResultDto
    {
        public IEnumerable<ChatMessageDto> Messages { get; set; } = new List<ChatMessageDto>();
        public IEnumerable<ChatConversationDto> Conversations { get; set; } = new List<ChatConversationDto>();
        public int TotalCount { get; set; }
        public bool HasMore { get; set; }
        public int? NextPageNumber { get; set; }
    }
} 