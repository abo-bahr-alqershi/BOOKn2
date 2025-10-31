using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using System;
using YemenBooking.Application.Features.Authentication.DTOs;

namespace YemenBooking.Application.Features.Authentication.Commands.Logout
{
    /// <summary>
    /// أمر تسجيل خروج المستخدم
    /// Command to logout user
    /// </summary>
    public class LogoutCommand : IRequest<ResultDto<LogoutResponse>>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// رمز التحديث الحالي (لإلغائه)
    /// </summary>
    public string RefreshToken { get; set; } = string.Empty;
    
        /// <summary>
        /// تسجيل الخروج من جميع الأجهزة
        /// </summary>
        public bool LogoutFromAllDevices { get; set; } = false;
    }
}