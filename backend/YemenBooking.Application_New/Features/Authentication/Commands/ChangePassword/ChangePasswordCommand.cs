using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Features.Authentication.DTOs;

namespace YemenBooking.Application.Features.Authentication.Commands.ChangePassword
{
    /// <summary>
    /// أمر تغيير كلمة المرور
    /// Command to change user password
    /// </summary>
    public class ChangePasswordCommand : IRequest<ResultDto<ChangePasswordResponse>>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// كلمة المرور الحالية
    /// </summary>
    public string CurrentPassword { get; set; } = string.Empty;
    
        /// <summary>
        /// كلمة المرور الجديدة
        /// </summary>
        public string NewPassword { get; set; } = string.Empty;
    }
}