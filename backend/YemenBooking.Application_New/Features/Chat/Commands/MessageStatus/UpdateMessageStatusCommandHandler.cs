using System;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Chat;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Chat.Commands.MessageStatus
{
    /// <summary>
    /// معالج أمر تحديث حالة الرسالة (sent, delivered, read, failed)
    /// </summary>
    public class UpdateMessageStatusCommandHandler : IRequestHandler<UpdateMessageStatusCommand, ResultDto>
    {
        private readonly IChatMessageRepository _messageRepo;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IFirebaseService _firebaseService;
        private readonly IMapper _mapper;
        private readonly ILogger<UpdateMessageStatusCommandHandler> _logger;

        public UpdateMessageStatusCommandHandler(
            IChatMessageRepository messageRepo,
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            IFirebaseService firebaseService,
            IMapper mapper,
            ILogger<UpdateMessageStatusCommandHandler> logger)
        {
            _messageRepo = messageRepo;
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _firebaseService = firebaseService;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<ResultDto> Handle(UpdateMessageStatusCommand request, CancellationToken cancellationToken)
        {
            try
            {
                var message = await _messageRepo.GetByIdAsync(request.MessageId, cancellationToken);
                if (message == null)
                    return ResultDto.Failed("الرسالة غير موجودة", errorCode: "message_not_found");

                message.Status = request.Status;
                var now = DateTime.UtcNow;
                if (request.Status.Equals("delivered", StringComparison.OrdinalIgnoreCase))
                    message.DeliveredAt = now;
                else if (request.Status.Equals("read", StringComparison.OrdinalIgnoreCase))
                    message.ReadAt = now;
                message.UpdatedAt = now;

                await _messageRepo.UpdateAsync(message, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // إشعار المُرسل عبر FCM بحالة الرسالة دون عرض إشعار مرئي على الجهاز
                // نرسل بيانات فقط (data-only) بحيث يتجاهل العميل عرض إشعار ويكتفي بتحديث الحالة
                // Convert timestamps to user's local for payload values
                var deliveredLocal = message.DeliveredAt.HasValue ? (await _currentUserService.ConvertFromUtcToUserLocalAsync(message.DeliveredAt.Value)).ToString("o") : string.Empty;
                var readLocal = message.ReadAt.HasValue ? (await _currentUserService.ConvertFromUtcToUserLocalAsync(message.ReadAt.Value)).ToString("o") : string.Empty;
                await _firebaseService.SendNotificationAsync($"user_{message.SenderId}", string.Empty, string.Empty, new System.Collections.Generic.Dictionary<string, string>
                {
                    { "type", "message_status_updated" },
                    { "conversation_id", message.ConversationId.ToString() },
                    { "message_id", message.Id.ToString() },
                    { "status", message.Status },
                    { "read_at", readLocal },
                    { "delivered_at", deliveredLocal },
                    { "silent", "true" }
                }, cancellationToken);

                return ResultDto.Ok(null, "تم تحديث حالة الرسالة");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تحديث حالة الرسالة");
                return ResultDto.Failed("حدث خطأ أثناء تحديث حالة الرسالة");
            }
        }
    }
} 