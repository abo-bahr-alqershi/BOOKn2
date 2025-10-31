using System;
using System.Text.Json.Serialization;

namespace YemenBooking.Application.Features.Users.DTOs {
    /// <summary>
    /// واجهة مستخدم للدردشة
    /// Chat user DTO with chat-specific fields
    /// </summary>
    public class ChatUserDto
    {
        /// <summary>معرّف المستخدم في الشات</summary>
        [JsonPropertyName("user_id")]
        public Guid UserId { get; set; }

        /// <summary>اسم المستخدم</summary>
        [JsonPropertyName("name")]
        public string Name { get; set; } = string.Empty;

        /// <summary>البريد الإلكتروني للمستخدم</summary>
        [JsonPropertyName("email")]
        public string Email { get; set; } = string.Empty;

        /// <summary>رقم هاتف المستخدم</summary>
        [JsonPropertyName("phone")]
        public string? Phone { get; set; }

        /// <summary>صورة الملف الشخصي للمستخدم</summary>
        [JsonPropertyName("profile_image")]
        public string? ProfileImage { get; set; }

        /// <summary>نوع المستخدم في الشات</summary>
        [JsonPropertyName("user_type")]
        public string UserType { get; set; } = string.Empty;

        /// <summary>حالة المستخدم في الشات</summary>
        [JsonPropertyName("status")]
        public string Status { get; set; } = string.Empty;

        /// <summary>آخر تواجد للمستخدم</summary>
        [JsonPropertyName("last_seen")]
        public DateTime? LastSeen { get; set; }

        /// <summary>معرّف الفندق إذا كان مالكًا</summary>
        [JsonPropertyName("property_id")]
        public Guid? PropertyId { get; set; }

        /// <summary>هل المستخدم متصل حاليًا</summary>
        [JsonPropertyName("is_online")]
        public bool IsOnline { get; set; }
    }
} 