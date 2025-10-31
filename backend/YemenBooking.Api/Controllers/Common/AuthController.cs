using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Authentication.Commands.Login;
using YemenBooking.Application.Features.Authentication.Commands.RefreshToken;
using YemenBooking.Application.Features.Authentication.Commands.PasswordReset;
using YemenBooking.Application.Features.Authentication.Commands.ChangePassword;
using YemenBooking.Application.Features.Authentication.Commands.VerifyEmail;
using YemenBooking.Application.Features.Users.Commands.ResendPasswordResetLink;

namespace YemenBooking.Api.Controllers.Common
{
    /// <summary>
    /// متحكم بعمليات المصادقة: تسجيل الدخول، تحديث التوكن، وإدارة استعادة الحساب
    /// Controller for authentication operations: login, refresh token, password resets, and email verification
    /// </summary>
    public class AuthController : BaseCommonController
    {
        public AuthController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// تسجيل الدخول للمستخدم وإصدار رموز المصادقة
        /// User login and token issuance
        /// </summary>
        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث رمز المصادقة باستخدام رمز التحديث
        /// Refresh authentication token using a refresh token
        /// </summary>
        [AllowAnonymous]
        [HttpPost("refresh-token")]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إرسال رابط إعادة تعيين كلمة المرور للمستخدم
        /// Send password reset link to user
        /// </summary>
        [AllowAnonymous]
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إعادة تعيين كلمة المرور باستخدام الرمز المرسل
        /// Reset user password using provided token
        /// </summary>
        [AllowAnonymous]
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إعادة إرسال رابط التحقق من البريد الإلكتروني
        /// Resend email verification link
        /// </summary>
        [AllowAnonymous]
        [HttpPost("resend-email-verification")]
        public async Task<IActionResult> ResendEmailVerification([FromBody] ResendEmailVerificationLinkCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إعادة إرسال رابط استعادة كلمة المرور
        /// Resend password reset link
        /// </summary>
        [AllowAnonymous]
        [HttpPost("resend-password-reset")]
        public async Task<IActionResult> ResendPasswordReset([FromBody] ResendPasswordResetLinkCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// التحقق من صحة عنوان البريد الإلكتروني للمستخدم
        /// Verify user email address
        /// </summary>
        [AllowAnonymous]
        [HttpPost("verify-email")]
        public async Task<IActionResult> VerifyEmail([FromBody] VerifyEmailCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تغيير كلمة المرور للمستخدم الحالي
        /// Change password for current user
        /// </summary>
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }
    }
} 