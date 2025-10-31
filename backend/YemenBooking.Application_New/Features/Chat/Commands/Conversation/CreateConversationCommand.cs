using YemenBooking.Application.Features.Chat.DTOs;

namespace YemenBooking.Application.Features.Chat.Commands.Conversation
{
    using System;
    using System.Collections.Generic;
    using MediatR;
    using YemenBooking.Application.Common.Models;

    /// <summary>
    /// أمر لإنشاء محادثة جديدة بين المستخدمين
    /// Command to create a new chat conversation
    /// </summary>
    public class CreateConversationCommand : IRequest<ResultDto<ChatConversationDto>>
    {
        /// <summary>
        /// قائمة معرفات المشاركين في المحادثة
        /// Participant IDs in the conversation
        /// </summary>
        public List<Guid> ParticipantIds { get; set; } = new List<Guid>();

        /// <summary>
        /// نوع المحادثة (direct أو group)
        /// Conversation type (direct or group)
        /// </summary>
        public string ConversationType { get; set; } = string.Empty;

        /// <summary>
        /// عنوان المحادثة (اختياري للمجموعات)
        /// Title of the conversation (optional for group chats)
        /// </summary>
        public string? Title { get; set; }

        /// <summary>
        /// وصف المحادثة (اختياري)
        /// Description of the conversation (optional)
        /// </summary>
        public string? Description { get; set; }

        /// <summary>
        /// معرف الفندق المرتبط بالمحادثة (اختياري)
        /// Associated property ID (optional)
        /// </summary>
        public Guid? PropertyId { get; set; }
    }
} 