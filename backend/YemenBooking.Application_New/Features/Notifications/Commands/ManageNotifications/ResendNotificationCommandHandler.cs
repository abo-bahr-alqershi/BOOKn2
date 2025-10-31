using System;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Notifications.Services;

namespace YemenBooking.Application.Features.Notifications.Commands.ManageNotifications
{
    /// <summary>
    /// معالج إعادة إرسال إشعار فشل سابقًا
    /// </summary>
    public class ResendNotificationCommandHandler : IRequestHandler<ResendNotificationCommand, ResultDto<bool>>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INotificationService _notificationService;
        private readonly ILogger<ResendNotificationCommandHandler> _logger;

        public ResendNotificationCommandHandler(
            IUnitOfWork unitOfWork,
            INotificationService notificationService,
            ILogger<ResendNotificationCommandHandler> logger)
        {
            _unitOfWork = unitOfWork;
            _notificationService = notificationService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(ResendNotificationCommand request, CancellationToken cancellationToken)
        {
            if (request.NotificationId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الإشعار مطلوب");

            var repo = _unitOfWork.Repository<Notification>();
            var entity = await repo.GetByIdAsync(request.NotificationId, cancellationToken);
            if (entity == null)
                return ResultDto<bool>.Failed("الإشعار غير موجود");

            try
            {
                await _notificationService.SendAsync(new YemenBooking.Core.Notifications.NotificationRequest
                {
                    UserId = entity.RecipientId,
                    Title = entity.Title,
                    Message = entity.Message,
                    Type = Enum.TryParse<YemenBooking.Core.Notifications.NotificationType>(entity.Type, true, out var t)
                        ? t : YemenBooking.Core.Notifications.NotificationType.BookingUpdated,
                    Data = string.IsNullOrWhiteSpace(entity.Data) ? null : JsonSerializer.Deserialize<object>(entity.Data)
                }, cancellationToken);

                entity.MarkAsSent(request.Channel ?? "IN_APP");
                await repo.UpdateAsync(entity, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);
                return ResultDto<bool>.Succeeded(true, "تمت إعادة إرسال الإشعار");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "فشل إعادة إرسال الإشعار {NotificationId}", request.NotificationId);
                entity.MarkAsFailed(ex.Message);
                await repo.UpdateAsync(entity, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);
                return ResultDto<bool>.Failed("فشل إعادة إرسال الإشعار");
            }
        }
    }
}

