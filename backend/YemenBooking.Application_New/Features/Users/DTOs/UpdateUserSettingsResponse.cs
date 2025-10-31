using System;

namespace YemenBooking.Application.Features.Users.DTOs {
    /// <summary>
    /// استجابة تحديث إعدادات المستخدم
    /// Update user settings response
    /// </summary>
    public class UpdateUserSettingsResponse
    {
        /// <summary>
        /// معرف المستخدم
        /// User identifier
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// هل تم التحديث بنجاح
        /// Whether the update was successful
        /// </summary>
        public bool Success { get; set; }

        /// <summary>
        /// رسالة النتيجة
        /// Result message
        /// </summary>
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// الإعدادات المحدثة
        /// Updated settings
        /// </summary>
        public UserSettingsDto UpdatedSettings { get; set; } = null!;

        /// <summary>
        /// تاريخ التحديث
        /// Update timestamp
        /// </summary>
        public DateTime UpdatedAt { get; set; }
    }
}
