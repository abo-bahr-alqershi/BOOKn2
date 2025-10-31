using System;

namespace YemenBooking.Application.Features.Authentication.DTOs {
    /// <summary>
    /// استجابة تسجيل المستخدم
    /// User registration response DTO
    /// </summary>
    public class RegisterUserResponse
    {
        /// <summary>
        /// معرف المستخدم الجديد
        /// New user ID
        /// </summary>
        public Guid UserId { get; set; }
        
        /// <summary>
        /// رمز الوصول
        /// Access token
        /// </summary>
        public string AccessToken { get; set; } = string.Empty;
        
        /// <summary>
        /// رمز التحديث
        /// Refresh token
        /// </summary>
        public string RefreshToken { get; set; } = string.Empty;
        
        /// <summary>
        /// رسالة النجاح
        /// Success message
        /// </summary>
        public string Message { get; set; } = string.Empty;
        
        /// <summary>
        /// تاريخ انتهاء صلاحية رمز الوصول
        /// Access token expiry date
        /// </summary>
        public DateTime AccessTokenExpiry { get; set; }
        
        /// <summary>
        /// اسم المستخدم
        /// User name
        /// </summary>
        public string UserName { get; set; } = string.Empty;
        
        /// <summary>
        /// البريد الإلكتروني
        /// Email address
        /// </summary>
        public string Email { get; set; } = string.Empty;
        
        /// <summary>
        /// هل تم تأكيد البريد الإلكتروني
        /// Whether email is verified
        /// </summary>
        public bool IsEmailVerified { get; set; }
    }
}
