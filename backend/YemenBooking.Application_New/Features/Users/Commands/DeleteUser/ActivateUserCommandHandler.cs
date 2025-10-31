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
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Application.Features.Authentication.Services;

namespace YemenBooking.Application.Features.Users.Commands.DeleteUser
{
    /// <summary>
    /// معالج أمر تفعيل حساب المستخدم بعد تأكيد البريد الإلكتروني
    /// </summary>
    public class ActivateUserCommandHandler : IRequestHandler<ActivateUserCommand, ResultDto<bool>>
    {
        private readonly IAuthenticationService _authenticationService;
        private readonly IUserRepository _userRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<ActivateUserCommandHandler> _logger;

        public ActivateUserCommandHandler(
            IAuthenticationService authenticationService,
            IUserRepository userRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<ActivateUserCommandHandler> logger)
        {
            _authenticationService = authenticationService;
            _userRepository = userRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(ActivateUserCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تفعيل المستخدم: UserId={UserId}", request.UserId);

            // التحقق من المدخلات
            if (request.UserId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف المستخدم مطلوب");

            // التحقق من الوجود
            var user = await _userRepository.GetUserByIdAsync(request.UserId, cancellationToken);
            if (user == null)
                return ResultDto<bool>.Failed("المستخدم غير موجود");

            // تنفيذ التفعيل
            var result = await _userRepository.ActivateUserAsync(request.UserId, cancellationToken);
            if (!result)
                return ResultDto<bool>.Failed("فشل تفعيل المستخدم");

            // تسجيل التدقيق
            await _auditService.LogBusinessOperationAsync(
                "ActivateUser",
                $"تم تفعيل المستخدم {request.UserId}",
                request.UserId,
                "User",
                _currentUserService.UserId,
                null,
                cancellationToken);

            _logger.LogInformation("اكتمل تفعيل المستخدم بنجاح: UserId={UserId}", request.UserId);
            return ResultDto<bool>.Succeeded(true, "تم تفعيل المستخدم بنجاح");
        }
    }
} 