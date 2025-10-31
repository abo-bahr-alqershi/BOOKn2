using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Features.Users.DTOs;

namespace YemenBooking.Application.Features.Users.Commands.UpdateUser
{
    /// <summary>
    /// أمر تحديث إعدادات المستخدم
    /// Command to update user settings
    /// </summary>
    public class UpdateUserSettingsCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// معرف المستخدم
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// اللغة المفضلة (ar, en)
        /// </summary>
        public string PreferredLanguage { get; set; } = "ar";

        /// <summary>
        /// العملة المفضلة
        /// </summary>
        public string PreferredCurrency { get; set; } = "YER";

        /// <summary>
        /// المنطقة الزمنية
        /// </summary>
        public string TimeZone { get; set; } = "Asia/Aden";

        /// <summary>
        /// تفعيل الوضع الليلي
        /// </summary>
        public bool DarkMode { get; set; } = false;

    
        /// <summary>
        /// إعدادات الإشعارات
        /// Notification settings
        /// </summary>
        public NotificationSettingsDto NotificationSettings { get; set; } = new();
        
        /// <summary>
        /// إعدادات إضافية
        /// Additional settings
        /// </summary>
        public Dictionary<string, object> AdditionalSettings { get; set; } = new();

        /// <summary>
        /// تمكين البصمة لتسجيل الدخول
        /// Enable biometric login (stored under AdditionalSettings['biometricEnabled'])
        /// هذا الحقل اختياري ومجرّد مختصر لواجهة المستخدم؛ يعكسه المعالج في AdditionalSettings
        /// </summary>
        public bool? BiometricEnabled { get; set; }
    }
}