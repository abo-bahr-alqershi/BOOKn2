using System;
using System.Threading.Tasks;

namespace YemenBooking.Application.Features.Authentication.Services {
    /// <summary>
    /// واجهة خدمة إعادة تعيين كلمة المرور
    /// Password reset service interface
    /// </summary>
    public interface IPasswordResetService
    {
        /// <summary>
        /// إرسال رابط إعادة تعيين كلمة المرور
        /// Send password reset link
        /// </summary>
        /// <param name="email">البريد الإلكتروني</param>
        /// <param name="resetToken">رمز إعادة التعيين</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> SendPasswordResetEmailAsync(string email, string resetToken);

        /// <summary>
        /// إنشاء رمز إعادة تعيين كلمة المرور
        /// Generate password reset token
        /// </summary>
        /// <param name="userId">معرف المستخدم</param>
        /// <returns>رمز إعادة التعيين</returns>
        Task<string> GenerateResetTokenAsync(Guid userId);

        /// <summary>
        /// التحقق من صحة رمز إعادة التعيين
        /// Validate password reset token
        /// </summary>
        /// <param name="userId">معرف المستخدم</param>
        /// <param name="resetToken">رمز إعادة التعيين</param>
        /// <returns>نتيجة التحقق</returns>
        Task<bool> ValidateResetTokenAsync(Guid userId, string resetToken);

        /// <summary>
        /// التحقق من انتهاء صلاحية رمز إعادة التعيين
        /// Check if reset token is expired
        /// </summary>
        /// <param name="resetToken">رمز إعادة التعيين</param>
        /// <returns>true إذا كان منتهي الصلاحية</returns>
        Task<bool> IsTokenExpiredAsync(string resetToken);

        /// <summary>
        /// حذف رمز إعادة التعيين بعد الاستخدام
        /// Delete reset token after use
        /// </summary>
        /// <param name="resetToken">رمز إعادة التعيين</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> DeleteResetTokenAsync(string resetToken);

        /// <summary>
        /// إعادة تعيين كلمة المرور
        /// Reset password
        /// </summary>
        /// <param name="userId">معرف المستخدم</param>
        /// <param name="newPassword">كلمة المرور الجديدة</param>
        /// <returns>نتيجة العملية</returns>
        Task<bool> ResetPasswordAsync(Guid userId, string newPassword);
    }
}
