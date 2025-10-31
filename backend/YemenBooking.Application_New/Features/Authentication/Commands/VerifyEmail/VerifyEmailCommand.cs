using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Features.Authentication.DTOs;

namespace YemenBooking.Application.Features.Authentication.Commands.VerifyEmail;

/// <summary>
/// أمر تأكيد البريد الإلكتروني
/// Command to verify email
/// </summary>
public class VerifyEmailCommand : IRequest<ResultDto<VerifyEmailResponse>>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// رمز التأكيد
    /// </summary>
    public string VerificationToken { get; set; } = string.Empty;
}