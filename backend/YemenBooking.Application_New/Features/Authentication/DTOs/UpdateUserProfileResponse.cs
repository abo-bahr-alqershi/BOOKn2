using System;

namespace YemenBooking.Application.Features.Authentication.DTOs {
    /// <summary>
    /// استجابة تحديث الملف الشخصي
    /// Update user profile response
    /// </summary>
    public class UpdateUserProfileResponse
    {
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
        /// معرف المستخدم
        /// User identifier
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// الاسم المحدث
        /// Updated name
        /// </summary>
        public string? UpdatedName { get; set; }

        /// <summary>
        /// رقم الهاتف المحدث
        /// Updated phone number
        /// </summary>
        public string? UpdatedPhone { get; set; }

        /// <summary>
        /// رابط الصورة الجديدة إن وجدت
        /// New profile image URL if updated
        /// </summary>
        public string? NewProfileImageUrl { get; set; }

        /// <summary>
        /// تاريخ التحديث
        /// Update timestamp
        /// </summary>
        public DateTime UpdatedAt { get; set; }
    }
}
