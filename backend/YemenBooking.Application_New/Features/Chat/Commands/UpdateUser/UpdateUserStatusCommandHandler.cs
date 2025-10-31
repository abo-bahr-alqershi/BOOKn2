using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Chat;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using System;
using YemenBooking.Application.Common.Interfaces;
 
 namespace YemenBooking.Application.Features.Chat.Commands.UpdateUser
 {
     /// <summary>
     /// معالج أمر تحديث حالة المستخدم
     /// Handler for UpdateUserStatusCommand
     /// </summary>
     public class UpdateUserStatusCommandHandler : IRequestHandler<UpdateUserStatusCommand, ResultDto>
     {
        private readonly IFirebaseService _firebaseService;
        private readonly ICurrentUserService _currentUserService;

        public UpdateUserStatusCommandHandler(IFirebaseService firebaseService, ICurrentUserService currentUserService)
        {
            _firebaseService = firebaseService;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto> Handle(UpdateUserStatusCommand request, CancellationToken cancellationToken)
        {
            var userId = _currentUserService.UserId;
            // إشعار تغيّر الحالة عبر FCM (اختياري: يمكن الاستغناء عنه)
            await _firebaseService.SendNotificationAsync($"user_{userId}", "تحديث حالة المستخدم", request.Status, new System.Collections.Generic.Dictionary<string, string>
            {
                { "type", "user_status_changed" },
                { "user_id", userId.ToString() },
                { "status", request.Status }
            }, cancellationToken);
            return ResultDto.Ok(null, "تم تحديث حالة المستخدم");
        }
    }
} 