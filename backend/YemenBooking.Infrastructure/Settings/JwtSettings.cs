namespace YemenBooking.Infrastructure.Settings
{
    /// <summary>
    /// إعدادات JWT للمصادقة
    /// JWT authentication settings
    /// </summary>
    public class JwtSettings
    {
        /// <summary>
        /// المُصدر (Issuer) للرمز
        /// Token issuer
        /// </summary>
        public string Issuer { get; set; } = string.Empty;

        /// <summary>
        /// المستفيد (Audience) للرمز
        /// Token audience
        /// </summary>
        public string Audience { get; set; } = string.Empty;

        /// <summary>
        /// السر المستخدم لتوقيع الرمز
        /// Signing key (secret)
        /// </summary>
        public string Secret { get; set; } = string.Empty;

        /// <summary>
        /// مدة صلاحية رمز الوصول (بالدقائق)
        /// Access token expiration in minutes
        /// </summary>
        public int AccessTokenExpirationMinutes { get; set; }

        /// <summary>
        /// مدة صلاحية رمز التجديد (بالأيام)
        /// Refresh token expiration in days
        /// </summary>
        public int RefreshTokenExpirationDays { get; set; }
    }
} 