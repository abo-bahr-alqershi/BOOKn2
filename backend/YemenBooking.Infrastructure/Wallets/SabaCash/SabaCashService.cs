// Services/SabaCashService.cs
using System;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Text;
using Microsoft.Extensions.Caching.Memory;
using YemenBooking.Core.Wallets.SabaCash;

namespace YemenBooking.Infrastructure.Wallets.SabaCash
{
    /// <summary>
    /// تنفيذ خدمة التكامل مع SabaCash
    /// </summary>
    public class SabaCashService : ISabaCashService
    {
        // العميل HTTP للاتصال بـ API
        private readonly HttpClient _httpClient;
        
        // للوصول لإعدادات التطبيق
        private readonly IConfiguration _configuration;
        
        // لتسجيل الأحداث والأخطاء
        private readonly ILogger<SabaCashService> _logger;
        
        // للذاكرة المؤقتة (حفظ Token)
        private readonly IMemoryCache _cache;
        
        // مفتاح حفظ Token في الذاكرة المؤقتة
        private const string TOKEN_CACHE_KEY = "SabaCash_Token";

        /// <summary>
        /// منشئ الخدمة
        /// </summary>
        public SabaCashService(
            HttpClient httpClient,
            IConfiguration configuration,
            ILogger<SabaCashService> logger,
            IMemoryCache cache)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;
            _cache = cache;
            
            // تعيين العنوان الأساسي لـ API
            _httpClient.BaseAddress = new Uri(_configuration["SabaCash:BaseUrl"]);
            
            // تعيين اللغة الافتراضية للردود
            _httpClient.DefaultRequestHeaders.Add("Accept-Language", "ar");
        }

        /// <summary>
        /// الحصول على رمز المصادقة من SabaCash
        /// يتم التحقق أولاً من الذاكرة المؤقتة قبل طلب رمز جديد
        /// </summary>
        /// <returns>رمز المصادقة JWT</returns>
        public async Task<string> GetAuthTokenAsync()
        {
            // التحقق من وجود رمز مصادقة صالح في الذاكرة المؤقتة
            if (_cache.TryGetValue(TOKEN_CACHE_KEY, out string cachedToken))
            {
                _logger.LogDebug("استخدام رمز المصادقة من الذاكرة المؤقتة");
                return cachedToken;
            }

            try
            {
                _logger.LogInformation("بدء عملية تسجيل الدخول إلى SabaCash");
                
                // إعداد بيانات تسجيل الدخول
                var loginRequest = new SabaCashLoginRequest
                {
                    Username = _configuration["SabaCash:Username"],
                    Password = _configuration["SabaCash:Password"]
                };

                // تحويل البيانات إلى JSON
                var content = new StringContent(
                    JsonConvert.SerializeObject(loginRequest),
                    Encoding.UTF8,
                    "application/json");

                // إرسال طلب تسجيل الدخول
                var response = await _httpClient.PostAsync("/api/user-ms/v1/login/", content);
                var responseContent = await response.Content.ReadAsStringAsync();

                // التحقق من نجاح العملية
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError($"فشل تسجيل الدخول إلى SabaCash. الحالة: {response.StatusCode}, المحتوى: {responseContent}");
                    throw new Exception($"فشل تسجيل الدخول إلى SabaCash: {response.StatusCode}");
                }

                // تحليل الاستجابة
                var loginResponse = JsonConvert.DeserializeObject<SabaCashLoginResponse>(responseContent);
                
                // حفظ الرمز في الذاكرة المؤقتة لمدة 50 دقيقة
                // (الرمز صالح لمدة 60 دقيقة ولكن نجدده قبل انتهائه)
                _cache.Set(TOKEN_CACHE_KEY, loginResponse.Token, TimeSpan.FromMinutes(50));
                
                _logger.LogInformation("تم تسجيل الدخول بنجاح والحصول على رمز المصادقة");
                return loginResponse.Token;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء محاولة تسجيل الدخول إلى SabaCash");
                throw new Exception("فشل الاتصال بخدمة الدفع الإلكتروني", ex);
            }
        }

        /// <summary>
        /// إنشاء عملية دفع جديدة
        /// يتم التحقق من صحة رقم المحفظة ووجود رصيد كافي
        /// </summary>
        /// <param name="customerWallet">رقم محفظة العميل (يجب أن يبدأ بـ 7)</param>
        /// <param name="amount">المبلغ المطلوب دفعه بالريال اليمني</param>
        /// <param name="note">وصف العملية (مثل: دفع حجز فندق رقم 123)</param>
        /// <returns>تفاصيل العملية المنشأة متضمنة معرف العملية ورقم المعاملة</returns>
        public async Task<SabaCashPaymentResponse> CreatePaymentAsync(
            string customerWallet, 
            decimal amount, 
            string note)
        {
            try
            {
                _logger.LogInformation($"بدء إنشاء عملية دفع: المحفظة={customerWallet}, المبلغ={amount}");
                
                // التحقق من صحة رقم المحفظة محلياً
                if (string.IsNullOrEmpty(customerWallet) || !customerWallet.StartsWith("7") || customerWallet.Length != 9)
                {
                    throw new ArgumentException("رقم المحفظة غير صحيح. يجب أن يبدأ بـ 7 ويتكون من 9 أرقام");
                }

                // التحقق من صحة المبلغ
                if (amount <= 0)
                {
                    throw new ArgumentException("المبلغ يجب أن يكون أكبر من صفر");
                }

                // الحصول على رمز المصادقة
                var token = await GetAuthTokenAsync();
                
                // إضافة رمز المصادقة إلى رأس الطلب
                _httpClient.DefaultRequestHeaders.Authorization = 
                    new System.Net.Http.Headers.AuthenticationHeaderValue("bearer", token);

                // إعداد بيانات طلب الدفع
                var paymentRequest = new SabaCashPaymentRequest
                {
                    Source = new SourceInfo
                    {
                        Code = customerWallet,
                        CurrencyId = "1" // ريال يمني
                    },
                    Beneficiary = new BeneficiaryInfo
                    {
                        Terminal = _configuration["SabaCash:TerminalId"], // رقم Terminal من الإعدادات
                        CurrencyId = "1" // ريال يمني
                    },
                    Amount = amount.ToString("F0"), // تحويل المبلغ إلى نص بدون كسور عشرية
                    AmountCurrencyId = "1", // ريال يمني
                    Note = note ?? $"عملية دفع بتاريخ {DateTime.Now:yyyy-MM-dd HH:mm}"
                };

                // تحويل البيانات إلى JSON
                var content = new StringContent(
                    JsonConvert.SerializeObject(paymentRequest),
                    Encoding.UTF8,
                    "application/json");

                // إرسال طلب إنشاء العملية
                var response = await _httpClient.PostAsync(
                    "/api/accounts/v1/adjustment/onLinePayment", 
                    content);
                    
                var responseContent = await response.Content.ReadAsStringAsync();

                // معالجة الاستجابة
                if (!response.IsSuccessStatusCode)
                {
                    // تحليل رسالة الخطأ
                    var errorResponse = JsonConvert.DeserializeObject<SabaCashErrorResponse>(responseContent);
                    var errorMessage = errorResponse?.Errors?.SubErrors?.FirstOrDefault()?.Message;
                    
                    // ترجمة رسائل الخطأ الشائعة
                    if (errorMessage?.Contains("sufficient balance") == true)
                    {
                        errorMessage = "الرصيد غير كافي لإتمام العملية";
                    }
                    else if (errorMessage?.Contains("not exists") == true)
                    {
                        errorMessage = "رقم المحفظة غير مسجل في النظام";
                    }
                    else if (string.IsNullOrEmpty(errorMessage))
                    {
                        errorMessage = "حدث خطأ في إنشاء عملية الدفع";
                    }
                    
                    _logger.LogError($"فشل إنشاء عملية الدفع: {responseContent}");
                    throw new Exception(errorMessage);
                }

                // تحليل الاستجابة الناجحة
                var paymentResponse = JsonConvert.DeserializeObject<SabaCashPaymentResponse>(responseContent);
                
                _logger.LogInformation($"تم إنشاء عملية الدفع بنجاح. معرف العملية: {paymentResponse.Adjustment.Id}, رقم المعاملة: {paymentResponse.Adjustment.TransactionId}");
                
                return paymentResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في إنشاء عملية الدفع");
                throw;
            }
        }

        /// <summary>
        /// تأكيد عملية الدفع باستخدام رمز التحقق OTP
        /// يجب استدعاء هذه الدالة خلال 5 دقائق من إنشاء العملية
        /// </summary>
        /// <param name="adjustmentId">معرف العملية المراد تأكيدها</param>
        /// <param name="otp">رمز التحقق المرسل للعميل (عادة 4 أرقام)</param>
        /// <param name="note">ملاحظة إضافية عن التأكيد</param>
        /// <returns>نتيجة التأكيد متضمنة حالة النجاح</returns>
        public async Task<SabaCashConfirmResponse> ConfirmPaymentAsync(
            string adjustmentId, 
            string otp, 
            string note)
        {
            try
            {
                _logger.LogInformation($"بدء تأكيد عملية الدفع: معرف العملية={adjustmentId}");
                
                // التحقق من صحة المدخلات
                if (string.IsNullOrEmpty(adjustmentId))
                {
                    throw new ArgumentException("معرف العملية مطلوب");
                }

                if (string.IsNullOrEmpty(otp) || otp.Length != 4)
                {
                    throw new ArgumentException("رمز التحقق يجب أن يتكون من 4 أرقام");
                }

                // الحصول على رمز المصادقة
                var token = await GetAuthTokenAsync();
                _httpClient.DefaultRequestHeaders.Authorization = 
                    new System.Net.Http.Headers.AuthenticationHeaderValue("bearer", token);

                // إعداد بيانات التأكيد
                var confirmRequest = new SabaCashConfirmRequest
                {
                    Id = adjustmentId,
                    Otp = otp,
                    Note = note ?? "تأكيد عملية الدفع"
                };

                // تحويل البيانات إلى JSON
                var content = new StringContent(
                    JsonConvert.SerializeObject(confirmRequest),
                    Encoding.UTF8,
                    "application/json");

                // إنشاء طلب PATCH
                var request = new HttpRequestMessage(HttpMethod.Patch, 
                    "/api/accounts/v1/adjustment/onLinePayment")
                {
                    Content = content
                };

                // إرسال الطلب
                var response = await _httpClient.SendAsync(request);
                var responseContent = await response.Content.ReadAsStringAsync();

                // معالجة الاستجابة
                if (!response.IsSuccessStatusCode)
                {
                    // تحليل رسالة الخطأ
                    var errorResponse = JsonConvert.DeserializeObject<SabaCashErrorResponse>(responseContent);
                    var errorMessage = errorResponse?.Errors?.SubErrors?.FirstOrDefault()?.Message;
                    
                    // ترجمة رسائل الخطأ الشائعة
                    if (errorMessage?.Contains("Invalid OTP") == true)
                    {
                        errorMessage = "رمز التحقق غير صحيح";
                    }
                    else if (errorMessage?.Contains("expired") == true)
                    {
                        errorMessage = "انتهت صلاحية العملية. يرجى إعادة المحاولة";
                    }
                    else if (errorMessage?.Contains("already processed") == true)
                    {
                        errorMessage = "تمت معالجة هذه العملية مسبقاً";
                    }
                    else if (string.IsNullOrEmpty(errorMessage))
                    {
                        errorMessage = "فشل تأكيد عملية الدفع";
                    }
                    
                    _logger.LogError($"فشل تأكيد عملية الدفع: {responseContent}");
                    throw new Exception(errorMessage);
                }

                // تحليل الاستجابة الناجحة
                var confirmResponse = JsonConvert.DeserializeObject<SabaCashConfirmResponse>(responseContent);
                
                _logger.LogInformation($"تم تأكيد عملية الدفع. النتيجة: {(confirmResponse.Completed ? "نجحت" : "فشلت")}");
                
                return confirmResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تأكيد عملية الدفع");
                throw;
            }
        }

        /// <summary>
        /// الاستعلام عن حالة عملية دفع سابقة
        /// يمكن استخدامها للتحقق من نجاح العملية أو معرفة سبب الفشل
        /// </summary>
        /// <param name="transactionId">رقم المعاملة المراد الاستعلام عنها</param>
        /// <returns>تفاصيل حالة العملية</returns>
        public async Task<SabaCashStatusResponse> CheckPaymentStatusAsync(string transactionId)
        {
            try
            {
                _logger.LogInformation($"الاستعلام عن حالة المعاملة: {transactionId}");
                
                // التحقق من صحة المدخلات
                if (string.IsNullOrEmpty(transactionId))
                {
                    throw new ArgumentException("رقم المعاملة مطلوب");
                }

                // الحصول على رمز المصادقة
                var token = await GetAuthTokenAsync();
                _httpClient.DefaultRequestHeaders.Authorization = 
                    new System.Net.Http.Headers.AuthenticationHeaderValue("bearer", token);

                // إرسال طلب الاستعلام
                var response = await _httpClient.GetAsync(
                    $"/api/accounts/v1/adjustment/checkAdjustmentByTransactionId?transactionId={transactionId}");
                    
                var responseContent = await response.Content.ReadAsStringAsync();

                // معالجة الاستجابة
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError($"فشل الاستعلام عن حالة العملية: {responseContent}");
                    
                    // في حالة عدم وجود صلاحية
                    if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
                    {
                        throw new UnauthorizedAccessException("ليس لديك صلاحية للاستعلام عن هذه العملية");
                    }
                    
                    throw new Exception("فشل التحقق من حالة العملية");
                }

                // تحليل الاستجابة
                var statusResponse = JsonConvert.DeserializeObject<SabaCashStatusResponse>(responseContent);
                
                // ترجمة حالة العملية للعربية في السجل
                string statusArabic = statusResponse.StatusCode switch
                {
                    "completed" => "مكتملة",
                    "not-completed" => "غير مكتملة",
                    "not-exist" => "غير موجودة",
                    _ => "غير معروفة"
                };
                
                _logger.LogInformation($"حالة المعاملة {transactionId}: {statusArabic}");
                
                return statusResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في الاستعلام عن حالة العملية");
                throw;
            }
        }

        /// <summary>
        /// إرجاع مبلغ للعميل (كلي أو جزئي)
        /// يستخدم في حالات الإلغاء أو الاسترجاع
        /// </summary>
        /// <param name="originalAdjustmentId">معرف العملية الأصلية التي تم دفعها</param>
        /// <param name="customerWallet">رقم محفظة العميل التي ستستلم المبلغ المرجع</param>
        /// <param name="amount">المبلغ المراد إرجاعه (قد يكون أقل من المبلغ الأصلي)</param>
        /// <param name="transactionId">رقم المعاملة الأصلية</param>
        /// <param name="note">سبب الإرجاع (مثل: إلغاء الحجز)</param>
        /// <returns>تفاصيل عملية الإرجاع</returns>
        public async Task<SabaCashPaymentResponse> RefundPaymentAsync(
            string originalAdjustmentId,
            string customerWallet,
            decimal amount,
            string transactionId,
            string note)
        {
            try
            {
                _logger.LogInformation($"بدء عملية إرجاع: معرف العملية الأصلية={originalAdjustmentId}, المبلغ={amount}");
                
                // التحقق من صحة المدخلات
                if (string.IsNullOrEmpty(originalAdjustmentId))
                {
                    throw new ArgumentException("معرف العملية الأصلية مطلوب");
                }

                if (string.IsNullOrEmpty(customerWallet) || !customerWallet.StartsWith("7") || customerWallet.Length != 9)
                {
                    throw new ArgumentException("رقم محفظة العميل غير صحيح");
                }

                if (amount <= 0)
                {
                    throw new ArgumentException("مبلغ الإرجاع يجب أن يكون أكبر من صفر");
                }

                if (string.IsNullOrEmpty(transactionId))
                {
                    throw new ArgumentException("رقم المعاملة الأصلية مطلوب");
                }

                // الحصول على رمز المصادقة
                var token = await GetAuthTokenAsync();
                _httpClient.DefaultRequestHeaders.Authorization = 
                    new System.Net.Http.Headers.AuthenticationHeaderValue("bearer", token);

                // إعداد بيانات طلب الإرجاع
                var refundRequest = new SabaCashRefundRequest
                {
                    Id = originalAdjustmentId,
                    Source = new RefundSourceInfo
                    {
                        CurrencyId = "1", // ريال يمني
                        IsTerminal = true // الإرجاع من حساب التاجر
                    },
                    Beneficiary = new RefundBeneficiaryInfo
                    {
                        Code = customerWallet,
                        CurrencyId = "1" // ريال يمني
                    },
                    Amount = amount.ToString("F0"),
                    AmountCurrencyId = "1",
                    TransactionId = transactionId,
                    Note = note ?? $"إرجاع مبلغ - {DateTime.Now:yyyy-MM-dd HH:mm}"
                };

                // تحويل البيانات إلى JSON
                var content = new StringContent(
                    JsonConvert.SerializeObject(refundRequest),
                    Encoding.UTF8,
                    "application/json");

                // إرسال طلب الإرجاع
                var response = await _httpClient.PostAsync(
                    "/api/accounts/v1/adjustment/onlineMoneyReturn", 
                    content);
                    
                var responseContent = await response.Content.ReadAsStringAsync();

                // معالجة الاستجابة
                if (!response.IsSuccessStatusCode)
                {
                    // تحليل رسالة الخطأ
                    var errorResponse = JsonConvert.DeserializeObject<SabaCashErrorResponse>(responseContent);
                    var errorMessage = errorResponse?.Errors?.SubErrors?.FirstOrDefault()?.Message;
                    
                    // ترجمة رسائل الخطأ الشائعة
                    if (errorMessage?.Contains("sufficient balance") == true)
                    {
                        errorMessage = "رصيد حساب التاجر غير كافي لإرجاع المبلغ";
                    }
                    else if (errorMessage?.Contains("not completed") == true)
                    {
                        errorMessage = "لا يمكن إرجاع مبلغ عملية غير مكتملة";
                    }
                    else if (errorMessage?.Contains("conflict") == true)
                    {
                        errorMessage = "بيانات العملية لا تتطابق مع العملية الأصلية";
                    }
                    else if (string.IsNullOrEmpty(errorMessage))
                    {
                        errorMessage = "فشلت عملية الإرجاع";
                    }
                    
                    _logger.LogError($"فشلت عملية الإرجاع: {responseContent}");
                    throw new Exception(errorMessage);
                }

                // تحليل الاستجابة الناجحة
                var refundResponse = JsonConvert.DeserializeObject<SabaCashPaymentResponse>(responseContent);
                
                _logger.LogInformation($"تمت عملية الإرجاع بنجاح. معرف العملية: {refundResponse.Adjustment.Id}");
                
                return refundResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في معالجة عملية الإرجاع");
                throw;
            }
        }
    }
}            