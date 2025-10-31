using System;

namespace YemenBooking.Application.Features.Users.DTOs {
    /// <summary>
    /// DTO لبيانات المستخدم
    /// DTO for user data
    /// </summary>
    public class UserDto
    {
        /// <summary>
        /// المعرف الفريد للمستخدم
        /// User unique identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// اسم المستخدم
        /// User name
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// البريد الإلكتروني للمستخدم
        /// User email
        /// </summary>
        public string Email { get; set; }

        /// <summary>
        /// رقم هاتف المستخدم
        /// User phone number
        /// </summary>
        public string Phone { get; set; }

        /// <summary>
        /// صورة الملف الشخصي للمستخدم
        /// User profile image
        /// </summary>
        public string ProfileImage { get; set; }

        /// <summary>
        /// تاريخ إنشاء حساب المستخدم
        /// User account creation date
        /// </summary>
        public DateTime CreatedAt { get; set; }

        /// <summary>
        /// حالة تفعيل الحساب
        /// Account activation status
        /// </summary>
        public bool IsActive { get; set; }

        /// <summary>
        /// إعدادات المستخدم بصيغة JSON
        /// User settings JSON
        /// </summary>
        public string SettingsJson { get; set; } = "{}";

        /// <summary>
        /// قائمة المفضلة للمستخدم بصيغة JSON
        /// User favorites JSON
        /// </summary>
        public string FavoritesJson { get; set; } = "[]";

        /// <summary>
        /// نوع الحساب الموحّد (Admin, Owner, Staff, Customer)
        /// Unified account role
        /// </summary>
        public string AccountRole { get; set; } = string.Empty;

        /// <summary>
        /// معرف العقار إن كان مالكاً أو موظفاً
        /// Property identifier if owner/staff
        /// </summary>
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// اسم العقار إن كان مالكاً أو موظفاً
        /// Property name if owner/staff
        /// </summary>
        public string? PropertyName { get; set; }

        /// <summary>
        /// عملة العقار
        /// Property currency code
        /// </summary>
        public string? PropertyCurrency { get; set; }

        /// <summary>
        /// تاريخ آخر نشاط للمستخدم
        /// User's last seen date
        /// </summary>
        public DateTime? LastSeen { get; set; }

        /// <summary>
        /// تاريخ آخر تسجيل دخول
        /// Last login date
        /// </summary>
        public DateTime? LastLoginDate { get; set; }
    }
} 