namespace YemenBooking.Core.Settings
{
    /// <summary>
    /// إعدادات Firebase للمستخدم
    /// Settings for Firebase Admin SDK
    /// </summary>
    public class FirebaseSettings
    {
        /// <summary>
        /// مسار ملف بيانات الاعتماد لخدمة Firebase
        /// Path to service account credentials JSON file
        /// </summary>
        public string CredentialsPath { get; set; } = "firebase-service-account.json";
    }
} 