using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Authentication.Commands.UpdateProfile
{
    public class UploadUserProfileImageCommandHandler : IRequestHandler<UploadUserProfileImageCommand, ResultDto<UploadUserProfileImageResponse>>
    {
        private readonly IUserRepository _userRepository;
        private readonly IFileUploadService _fileUploadService;
    private readonly ILogger<UploadUserProfileImageCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

        public UploadUserProfileImageCommandHandler(
            IUserRepository userRepository,
            IFileUploadService fileUploadService,
            ILogger<UploadUserProfileImageCommandHandler> logger,
            IAuditService auditService,
            ICurrentUserService currentUserService)
        {
            _userRepository = userRepository;
            _fileUploadService = fileUploadService;
            _logger = logger;
            _auditService = auditService;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<UploadUserProfileImageResponse>> Handle(UploadUserProfileImageCommand request, CancellationToken cancellationToken)
        {
            try
            {
                if (request.UserId == Guid.Empty)
                {
                    return ResultDto<UploadUserProfileImageResponse>.Failed("معرف المستخدم غير صالح", "INVALID_USER_ID");
                }
                if (request.FileBytes == null || request.FileBytes.Length == 0)
                {
                    return ResultDto<UploadUserProfileImageResponse>.Failed("لا توجد صورة مرفوعة", "FILE_EMPTY");
                }
                var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
                if (!_fileUploadService.IsValidFileType(request.FileName, allowed))
                {
                    return ResultDto<UploadUserProfileImageResponse>.Failed("نوع الملف غير مدعوم", "INVALID_FILE_TYPE");
                }
                if (!_fileUploadService.IsValidFileSize(request.FileBytes.LongLength, 5))
                {
                    return ResultDto<UploadUserProfileImageResponse>.Failed("حجم الملف يتجاوز 5MB", "FILE_TOO_LARGE");
                }

                var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
                if (user == null)
                {
                    return ResultDto<UploadUserProfileImageResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
                }

                using var stream = new MemoryStream(request.FileBytes);
                var uniqueName = _fileUploadService.GenerateUniqueFileName(request.FileName);
                var imageUrl = await _fileUploadService.UploadProfileImageAsync(stream, uniqueName, cancellationToken);

                user.ProfileImageUrl = imageUrl;
                user.ProfileImage = imageUrl; // keep legacy/alt field in sync
                user.UpdatedAt = DateTime.UtcNow;
                await _userRepository.UpdateUserAsync(user, cancellationToken);

                var response = new UploadUserProfileImageResponse
                {
                    UserId = user.Id,
                    ProfileImageUrl = user.ProfileImageUrl,
                    UpdatedAt = user.UpdatedAt
                };

                // تدقيق يدوي: تحديث صورة الملف
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes = $"تم تحديث صورة الملف للمستخدم {user.Id} بواسطة {performerName} (ID={performerId})";
                await _auditService.LogAuditAsync(
                    entityType: "User",
                    entityId: user.Id,
                    action: YemenBooking.Core.Entities.AuditAction.UPDATE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { ProfileImageUrl = user.ProfileImageUrl }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                return ResultDto<UploadUserProfileImageResponse>.Ok(response, "تم رفع صورة الملف الشخصي بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "فشل رفع صورة الملف الشخصي للمستخدم {UserId}", request.UserId);
                return ResultDto<UploadUserProfileImageResponse>.Failed("حدث خطأ أثناء رفع الصورة", "UPLOAD_FAILED");
            }
        }
    }
}