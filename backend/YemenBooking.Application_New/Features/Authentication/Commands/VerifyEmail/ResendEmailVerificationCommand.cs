using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Application.Features.Authentication.DTOs;

namespace YemenBooking.Application.Features.Authentication.Commands.VerifyEmail
{
    /// <summary>
    /// أمر إعادة إرسال رمز تأكيد البريد الإلكتروني
    /// Command to resend email verification token
    /// </summary>
    public class ResendEmailVerificationCommand : IRequest<ResultDto<ResendEmailVerificationResponse>>
    {
        /// <summary>
        /// معرف المستخدم
        /// </summary>
        public Guid UserId { get; set; }
        
        /// <summary>
        /// البريد الإلكتروني
        /// </summary>
        [Required(ErrorMessage = "البريد الإلكتروني مطلوب")]
        [EmailAddress(ErrorMessage = "بريد إلكتروني غير صحيح")]
        public string Email { get; set; } = string.Empty;
    }
}