namespace YemenBooking.Infrastructure.Settings
{
    /// <summary>
    /// إعدادات خدمة البريد الإلكتروني
    /// Email service settings
    /// </summary>
    public class EmailSettings
    {
        /// <summary>
        /// عنوان البريد المرسل
        /// Sender email address
        /// </summary>
        public string FromEmail { get; set; } = string.Empty;

        /// <summary>
        /// اسم المرسل المعروض
        /// Display name for sender
        /// </summary>
        public string FromName { get; set; } = string.Empty;

        /// <summary>
        /// عنوان خادم SMTP
        /// SMTP server host
        /// </summary>
        public string SmtpHost { get; set; } = string.Empty;

        /// <summary>
        /// منفذ خادم SMTP
        /// SMTP server port
        /// </summary>
        public int SmtpPort { get; set; } = 587;

        /// <summary>
        /// تمكين SSL
        /// Enable SSL
        /// </summary>
        public bool EnableSsl { get; set; } = true;

        /// <summary>
        /// اسم المستخدم لخادم SMTP
        /// SMTP username
        /// </summary>
        public string Username { get; set; } = string.Empty;

        /// <summary>
        /// كلمة المرور لخادم SMTP
        /// SMTP password
        /// </summary>
        public string Password { get; set; } = string.Empty;

        /// <summary>
        /// استخدام مجلد الاستلام بدلاً من الإرسال عبر الشبكة (وضع التطوير)
        /// Use local pickup directory instead of network SMTP (development)
        /// </summary>
        public bool UsePickupDirectory { get; set; } = false;

        /// <summary>
        /// مسار مجلد الاستلام
        /// Pickup directory location
        /// </summary>
        public string PickupDirectoryLocation { get; set; } = "Emails";
    }
} 