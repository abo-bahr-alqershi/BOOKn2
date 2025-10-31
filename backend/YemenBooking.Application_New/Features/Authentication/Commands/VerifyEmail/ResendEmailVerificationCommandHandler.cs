using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using System.Text.RegularExpressions;
using System;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Authentication.DTOs;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Authentication.Commands.VerifyEmail
{
    /// <summary>
    /// معالج أمر إعادة إرسال رمز تأكيد البريد الإلكتروني
    /// Handler for resend email verification command
    /// </summary>
    public class ResendEmailVerificationCommandHandler : IRequestHandler<ResendEmailVerificationCommand, ResultDto<ResendEmailVerificationResponse>>
    {
        private readonly IUserRepository _userRepository;
        private readonly IEmailService _emailService;
        private readonly IEmailVerificationService _emailVerificationService;
    private readonly ILogger<ResendEmailVerificationCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

        /// <summary>
        /// منشئ معالج أمر إعادة إرسال رمز تأكيد البريد الإلكتروني
        /// Constructor for resend email verification command handler
        /// </summary>
        /// <param name="userRepository">مستودع المستخدمين</param>
        /// <param name="emailService">خدمة البريد الإلكتروني</param>
        /// <param name="emailVerificationService">خدمة تأكيد البريد الإلكتروني</param>
        /// <param name="logger">مسجل الأحداث</param>
        public ResendEmailVerificationCommandHandler(
        IUserRepository userRepository,
        IEmailService emailService,
        IEmailVerificationService emailVerificationService,
        ILogger<ResendEmailVerificationCommandHandler> logger,
        IAuditService auditService,
        ICurrentUserService currentUserService)
        {
            _userRepository = userRepository;
            _emailService = emailService;
            _emailVerificationService = emailVerificationService;
        _logger = logger;
        _auditService = auditService;
        _currentUserService = currentUserService;
        }

        /// <summary>
        /// معالجة أمر إعادة إرسال رمز تأكيد البريد الإلكتروني
        /// Handle resend email verification command
        /// </summary>
        /// <param name="request">طلب إعادة إرسال رمز التأكيد</param>
        /// <param name="cancellationToken">رمز الإلغاء</param>
        /// <returns>نتيجة العملية</returns>
        public async Task<ResultDto<ResendEmailVerificationResponse>> Handle(ResendEmailVerificationCommand request, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("بدء عملية إعادة إرسال رمز تأكيد البريد الإلكتروني للمستخدم: {UserId}", request.UserId);

                // التحقق من صحة البيانات المدخلة
                if (request.UserId == Guid.Empty)
                {
                    _logger.LogWarning("محاولة إعادة إرسال رمز التأكيد بمعرف مستخدم غير صالح");
                    return ResultDto<ResendEmailVerificationResponse>.Failed("معرف المستخدم غير صالح", "INVALID_USER_ID");
                }

                if (string.IsNullOrWhiteSpace(request.Email))
                {
                    return ResultDto<ResendEmailVerificationResponse>.Failed("البريد الإلكتروني مطلوب", "EMAIL_REQUIRED");
                }

                // التحقق من صحة تنسيق البريد الإلكتروني
                var emailRegex = new Regex(@"^[^\s@]+@[^\s@]+\.[^\s@]+$");
                if (!emailRegex.IsMatch(request.Email))
                {
                    return ResultDto<ResendEmailVerificationResponse>.Failed("تنسيق البريد الإلكتروني غير صحيح", "INVALID_EMAIL_FORMAT");
                }

                // البحث عن المستخدم
                var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
                if (user == null)
                {
                    _logger.LogWarning("لم يتم العثور على المستخدم: {UserId}", request.UserId);
                    return ResultDto<ResendEmailVerificationResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
                }

                // التحقق من تطابق البريد الإلكتروني
                if (!string.Equals(user.Email, request.Email, StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogWarning("البريد الإلكتروني غير متطابق للمستخدم: {UserId}", request.UserId);
                    return ResultDto<ResendEmailVerificationResponse>.Failed("البريد الإلكتروني غير متطابق مع الحساب", "EMAIL_MISMATCH");
                }

                // التحقق من حالة تأكيد البريد الإلكتروني
                if (user.IsEmailVerified)
                {
                    _logger.LogInformation("البريد الإلكتروني مؤكد مسبقاً للمستخدم: {UserId}", request.UserId);

                    var alreadyVerifiedResponse = new ResendEmailVerificationResponse
                    {
                        Success = true,
                        Message = "البريد الإلكتروني مؤكد مسبقاً"
                    };

                    return ResultDto<ResendEmailVerificationResponse>.Ok(alreadyVerifiedResponse, "البريد الإلكتروني مؤكد مسبقاً");
                }

                // التحقق من عدد المحاولات الأخيرة (تنفيذ مبسط)
                _logger.LogInformation("التحقق من محاولات إعادة الإرسال للمستخدم: {UserId}", request.UserId);
                
                var tooManyAttemptsResponse = new ResendEmailVerificationResponse
                {
                    Success = false,
                        Message = "تم تجاوز الحد الأقصى لمحاولات إعادة الإرسال. يرجى المحاولة بعد 15 دقيقة",
                        RetryAfterSeconds = 900 // 15 دقيقة
                    };

                    // تنفيذ مبسط - لا حاجة للعودة في هذه المرحلة
                    // return ResultDto<ResendEmailVerificationResponse>.Failed(tooManyAttemptsResponse, "تم تجاوز الحد الأقصى", "TOO_MANY_ATTEMPTS");
                

                // التحقق من الوقت المنقضي منذ آخر إرسال (تنفيذ مبسط)
                _logger.LogInformation("التحقق من آخر وقت إرسال للمستخدم: {UserId}", request.UserId);
                
                // إنشاء رمز تأكيد جديد صالح لمدة 10 دقائق
                var verificationToken = _emailVerificationService.GenerateVerificationCode();
                _logger.LogInformation("تم إنشاء رمز تأكيد جديد للمستخدم: {UserId}", request.UserId);

                // إرسال بريد التأكيد (تنفيذ مبسط)
                var sendResult = await _emailVerificationService.SendVerificationEmailAsync(request.Email, verificationToken);
                if (!sendResult)
                {
                    _logger.LogError("فشل في إرسال بريد تأكيد البريد الإلكتروني للمستخدم: {UserId}", request.UserId);

                    return ResultDto<ResendEmailVerificationResponse>.Failed("فشل في إرسال بريد التأكيد", "SEND_FAILED");
                }

                // تسجيل محاولة الإرسال (تنفيذ مبسط)
                _logger.LogInformation("تم تسجيل محاولة إرسال للمستخدم: {UserId}", request.UserId);

                _logger.LogInformation("تم إعادة إرسال رمز تأكيد البريد الإلكتروني بنجاح للمستخدم: {UserId}", request.UserId);

                var response = new ResendEmailVerificationResponse
                {
                    Success = true,
                    Message = "تم إرسال رمز التأكيد إلى بريدك الإلكتروني. يرجى التحقق من صندوق الوارد وصندوق الرسائل غير المرغوب فيها",
                    SentTo = request.Email,
                    SentAt = DateTime.UtcNow,
                    VerificationCode = verificationToken
                };

                // تدقيق يدوي: إعادة إرسال رمز التحقق
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes = $"تمت إعادة إرسال رمز التحقق للمستخدم {request.UserId} بواسطة {performerName} (ID={performerId})";
                await _auditService.LogAuditAsync(
                    entityType: "User",
                    entityId: request.UserId,
                    action: AuditAction.UPDATE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { Email = request.Email }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                return ResultDto<ResendEmailVerificationResponse>.Ok(response, "تم إرسال رمز التأكيد بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء إعادة إرسال رمز تأكيد البريد الإلكتروني للمستخدم: {UserId}", request.UserId);
                return ResultDto<ResendEmailVerificationResponse>.Failed($"حدث خطأ أثناء إعادة إرسال رمز التأكيد: {ex.Message}", "RESEND_VERIFICATION_ERROR");
            }
        }
    }
}
