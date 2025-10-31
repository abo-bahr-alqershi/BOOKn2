using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using System;
using YemenBooking.Application.Features.Authentication.DTOs;

namespace YemenBooking.Application.Features.Authentication.Commands.RefreshToken
{
    /// <summary>
    /// أمر تحديث رمز الوصول باستخدام رمز التحديث
    /// Command to refresh access token using refresh token
    /// </summary>
    public class RefreshTokenCommand : IRequest<ResultDto<RefreshTokenResponse>>
{
    /// <summary>
    /// رمز الوصول المنتهي الصلاحية
    /// </summary>
    public string AccessToken { get; set; } = string.Empty;
    
        /// <summary>
        /// رمز التحديث
        /// </summary>
        public string RefreshToken { get; set; } = string.Empty;
    }
}