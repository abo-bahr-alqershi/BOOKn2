using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using System;
using YemenBooking.Application.Features.Authentication.DTOs;

namespace YemenBooking.Application.Features.Authentication.Commands.Account
{
    /// <summary>
    /// أمر حذف حساب المستخدم
    /// Command to delete user account
    /// </summary>
    public class DeleteAccountCommand : IRequest<ResultDto<DeleteAccountResponse>>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// كلمة المرور للتأكيد
    /// </summary>
    public string Password { get; set; } = string.Empty;
    
        /// <summary>
        /// سبب حذف الحساب
        /// </summary>
        public string? Reason { get; set; }
    }
}