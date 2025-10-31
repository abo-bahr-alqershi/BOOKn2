namespace YemenBooking.Application.Features.Chat.DTOs {
    using System;
    using System.Text.Json.Serialization;

    /// <summary>
    /// DTO لتمثيل مرفق المحادثة
    /// DTO for ChatAttachment entity
    /// </summary>
    public class ChatAttachmentDto
    {
        [JsonPropertyName("conversation_id")]
        public Guid ConversationId { get; set; }

        [JsonPropertyName("attachment_id")]
        public Guid Id { get; set; }

        [JsonPropertyName("file_name")]
        public string FileName { get; set; } = string.Empty;

        [JsonPropertyName("mime_type")]
        public string ContentType { get; set; } = string.Empty;

        [JsonPropertyName("file_size")]
        public long FileSize { get; set; }

        [JsonIgnore]
        public string FilePath { get; set; } = string.Empty;

        [JsonPropertyName("uploaded_by")]
        public Guid UploadedBy { get; set; }

        [JsonPropertyName("uploaded_at")]
        public DateTime CreatedAt { get; set; }

        [JsonPropertyName("file_url")]
        public string FileUrl => $"/api/common/chat/attachments/{Id}";
        [JsonPropertyName("thumbnail_url")]
        public string? ThumbnailUrl { get; set; }
        [JsonPropertyName("metadata")]
        public string? Metadata { get; set; }

        /// <summary>
        /// الرسالة المرتبط بها هذا المرفق (لتمكين التجميع الأمامي)
        /// </summary>
        [JsonPropertyName("message_id")]
        public Guid? MessageId { get; set; }

        /// <summary>
        /// مدة المرفق بالثواني (للصوت/الفيديو)
        /// Attachment duration in seconds (audio/video)
        /// </summary>
        [JsonPropertyName("duration")]
        public int? DurationSeconds { get; set; }
    }
}