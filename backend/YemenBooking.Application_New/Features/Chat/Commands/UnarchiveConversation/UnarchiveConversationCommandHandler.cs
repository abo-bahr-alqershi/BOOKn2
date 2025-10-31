using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Chat;
using YemenBooking.Application.Common.Models;
using System.Text.Json;
using AutoMapper;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using System.Linq;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Chat.Commands.UnarchiveConversation
{
    /// <summary>
    /// معالج أمر إلغاء أرشفة المحادثة
    /// </summary>
    public class UnarchiveConversationCommandHandler : IRequestHandler<UnarchiveConversationCommand, ResultDto>
    {
        private readonly IChatConversationRepository _conversationRepo;
        private readonly ICurrentUserService _currentUserService;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMapper _mapper;
        private readonly IFirebaseService _firebaseService;
        private readonly ILogger<UnarchiveConversationCommandHandler> _logger;

        public UnarchiveConversationCommandHandler(
            IChatConversationRepository conversationRepo,
            ICurrentUserService currentUserService,
            IUnitOfWork unitOfWork,
            IMapper mapper,
            IFirebaseService firebaseService,
            ILogger<UnarchiveConversationCommandHandler> logger)
        {
            _conversationRepo = conversationRepo;
            _currentUserService = currentUserService;
            _unitOfWork = unitOfWork;
            _mapper = mapper;
            _firebaseService = firebaseService;
            _logger = logger;
        }

        public async Task<ResultDto> Handle(UnarchiveConversationCommand request, CancellationToken cancellationToken)
        {
            try
            {
                var conversation = await _conversationRepo.GetByIdAsync(request.ConversationId, cancellationToken);
                if (conversation == null)
                    return ResultDto.Failure("المحادثة غير موجودة", errorCode: "conversation_not_found");

                conversation.IsArchived = false;
                await _unitOfWork.SaveChangesAsync(cancellationToken);
                // إشعار المشاركين عبر FCM
                var userId = _currentUserService.UserId;
                foreach (var participant in conversation.Participants.Where(p => p.Id != userId))
                {
                    await _firebaseService.SendNotificationAsync($"user_{participant.Id}", "تم تحديث المحادثة", "تم إلغاء الأرشفة", new System.Collections.Generic.Dictionary<string, string>
                    {
                        { "type", "conversation_updated" },
                        { "conversation_id", conversation.Id.ToString() }
                    }, cancellationToken);
                }

                return ResultDto.Ok("تم إلغاء أرشفة المحادثة");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء إلغاء أرشفة المحادثة");
                return ResultDto.Failure("حدث خطأ أثناء إلغاء أرشفة المحادثة");
            }
        }
    }
} 