using System;

namespace YemenBooking.Application.Features.Authentication.DTOs {
    /// <summary>
    /// استجابة تغيير كلمة المرور
    /// Change password response DTO
    /// </summary>
    public class ChangePasswordResponse
    {
        /// <summary>
        /// نجاح العملية
        /// Operation success
        /// </summary>
        public bool Success { get; set; }
        
        /// <summary>
        /// رسالة النتيجة
        /// Result message
        /// </summary>
        public string Message { get; set; } = string.Empty;
        
        /// <summary>
        /// تاريخ آخر تغيير لكلمة المرور
        /// Last password change date
        /// </summary>
        public DateTime? LastPasswordChangeDate { get; set; }
        
        /// <summary>
        /// هل يحتاج المستخدم لتسجيل دخول جديد
        /// Whether user needs to re-login
        /// </summary>
        public bool RequiresReLogin { get; set; } = true;
    }
}
