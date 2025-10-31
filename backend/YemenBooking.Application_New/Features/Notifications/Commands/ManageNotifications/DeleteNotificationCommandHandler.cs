using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Application.Features.Notifications.Commands.ManageNotifications
{
    /// <summary>
    /// معالج حذف الإشعار
    /// </summary>
    public class DeleteNotificationCommandHandler : IRequestHandler<DeleteNotificationCommand, ResultDto<bool>>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ILogger<DeleteNotificationCommandHandler> _logger;

        public DeleteNotificationCommandHandler(IUnitOfWork unitOfWork, ILogger<DeleteNotificationCommandHandler> logger)
        {
            _unitOfWork = unitOfWork;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(DeleteNotificationCommand request, CancellationToken cancellationToken)
        {
            if (request.NotificationId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الإشعار مطلوب");

            var repo = _unitOfWork.Repository<Core.Entities.Notification>();
            var entity = await repo.GetByIdAsync(request.NotificationId, cancellationToken);
            if (entity == null) return ResultDto<bool>.Failed("الإشعار غير موجود");

            await repo.DeleteAsync(entity, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            _logger.LogInformation("تم حذف الإشعار {NotificationId}", request.NotificationId);
            return ResultDto<bool>.Succeeded(true, "تم حذف الإشعار");
        }
    }
}

