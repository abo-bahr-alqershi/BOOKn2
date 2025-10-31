using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Users.Commands.UpdateUser
{
    /// <summary>
    /// معالج أمر تحديث صورة ملف المستخدم الشخصي
    /// </summary>
    public class UpdateUserProfilePictureCommandHandler : IRequestHandler<UpdateUserProfilePictureCommand, ResultDto<bool>>
    {
        private readonly IUserRepository _userRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<UpdateUserProfilePictureCommandHandler> _logger;

        public UpdateUserProfilePictureCommandHandler(
            IUserRepository userRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<UpdateUserProfilePictureCommandHandler> logger)
        {
            _userRepository = userRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(UpdateUserProfilePictureCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تحديث صورة المستخدم: UserId={UserId}", request.UserId);

            // التحقق من المدخلات
            if (request.UserId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف المستخدم مطلوب");
            if (string.IsNullOrWhiteSpace(request.ProfileImageUrl))
                return ResultDto<bool>.Failed("رابط الصورة مطلوب");

            // التحقق من الوجود
            var user = await _userRepository.GetUserByIdAsync(request.UserId, cancellationToken);
            if (user == null)
                return ResultDto<bool>.Failed("المستخدم غير موجود");

            // التحقق من الصلاحيات (المستخدم نفسه أو مسؤول)
            if (_currentUserService.Role != "Admin" && user.Id != _currentUserService.UserId)
                return ResultDto<bool>.Failed("غير مصرح لك بتحديث صورة الملف الشخصي لهذا المستخدم");

            // التنفيذ
            user.ProfileImage = request.ProfileImageUrl.Trim();
            user.UpdatedBy = _currentUserService.UserId;
            user.UpdatedAt = DateTime.UtcNow;
            await _userRepository.UpdateUserAsync(user, cancellationToken);

            // تسجيل التدقيق اليدوي مع القيم القديمة والجديدة الملخصة
            await _auditService.LogAuditAsync(
                entityType: "User",
                entityId: request.UserId,
                action: AuditAction.UPDATE,
                oldValues: JsonSerializer.Serialize(new { ProfileImage = "previous" }),
                newValues: JsonSerializer.Serialize(new { ProfileImage = user.ProfileImage }),
                performedBy: _currentUserService.UserId,
                notes: $"تم تحديث صورة الملف الشخصي للمستخدم {request.UserId}",
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل تحديث صورة الملف الشخصي بنجاح: UserId={UserId}", request.UserId);
            return ResultDto<bool>.Succeeded(true, "تم تحديث صورة الملف الشخصي بنجاح");
        }
    }
} 