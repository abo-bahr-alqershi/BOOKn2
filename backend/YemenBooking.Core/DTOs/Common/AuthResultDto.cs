using System;

namespace YemenBooking.Core.DTOs.Common
{
    /// <summary>
    /// DTO لنتيجة المصادقة (رموز الوصول والتحديث)
    /// DTO for authentication result (access and refresh tokens)
    /// </summary>
    public class AuthResultDto
    {
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
        /// تاريخ انتهاء صلاحية رمز الوصول
        /// Expiration time of the access token
        /// </summary>
        public DateTime ExpiresAt { get; set; }

        /// <summary>
        /// معرف المستخدم
        /// User identifier
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// اسم المستخدم
        /// User name
        /// </summary>
        public string UserName { get; set; } = string.Empty;

        /// <summary>
        /// البريد الإلكتروني للمستخدم
        /// User email
        /// </summary>
        public string Email { get; set; } = string.Empty;

        /// <summary>
        /// دور المستخدم
        /// User role
        /// </summary>
        public string Role { get; set; } = string.Empty;

        /// <summary>
        /// نوع الحساب الموحّد (Admin, Owner, Staff, Customer)
        /// Unified account role (Admin, Owner, Staff, Customer)
        /// </summary>
        public string AccountRole { get; set; } = string.Empty;

        /// <summary>
        /// رابط صورة الملف الشخصي للمستخدم
        /// User profile image URL
        /// </summary>
        public string ProfileImage { get; set; } = string.Empty;

        /// <summary>
        /// معرف الكيان إذا كان مالكًا أو موظفًا
        /// Property ID if user is owner or staff
        /// </summary>
        public string? PropertyId { get; set; }

        /// <summary>
        /// اسم الكيان إذا كان مالكًا أو موظفًا
        /// Property name if user is owner or staff
        /// </summary>
        public string? PropertyName { get; set; }

        /// <summary>
        /// معرف الموظف إذا كان موظفًا
        /// Staff ID if user is staff
        /// </summary>
        public string? StaffId { get; set; }

        /// <summary>
        /// عملة العقار (رمز)
        /// Property currency code (e.g., YER, USD)
        /// </summary>
        public string? PropertyCurrency { get; set; }
    }
} 