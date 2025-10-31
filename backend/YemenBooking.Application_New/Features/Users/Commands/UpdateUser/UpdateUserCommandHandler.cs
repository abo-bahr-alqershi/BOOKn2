using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.Users.Commands.UpdateUser
{
    /// <summary>
    /// معالج أمر تحديث بيانات المستخدم
    /// </summary>
    public class UpdateUserCommandHandler : IRequestHandler<UpdateUserCommand, ResultDto<bool>>
    {
        private readonly IUserRepository _userRepository;
        private readonly IEmailService _emailService;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<UpdateUserCommandHandler> _logger;
        private readonly IFinancialAccountingService _financialAccountingService;

        public UpdateUserCommandHandler(
            IUserRepository userRepository,
            IEmailService emailService,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<UpdateUserCommandHandler> logger,
            IFinancialAccountingService financialAccountingService)
        {
            _userRepository = userRepository;
            _emailService = emailService;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
            _financialAccountingService = financialAccountingService;
        }

        public async Task<ResultDto<bool>> Handle(UpdateUserCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تحديث بيانات المستخدم: UserId={UserId}", request.UserId);

            // التحقق من المدخلات
            if (request.UserId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف المستخدم مطلوب");
            if (request.Name != null && string.IsNullOrWhiteSpace(request.Name))
                return ResultDto<bool>.Failed("الاسم المحدث غير صالح");
            if (request.Email != null && string.IsNullOrWhiteSpace(request.Email))
                return ResultDto<bool>.Failed("البريد الإلكتروني المحدث غير صالح");

            // التحقق من الوجود
            var user = await _userRepository.GetUserByIdAsync(request.UserId, cancellationToken);
            if (user == null)
                return ResultDto<bool>.Failed("المستخدم غير موجود");

            // التحقق من الصلاحيات (المستخدم نفسه أو مسؤول)
            if (_currentUserService.Role != "Admin" && user.Id != _currentUserService.UserId)
                return ResultDto<bool>.Failed("غير مصرح لك بتحديث بيانات هذا المستخدم");

            // التحقق من قواعد العمل عند تغيير البريد الإلكتروني
            if (request.Email != null && !string.Equals(user.Email, request.Email.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                if (await _userRepository.CheckEmailExistsAsync(request.Email.Trim(), cancellationToken))
                    return ResultDto<bool>.Failed("البريد الإلكتروني مستخدم بالفعل");
                user.Email = request.Email.Trim();
                user.EmailConfirmed = false;
                user.EmailConfirmationToken = Guid.NewGuid().ToString();
                user.EmailConfirmationTokenExpires = DateTime.UtcNow.AddDays(1);
                // إرسال رسالة تأكيد البريد الإلكتروني الجديد
                await _emailService.SendEmailAsync(user.Email, "تأكيد البريد الإلكتروني",
                    $"يرجى تأكيد بريدك الإلكتروني عبر الرابط: {{your_app_url}}/verify?token={user.EmailConfirmationToken}",
                    true, cancellationToken);
            }

            // تطبيق التحديثات الممكنة
            if (request.Name != null)
                user.Name = request.Name.Trim();
            if (!string.IsNullOrWhiteSpace(request.Phone))
                user.Phone = request.Phone.Trim();
            if (!string.IsNullOrWhiteSpace(request.ProfileImage))
                user.ProfileImage = request.ProfileImage.Trim();
            
            // تحديث حالة تأكيد البريد الإلكتروني (فقط من قبل Admin)
            if (request.EmailConfirmed.HasValue && _currentUserService.Role == "Admin")
            {
                user.EmailConfirmed = request.EmailConfirmed.Value;
                user.IsEmailVerified = request.EmailConfirmed.Value;
                if (request.EmailConfirmed.Value)
                {
                    user.EmailVerifiedAt = DateTime.UtcNow;
                    user.EmailConfirmationToken = null;
                    user.EmailConfirmationTokenExpires = null;
                }
                else
                {
                    user.EmailVerifiedAt = null;
                }
            }
            
            // تحديث حالة تأكيد رقم الهاتف (فقط من قبل Admin)
            if (request.PhoneNumberConfirmed.HasValue && _currentUserService.Role == "Admin")
            {
                user.PhoneNumberConfirmed = request.PhoneNumberConfirmed.Value;
                user.IsPhoneNumberVerified = request.PhoneNumberConfirmed.Value;
                if (request.PhoneNumberConfirmed.Value)
                {
                    user.PhoneNumberVerifiedAt = DateTime.UtcNow;
                    user.PhoneNumberConfirmationCode = null;
                    user.PhoneNumberConfirmationCodeExpires = null;
                }
                else
                {
                    user.PhoneNumberVerifiedAt = null;
                }
            }

            user.UpdatedBy = _currentUserService.UserId;
            user.UpdatedAt = DateTime.UtcNow;

            // احتفظ بالقيم القديمة قبل التحديث للمراجعة
            var oldValues = new
            {
                user.Id,
                user.Name,
                user.Email,
                user.Phone,
                user.ProfileImage,
                user.EmailConfirmed,
                user.PhoneNumberConfirmed
            };

            await _userRepository.UpdateUserAsync(user, cancellationToken);

            // تسجيل التدقيق اليدوي بالقيم القديمة والجديدة
            var newValues = new
            {
                user.Id,
                user.Name,
                user.Email,
                user.Phone,
                user.ProfileImage,
                user.EmailConfirmed,
                user.PhoneNumberConfirmed
            };
            await _auditService.LogAuditAsync(
                entityType: "User",
                entityId: user.Id,
                action: AuditAction.UPDATE,
                oldValues: JsonSerializer.Serialize(oldValues),
                newValues: JsonSerializer.Serialize(newValues),
                performedBy: _currentUserService.UserId,
                notes: $"تم تحديث بيانات المستخدم {request.UserId}",
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل تحديث بيانات المستخدم بنجاح: UserId={UserId}", request.UserId);
            return ResultDto<bool>.Succeeded(true, "تم تحديث بيانات المستخدم بنجاح");
        }
    }
} 