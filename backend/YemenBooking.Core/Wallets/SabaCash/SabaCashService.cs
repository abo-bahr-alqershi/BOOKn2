// Services/SabaCashService.cs
using System;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
// using Newtonsoft.Json;
using System.Text;
using Microsoft.Extensions.Caching.Memory;

namespace YemenBooking.Core.Wallets.SabaCash
{
    /// <summary>
    /// واجهة خدمة التكامل مع SabaCash
    /// توفر جميع العمليات اللازمة للدفع الإلكتروني
    /// </summary>
    public interface ISabaCashService
    {
        /// <summary>
        /// الحصول على رمز المصادقة من SabaCash
        /// يتم حفظه في الذاكرة المؤقتة لمدة 50 دقيقة
        /// </summary>
        /// <returns>رمز المصادقة JWT</returns>
        Task<string> GetAuthTokenAsync();

        /// <summary>
        /// إنشاء عملية دفع جديدة
        /// </summary>
        /// <param name="customerWallet">رقم محفظة العميل</param>
        /// <param name="amount">المبلغ بالريال اليمني</param>
        /// <param name="note">وصف العملية</param>
        /// <returns>تفاصيل العملية المنشأة</returns>
        Task<SabaCashPaymentResponse> CreatePaymentAsync(string customerWallet, decimal amount, string note);

        /// <summary>
        /// تأكيد عملية الدفع باستخدام OTP
        /// </summary>
        /// <param name="adjustmentId">معرف العملية</param>
        /// <param name="otp">رمز التحقق المرسل للعميل</param>
        /// <param name="note">ملاحظة إضافية</param>
        /// <returns>نتيجة التأكيد</returns>
        Task<SabaCashConfirmResponse> ConfirmPaymentAsync(string adjustmentId, string otp, string note);

        /// <summary>
        /// الاستعلام عن حالة عملية دفع
        /// </summary>
        /// <param name="transactionId">رقم المعاملة</param>
        /// <returns>حالة العملية</returns>
        Task<SabaCashStatusResponse> CheckPaymentStatusAsync(string transactionId);

        /// <summary>
        /// إرجاع مبلغ للعميل
        /// </summary>
        /// <param name="originalAdjustmentId">معرف العملية الأصلية</param>
        /// <param name="customerWallet">محفظة العميل</param>
        /// <param name="amount">المبلغ المراد إرجاعه</param>
        /// <param name="transactionId">رقم المعاملة الأصلية</param>
        /// <param name="note">سبب الإرجاع</param>
        /// <returns>تفاصيل عملية الإرجاع</returns>
        Task<SabaCashPaymentResponse> RefundPaymentAsync(
            string originalAdjustmentId, 
            string customerWallet, 
            decimal amount, 
            string transactionId, 
            string note);
    }
}            