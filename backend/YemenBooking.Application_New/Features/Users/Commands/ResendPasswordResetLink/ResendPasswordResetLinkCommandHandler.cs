using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Users.Commands.ResendPasswordResetLink
{
    /// <summary>
    /// معالج أمر إعادة إرسال رابط إعادة تعيين كلمة المرور
    /// </summary>
    public class ResendPasswordResetLinkCommandHandler : IRequestHandler<ResendPasswordResetLinkCommand, ResultDto<bool>>
    {
        private readonly IUserRepository _userRepository;
        private readonly IEmailService _emailService;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<ResendPasswordResetLinkCommandHandler> _logger;

        public ResendPasswordResetLinkCommandHandler(
            IUserRepository userRepository,
            IEmailService emailService,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<ResendPasswordResetLinkCommandHandler> logger)
        {
            _userRepository = userRepository;
            _emailService = emailService;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(ResendPasswordResetLinkCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء إعادة إرسال رابط إعادة تعيين كلمة المرور: Email={Email}", request.Email);

            // التحقق من المدخلات
            if (string.IsNullOrWhiteSpace(request.Email))
                return ResultDto<bool>.Failed("البريد الإلكتروني مطلوب");

            // التحقق من وجود المستخدم
            var user = await _userRepository.GetUserByEmailAsync(request.Email.Trim(), cancellationToken);
            if (user == null)
                return ResultDto<bool>.Failed("المستخدم غير موجود");

            // إنشاء رمز إعادة تعيين جديد
            var token = Guid.NewGuid().ToString();
            user.PasswordResetToken = token;
            user.PasswordResetTokenExpires = DateTime.UtcNow.AddHours(2);
            await _userRepository.UpdateUserAsync(user, cancellationToken);

            // إرسال بريد إعادة تعيين كلمة المرور
            var emailSent = await _emailService.SendPasswordResetEmailAsync(
                user.Email,
                user.Name,
                token,
                cancellationToken);
            if (!emailSent)
                return ResultDto<bool>.Failed("فشل في إرسال رابط إعادة تعيين كلمة المرور");

            // تسجيل التدقيق (يدوي) بدون تفاصيل حساسة
            await _auditService.LogAuditAsync(
                entityType: "User",
                entityId: user.Id,
                action: AuditAction.PASSWORD_RESET,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new { PasswordResetLinkResent = true }),
                performedBy: _currentUserService.UserId,
                notes: $"تم إرسال رابط إعادة تعيين كلمة المرور للمستخدم {user.Id}",
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل إرسال رابط إعادة تعيين كلمة المرور: Email={Email}", user.Email);
            return ResultDto<bool>.Succeeded(true, "تم إرسال رابط إعادة تعيين كلمة المرور إلى البريد الإلكتروني");
        }
    }
} 