using System;

namespace YemenBooking.Application.Features.Authentication.DTOs {
    /// <summary>
    /// استجابة تسجيل الخروج
    /// Logout response DTO
    /// </summary>
    public class LogoutResponse
    {
        /// <summary>
        /// نجاح العملية
        /// Operation success
        /// </summary>
        public bool Success { get; set; }
        
        /// <summary>
        /// رسالة النتيجة
        /// Result message
        /// </summary>
        public string Message { get; set; } = string.Empty;
        
        /// <summary>
        /// تاريخ تسجيل الخروج
        /// Logout timestamp
        /// </summary>
        public DateTime LogoutTime { get; set; } = DateTime.UtcNow;
        
        /// <summary>
        /// عدد الجلسات التي تم إنهاؤها
        /// Number of terminated sessions
        /// </summary>
        public int TerminatedSessionsCount { get; set; }
        
        /// <summary>
        /// هل تم تسجيل الخروج من جميع الأجهزة
        /// Whether logged out from all devices
        /// </summary>
        public bool LoggedOutFromAllDevices { get; set; }
    }
}
