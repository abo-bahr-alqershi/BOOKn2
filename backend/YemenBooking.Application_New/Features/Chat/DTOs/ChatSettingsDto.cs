namespace YemenBooking.Application.Features.Chat.DTOs {
    using System;

    /// <summary>
    /// DTO لإعدادات الشات الخاصة بالمستخدم
    /// DTO for ChatSettings entity
    /// </summary>
    public class ChatSettingsDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public bool NotificationsEnabled { get; set; }
        public bool SoundEnabled { get; set; }
        public bool ShowReadReceipts { get; set; }
        public bool ShowTypingIndicator { get; set; }
        public string Theme { get; set; } = string.Empty;
        public string FontSize { get; set; } = string.Empty;
        public bool AutoDownloadMedia { get; set; }
        public bool BackupMessages { get; set; }
    }
} 