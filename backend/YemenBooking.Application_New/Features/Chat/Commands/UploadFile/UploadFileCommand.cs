using System;
using System.Text.Json.Serialization;
using MediatR;
using Microsoft.AspNetCore.Http;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Chat.DTOs;

namespace YemenBooking.Application.Features.Chat.Commands.UploadFile
{
    /// <summary>
    /// أمر لرفع ملف مرفق في الشات
    /// Command to upload a chat attachment file
    /// </summary>
    public class UploadFileCommand : IRequest<ResultDto<ChatAttachmentDto>>
    {
        /// <summary>
        /// الملف المرفوع
        /// The file to upload
        /// </summary>
        [JsonPropertyName("file")]
        public IFormFile File { get; set; } = default!;

        /// <summary>
        /// صورة مصغرة اختيارية (للفيديو عادة)
        /// Optional thumbnail image (usually for videos)
        /// </summary>
        [JsonPropertyName("thumbnail")]
        public IFormFile? Thumbnail { get; set; }

        /// <summary>
        /// نوع الرسالة الذي يحدد الفئة (text, image, audio, video, document)
        /// Message type for categorizing the attachment
        /// </summary>
        [JsonPropertyName("message_type")]
        public string MessageType { get; set; } = string.Empty;

        /// <summary>
        /// معرف المحادثة المرتبطة بالمرفق
        /// Conversation Id associated with this attachment
        /// </summary>
        public Guid ConversationId { get; set; }
    }
} 