using System;

namespace YemenBooking.Application.Features.Authentication.DTOs {
    /// <summary>
    /// استجابة إعادة إرسال رمز التحقق
    /// Resend email verification response
    /// </summary>
    public class ResendEmailVerificationResponse
    {
        /// <summary>
        /// هل تم الإرسال بنجاح
        /// Whether sending was successful
        /// </summary>
        public bool Success { get; set; }

        /// <summary>
        /// رسالة النتيجة
        /// Result message
        /// </summary>
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// البريد الإلكتروني المرسل إليه
        /// Email sent to
        /// </summary>
        public string SentTo { get; set; } = string.Empty;

        /// <summary>
        /// الوقت المتبقي قبل إمكانية إعادة الإرسال مرة أخرى (بالثواني)
        /// Time remaining before retry is allowed (in seconds)
        /// </summary>
        public int? RetryAfterSeconds { get; set; }

        /// <summary>
        /// تاريخ الإرسال
        /// Send timestamp
        /// </summary>
        public DateTime SentAt { get; set; }

        /// <summary>
        /// رمز التحقق الجديد (للاختبار فقط)
        /// New verification code (for testing only)
        /// </summary>
        public string? VerificationCode { get; set; }
    }
}
