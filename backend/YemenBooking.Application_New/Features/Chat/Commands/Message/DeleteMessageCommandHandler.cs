using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Chat;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using System.Text.Json;
using YemenBooking.Application.Infrastructure.Services;
 
 namespace YemenBooking.Application.Features.Chat.Commands.Message
 {
     /// <summary>
     /// معالج أمر حذف رسالة المحادثة
     /// Handler for DeleteMessageCommand
     /// </summary>
     public class DeleteMessageCommandHandler : IRequestHandler<DeleteMessageCommand, ResultDto>
     {
        private readonly IChatMessageRepository _messageRepo;
        private readonly IChatConversationRepository _conversationRepo;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IFirebaseService _firebaseService;
 
        public DeleteMessageCommandHandler(IChatMessageRepository messageRepo, IChatConversationRepository conversationRepo, IUnitOfWork unitOfWork, IFirebaseService firebaseService)
        {
            _messageRepo = messageRepo;
            _conversationRepo = conversationRepo;
            _unitOfWork = unitOfWork;
            _firebaseService = firebaseService;
        }
 
        public async Task<ResultDto> Handle(DeleteMessageCommand request, CancellationToken cancellationToken)
        {
            var message = await _messageRepo.GetByIdAsync(request.MessageId, cancellationToken);
            if (message == null)
                return ResultDto.Failed("الرسالة غير موجودة");

            await _messageRepo.DeleteAsync(message, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // إرسال إشعار حذف الرسالة عبر FCM
            var conversation = await _conversationRepo.GetByIdAsync(message.ConversationId, cancellationToken);
            foreach (var participant in conversation.Participants)
            {
                await _firebaseService.SendNotificationAsync($"user_{participant.Id}", "تم حذف رسالة", string.Empty, new System.Collections.Generic.Dictionary<string, string>
                {
                    { "type", "message_deleted" },
                    { "conversation_id", message.ConversationId.ToString() },
                    { "message_id", message.Id.ToString() }
                }, cancellationToken);
            }

            return ResultDto.Ok(null, "تم حذف الرسالة بنجاح");
        }
    }
} 