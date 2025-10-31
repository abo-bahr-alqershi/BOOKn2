using System;

namespace YemenBooking.Application.Features.Authentication.DTOs {
    /// <summary>
    /// استجابة تحديث رمز الوصول
    /// Refresh token response DTO
    /// </summary>
    public class RefreshTokenResponse
    {
        /// <summary>
        /// رمز الوصول الجديد
        /// New access token
        /// </summary>
        public string NewAccessToken { get; set; } = string.Empty;
        
        /// <summary>
        /// رمز التحديث الجديد
        /// New refresh token
        /// </summary>
        public string NewRefreshToken { get; set; } = string.Empty;
        
        /// <summary>
        /// تاريخ انتهاء صلاحية رمز الوصول
        /// Access token expiry date
        /// </summary>
        public DateTime AccessTokenExpiry { get; set; }
        
        /// <summary>
        /// تاريخ انتهاء صلاحية رمز التحديث
        /// Refresh token expiry date
        /// </summary>
        public DateTime RefreshTokenExpiry { get; set; }
        
        /// <summary>
        /// نوع الرمز المميز
        /// Token type
        /// </summary>
        public string TokenType { get; set; } = "Bearer";
        
        /// <summary>
        /// مدة صلاحية رمز الوصول بالثواني
        /// Access token validity duration in seconds
        /// </summary>
        public int ExpiresIn { get; set; }
    }
}
