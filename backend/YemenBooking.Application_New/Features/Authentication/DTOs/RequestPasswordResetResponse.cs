using System;

namespace YemenBooking.Application.Features.Authentication.DTOs {
    /// <summary>
    /// استجابة طلب إعادة تعيين كلمة المرور
    /// Request password reset response
    /// </summary>
    public class RequestPasswordResetResponse
    {
        /// <summary>
        /// هل تم إرسال الطلب بنجاح
        /// Whether the request was sent successfully
        /// </summary>
        public bool Success { get; set; }

        /// <summary>
        /// رسالة التأكيد
        /// Confirmation message
        /// </summary>
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// رمز إعادة التعيين (للاختبار فقط)
        /// Reset token (for testing only)
        /// </summary>
        public string? ResetToken { get; set; }

        /// <summary>
        /// تاريخ انتهاء صلاحية الرمز
        /// Token expiration date
        /// </summary>
        public DateTime? ExpiresAt { get; set; }

        /// <summary>
        /// البريد الإلكتروني المرسل إليه
        /// Email sent to
        /// </summary>
        public string? SentTo { get; set; }
    }
}
