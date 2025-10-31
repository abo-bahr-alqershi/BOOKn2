using YemenBooking.Application.Features.Users.DTOs;

namespace YemenBooking.Application.Features.Chat.DTOs {
    using System;
    using System.Collections.Generic;
    using YemenBooking.Application.Features.Users; // Added for UserDto
    using System.Text.Json.Serialization;

    /// <summary>
    /// DTO لتمثيل المحادثة بين المستخدمين
    /// DTO for ChatConversation entity
    /// </summary>
    public class ChatConversationDto
    {
        [JsonPropertyName("id")]
        public Guid Id { get; set; }
        [JsonPropertyName("conversationType")]
        public string ConversationType { get; set; } = string.Empty;
        [JsonPropertyName("title")]
        public string? Title { get; set; }
        [JsonPropertyName("description")]
        public string? Description { get; set; }
        [JsonPropertyName("avatar")]
        public string? Avatar { get; set; }
        [JsonPropertyName("createdAt")]
        public DateTime CreatedAt { get; set; }
        [JsonPropertyName("updatedAt")]
        public DateTime UpdatedAt { get; set; }
        [JsonPropertyName("lastMessage")]
        public ChatMessageDto? LastMessage { get; set; }
        [JsonPropertyName("lastMessageTime")]
        public DateTime? LastMessageTime { get; set; }
        [JsonPropertyName("unreadCount")]
        public int UnreadCount { get; set; }
        [JsonPropertyName("isArchived")]
        public bool IsArchived { get; set; }
        [JsonPropertyName("isMuted")]
        public bool IsMuted { get; set; }
       
        /// <summary>
        /// معرّف الفندق المرتبط بالمحادثة
        /// Property ID associated with the conversation
        /// </summary>
        [JsonPropertyName("propertyId")]
        public Guid? PropertyId { get; set; }

        [JsonPropertyName("participants")]
        public IEnumerable<ChatUserDto> Participants { get; set; } = new List<ChatUserDto>();
    }
} 