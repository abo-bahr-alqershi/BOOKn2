using YemenBooking.Application.Features.Chat.DTOs;

namespace YemenBooking.Application.Features.Chat.Commands.SendMessage
{
    using System;
    using System.Collections.Generic;
    using Microsoft.AspNetCore.Http;
    using MediatR;
    using YemenBooking.Application.Common.Models;

    /// <summary>
    /// أمر لإرسال رسالة في محادثة
    /// Command to send a message in a chat conversation
    /// </summary>
    public class SendMessageCommand : IRequest<ResultDto<ChatMessageDto>>
    {
        /// <summary>
        /// معرف المحادثة
        /// Conversation ID
        /// </summary>
        public Guid ConversationId { get; set; }

        /// <summary>
        /// نوع الرسالة (text, image, audio, video, document, location, reply)
        /// Message type
        /// </summary>
        public string MessageType { get; set; } = string.Empty;

        /// <summary>
        /// محتوى الرسالة (للنصوص)
        /// Content of the message (for text type)
        /// </summary>
        public string? Content { get; set; }

        /// <summary>
        /// بيانات الموقع (JSON)
        /// Location data as JSON
        /// </summary>
        public string? LocationJson { get; set; }

        /// <summary>
        /// معرف الرسالة المرد عليها (في حال الرد)
        /// Reply to message ID (if replying)
        /// </summary>
        public Guid? ReplyToMessageId { get; set; }

        /// <summary>
        /// المرفقات المرسلة مع الرسالة
        /// Attachments sent with the message
        /// </summary>
        public List<IFormFile>? Attachments { get; set; }

        /// <summary>
        /// معرفات مرفقات مرفوعة مسبقًا لإسنادها إلى الرسالة
        /// Previously uploaded attachment IDs to associate with this message
        /// </summary>
        public List<Guid>? AttachmentIds { get; set; }
    }
} 