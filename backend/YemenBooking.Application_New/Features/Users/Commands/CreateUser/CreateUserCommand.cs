using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Users.Commands.CreateUser
{
    /// <summary>
    /// أمر لإنشاء حساب مستخدم جديد
    /// Command to create a new user account
    /// </summary>
    public class CreateUserCommand : IRequest<ResultDto<Guid>>
    {
        /// <summary>
        /// اسم المستخدم
        /// User name
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// البريد الإلكتروني للمستخدم
        /// User email
        /// </summary>
        public string Email { get; set; } = string.Empty;

        /// <summary>
        /// كلمة المرور للمستخدم
        /// User password
        /// </summary>
        public string Password { get; set; } = string.Empty;

        /// <summary>
        /// رقم هاتف المستخدم
        /// User phone number
        /// </summary>
        public string Phone { get; set; } = string.Empty;

        /// <summary>
        /// صورة الملف الشخصي للمستخدم (اختياري)
        /// User profile image (optional)
        /// </summary>
        public string? ProfileImage { get; set; }

        public string? RoleName { get; set; }

        /// <summary>
        /// حالة تأكيد البريد الإلكتروني
        /// Email confirmation status
        /// </summary>
        public bool EmailConfirmed { get; set; } = false;

        /// <summary>
        /// حالة تأكيد رقم الهاتف
        /// Phone number confirmation status
        /// </summary>
        public bool PhoneNumberConfirmed { get; set; } = false;
    }
} 