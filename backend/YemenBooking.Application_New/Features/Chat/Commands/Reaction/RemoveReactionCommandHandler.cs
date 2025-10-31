using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Chat;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces; // Added for IUnitOfWork
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Chat.Commands.Reaction
{
    /// <summary>
    /// معالج أمر إزالة تفاعل من رسالة
    /// </summary>
    public class RemoveReactionCommandHandler : IRequestHandler<RemoveReactionCommand, ResultDto>
    {
        private readonly IMessageReactionRepository _reactionRepo;
        private readonly IChatMessageRepository _messageRepo;
        private readonly IChatConversationRepository _conversationRepo;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IFirebaseService _firebaseService;
        private readonly ILogger<RemoveReactionCommandHandler> _logger;

        public RemoveReactionCommandHandler(
            IMessageReactionRepository reactionRepo,
            IChatMessageRepository messageRepo,
            IChatConversationRepository conversationRepo,
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            IFirebaseService firebaseService,
            ILogger<RemoveReactionCommandHandler> logger)
        {
            _reactionRepo = reactionRepo;
            _messageRepo = messageRepo;
            _conversationRepo = conversationRepo;
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _firebaseService = firebaseService;
            _logger = logger;
        }

        public async Task<ResultDto> Handle(RemoveReactionCommand request, CancellationToken cancellationToken)
        {
            try
            {
                var userId = _currentUserService.UserId;
                _logger.LogInformation("المستخدم {UserId} يزيل تفاعل {ReactionType} من الرسالة {MessageId}", userId, request.ReactionType, request.MessageId);

                var reaction = (await _unitOfWork.Repository<MessageReaction>()
                    .FindAsync(r => r.MessageId == request.MessageId && r.UserId == userId && r.ReactionType == request.ReactionType, cancellationToken))
                    .FirstOrDefault();
                if (reaction == null)
                    return ResultDto.Failure("التفاعل غير موجود");

                await _unitOfWork.Repository<MessageReaction>().DeleteAsync(reaction, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // إشعار جميع المشاركين عبر FCM (بما فيهم المنفذ للعملية) صامتاً لتحديث الواجهة فوراً
                var message = await _messageRepo.GetByIdAsync(request.MessageId, cancellationToken);
                // Ensure participants are loaded to notify all reliably
                var conversation = await _conversationRepo.GetByIdWithDetailsAsync(message.ConversationId, cancellationToken)
                                   ?? await _conversationRepo.GetByIdAsync(message.ConversationId, cancellationToken);
                var dataPayload = new System.Collections.Generic.Dictionary<string, string>
                {
                    { "type", "reaction_removed" },
                    { "conversation_id", message.ConversationId.ToString() },
                    { "message_id", message.Id.ToString() },
                    { "user_id", userId.ToString() },
                    { "reaction_type", request.ReactionType },
                    { "silent", "true" }
                };

                await _firebaseService.SendNotificationAsync($"user_{userId}", string.Empty, string.Empty, dataPayload, cancellationToken);
                foreach (var participant in conversation.Participants)
                {
                    if (participant.Id == userId) continue;
                    await _firebaseService.SendNotificationAsync($"user_{participant.Id}", string.Empty, string.Empty, dataPayload, cancellationToken);
                }

                return ResultDto.Ok("تم إزالة التفاعل بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء إزالة التفاعل");
                return ResultDto.Failure("حدث خطأ أثناء إزالة التفاعل");
            }
        }
    }
} 