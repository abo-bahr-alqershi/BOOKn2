namespace YemenBooking.Core.Settings
{
    /// <summary>
    /// إعدادات مسار تخزين مرفقات المحادثات
    /// Chat attachments storage settings
    /// </summary>
    public class ChatAttachmentSettings
    {
        /// <summary>
        /// المسار الأساسي داخل الخادم لتخزين مرفقات المحادثات
        /// Base path on server for storing chat attachments
        /// </summary>
        public string BasePath { get; set; } = "Uploads/ChatAttachments";
    }
} 