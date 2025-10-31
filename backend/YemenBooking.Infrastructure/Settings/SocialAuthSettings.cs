namespace YemenBooking.Infrastructure.Settings
{
    /// <summary>
    /// إعدادات مزودي تسجيل الدخول الاجتماعي
    /// Social auth providers settings
    /// </summary>
    public class SocialAuthSettings
    {
        public string[] GoogleClientIds { get; set; } = new string[0];
        public string FacebookAppId { get; set; } = string.Empty;
        public string FacebookAppSecret { get; set; } = string.Empty;
    }
}
