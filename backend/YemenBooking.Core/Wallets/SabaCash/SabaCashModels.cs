namespace YemenBooking.Core.Wallets.SabaCash
{
    /// <summary>
    /// نموذج طلب تسجيل الدخول إلى SabaCash
    /// يستخدم للحصول على رمز المصادقة (Token)
    /// </summary>
    public class SabaCashLoginRequest
    {
        /// <summary>
        /// اسم المستخدم الخاص بحساب التاجر
        /// مثال: "terminal-1" أو "merchant-123"
        /// </summary>
        public string Username { get; set; }

        /// <summary>
        /// كلمة المرور الخاصة بحساب التاجر
        /// يجب حفظها بشكل آمن في الإعدادات
        /// </summary>
        public string Password { get; set; }
    }

    /// <summary>
    /// نموذج استجابة تسجيل الدخول من SabaCash
    /// </summary>
    public class SabaCashLoginResponse
    {
        /// <summary>
        /// رمز المصادقة JWT الذي يستخدم في جميع الطلبات اللاحقة
        /// صلاحيته 60 دقيقة من وقت الإصدار
        /// </summary>
        public string Token { get; set; }
    }

    /// <summary>
    /// نموذج طلب إنشاء عملية دفع جديدة
    /// </summary>
    public class SabaCashPaymentRequest
    {
        /// <summary>
        /// معلومات المصدر (محفظة العميل الذي سيدفع)
        /// </summary>
        public SourceInfo Source { get; set; }

        /// <summary>
        /// معلومات المستفيد (حساب التاجر الذي سيستلم المبلغ)
        /// </summary>
        public BeneficiaryInfo Beneficiary { get; set; }

        /// <summary>
        /// المبلغ المطلوب دفعه (بالريال اليمني)
        /// مثال: "15000" لدفع 15 ألف ريال
        /// </summary>
        public string Amount { get; set; }

        /// <summary>
        /// معرف العملة للمبلغ
        /// "1" = ريال يمني (YER)
        /// </summary>
        public string AmountCurrencyId { get; set; }

        /// <summary>
        /// ملاحظة توضيحية عن العملية
        /// مثال: "دفع حجز فندق رقم 12345"
        /// </summary>
        public string Note { get; set; }
    }

    /// <summary>
    /// معلومات محفظة العميل (المصدر)
    /// </summary>
    public class SourceInfo
    {
        /// <summary>
        /// رقم محفظة العميل
        /// يجب أن يبدأ بـ 7 ويتكون من 9 أرقام
        /// مثال: "777123456"
        /// </summary>
        public string Code { get; set; }

        /// <summary>
        /// معرف عملة المحفظة
        /// "1" = ريال يمني
        /// </summary>
        public string CurrencyId { get; set; }
    }

    /// <summary>
    /// معلومات حساب التاجر (المستفيد)
    /// </summary>
    public class BeneficiaryInfo
    {
        /// <summary>
        /// رقم Terminal الخاص بالتاجر
        /// يتم الحصول عليه من SabaCash عند التسجيل
        /// </summary>
        public string Terminal { get; set; }

        /// <summary>
        /// معرف عملة حساب التاجر
        /// "1" = ريال يمني
        /// </summary>
        public string CurrencyId { get; set; }
    }

    /// <summary>
    /// نموذج الاستجابة عند إنشاء عملية دفع
    /// </summary>
    public class SabaCashPaymentResponse
    {
        /// <summary>
        /// معلومات العملية المنشأة
        /// </summary>
        public AdjustmentInfo Adjustment { get; set; }

        /// <summary>
        /// معلومات الوجهة (المستفيد)
        /// </summary>
        public DestinationInfo Destination { get; set; }

        /// <summary>
        /// معلومات المصدر (دافع المبلغ)
        /// </summary>
        public SourceResponseInfo Source { get; set; }
    }

    /// <summary>
    /// تفاصيل عملية الدفع (Adjustment)
    /// </summary>
    public class AdjustmentInfo
    {
        /// <summary>
        /// المعرف الفريد للعملية
        /// يستخدم لتأكيد العملية لاحقاً
        /// مثال: 987654
        /// </summary>
        public long Id { get; set; }

        /// <summary>
        /// رقم المعاملة الفريد
        /// يستخدم للتتبع والاستعلام
        /// مثال: "DF-01-0123456-0123456789"
        /// </summary>
        public string TransactionId { get; set; }

        /// <summary>
        /// المبلغ بالريال اليمني
        /// </summary>
        public decimal Amount { get; set; }

        /// <summary>
        /// نوع العملية
        /// 620 = دفع أونلاين
        /// 607 = إرجاع مبلغ
        /// </summary>
        public int AdjustmentTypeId { get; set; }

        /// <summary>
        /// معرف نوع الدفع (إن وجد)
        /// 0 = الافتراضي
        /// </summary>
        public int PaymentTypeId { get; set; }

        /// <summary>
        /// الرسوم المحملة على المصدر
        /// </summary>
        public decimal SourceFeeAmount { get; set; }

        /// <summary>
        /// الرسوم المحملة على الوجهة
        /// </summary>
        public decimal DestinationFeeAmount { get; set; }

        /// <summary>
        /// رسوم الطرف الثالث (إن وجدت)
        /// </summary>
        public decimal ThirdPartyFeeAmount { get; set; }

        /// <summary>
        /// هل تحتاج موافقة مراجع
        /// false = لا تحتاج
        /// </summary>
        public bool MakerChecker { get; set; }
    }

    /// <summary>
    /// معلومات الوجهة في الاستجابة
    /// </summary>
    public class DestinationInfo
    {
        /// <summary>
        /// رقم المحفظة أو الحساب
        /// </summary>
        public string Code { get; set; }

        /// <summary>
        /// هل الحساب مسجل في النظام
        /// </summary>
        public bool IsRegistered { get; set; }

        /// <summary>
        /// هل هو عميل viral
        /// </summary>
        public bool Viral { get; set; }

        /// <summary>
        /// معرف العملة
        /// </summary>
        public string CurrencyId { get; set; }

        /// <summary>
        /// سعر الصرف
        /// </summary>
        public decimal ExchangePrice { get; set; }
    }

    /// <summary>
    /// معلومات المصدر في الاستجابة
    /// </summary>
    public class SourceResponseInfo : DestinationInfo
    {
        // يرث نفس الخصائص من DestinationInfo
    }

    /// <summary>
    /// نموذج طلب تأكيد العملية بـ OTP
    /// </summary>
    public class SabaCashConfirmRequest
    {
        /// <summary>
        /// معرف العملية (adjustment ID) المراد تأكيدها
        /// يتم الحصول عليه من استجابة إنشاء العملية
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// رمز التحقق المرسل للعميل
        /// عادة 4 أرقام يتم إرسالها عبر SMS
        /// </summary>
        public string Otp { get; set; }

        /// <summary>
        /// ملاحظة إضافية
        /// مثال: "تأكيد دفع حجز فندق"
        /// </summary>
        public string Note { get; set; }
    }

    /// <summary>
    /// نموذج استجابة تأكيد العملية
    /// </summary>
    public class SabaCashConfirmResponse
    {
        /// <summary>
        /// معرف العملية
        /// </summary>
        public long Id { get; set; }

        /// <summary>
        /// هل تمت العملية بنجاح
        /// true = نجحت وتم خصم المبلغ
        /// false = فشلت العملية
        /// </summary>
        public bool Completed { get; set; }

        /// <summary>
        /// رقم المعاملة النهائي
        /// </summary>
        public string TransactionId { get; set; }
    }

    /// <summary>
    /// نموذج طلب الاستعلام عن حالة العملية
    /// </summary>
    public class SabaCashStatusRequest
    {
        /// <summary>
        /// رقم المعاملة المراد الاستعلام عنها
        /// </summary>
        public string TransactionId { get; set; }
    }

    /// <summary>
    /// نموذج استجابة الاستعلام عن الحالة
    /// </summary>
    public class SabaCashStatusResponse
    {
        /// <summary>
        /// المبلغ (قد يكون null إذا لم توجد العملية)
        /// </summary>
        public string Amount { get; set; }

        /// <summary>
        /// تاريخ العملية بصيغة Unix timestamp
        /// </summary>
        public string TransactionDate { get; set; }

        /// <summary>
        /// رقم المعاملة
        /// </summary>
        public string TransactionId { get; set; }

        /// <summary>
        /// حالة العملية:
        /// "completed" = مكتملة بنجاح
        /// "not-completed" = معلقة أو قيد المعالجة
        /// "not-exist" = غير موجودة
        /// </summary>
        public string StatusCode { get; set; }
    }

    /// <summary>
    /// نموذج طلب إرجاع المبلغ
    /// </summary>
    public class SabaCashRefundRequest
    {
        /// <summary>
        /// معرف العملية الأصلية المراد إرجاع مبلغها
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// معلومات المصدر (حساب التاجر الذي سيرجع المبلغ)
        /// </summary>
        public RefundSourceInfo Source { get; set; }

        /// <summary>
        /// معلومات المستفيد (محفظة العميل التي ستستلم المبلغ المرجع)
        /// </summary>
        public RefundBeneficiaryInfo Beneficiary { get; set; }

        /// <summary>
        /// المبلغ المراد إرجاعه
        /// قد يكون جزئي أو كامل
        /// </summary>
        public string Amount { get; set; }

        /// <summary>
        /// معرف العملة
        /// </summary>
        public string AmountCurrencyId { get; set; }

        /// <summary>
        /// رقم المعاملة الأصلية
        /// </summary>
        public string TransactionId { get; set; }

        /// <summary>
        /// سبب الإرجاع
        /// </summary>
        public string Note { get; set; }
    }

    /// <summary>
    /// معلومات مصدر الإرجاع (حساب التاجر)
    /// </summary>
    public class RefundSourceInfo
    {
        /// <summary>
        /// معرف العملة
        /// </summary>
        public string CurrencyId { get; set; }

        /// <summary>
        /// هل المصدر هو حساب terminal
        /// true = نعم (في حالة الإرجاع من التاجر)
        /// </summary>
        public bool IsTerminal { get; set; }
    }

    /// <summary>
    /// معلومات المستفيد من الإرجاع (العميل)
    /// </summary>
    public class RefundBeneficiaryInfo
    {
        /// <summary>
        /// رقم محفظة العميل
        /// </summary>
        public string Code { get; set; }

        /// <summary>
        /// معرف العملة
        /// </summary>
        public string CurrencyId { get; set; }
    }

    /// <summary>
    /// نموذج استجابة الخطأ من SabaCash
    /// </summary>
    public class SabaCashErrorResponse
    {
        /// <summary>
        /// تفاصيل الخطأ
        /// </summary>
        public ErrorInfo Errors { get; set; }
    }

    /// <summary>
    /// معلومات الخطأ التفصيلية
    /// </summary>
    public class ErrorInfo
    {
        /// <summary>
        /// حالة HTTP
        /// مثال: "400 BAD_REQUEST"
        /// </summary>
        public string Status { get; set; }

        /// <summary>
        /// وقت حدوث الخطأ
        /// </summary>
        public string Timestamp { get; set; }

        /// <summary>
        /// نوع الخطأ
        /// عادة: "ApiBaseException"
        /// </summary>
        public string Message { get; set; }

        /// <summary>
        /// المسار الذي حدث فيه الخطأ
        /// </summary>
        public string Uri { get; set; }

        /// <summary>
        /// اسم الخدمة المصغرة
        /// </summary>
        public string Microservice { get; set; }

        /// <summary>
        /// قائمة الأخطاء الفرعية مع التفاصيل
        /// </summary>
        public List<SubError> SubErrors { get; set; }
    }

    /// <summary>
    /// تفاصيل خطأ فرعي
    /// </summary>
    public class SubError
    {
        /// <summary>
        /// رسالة الخطأ بالتفصيل
        /// مثال: "الرصيد غير كافي"
        /// </summary>
        public string Message { get; set; }

        /// <summary>
        /// الحقل المتعلق بالخطأ (إن وجد)
        /// </summary>
        public string Field { get; set; }

        /// <summary>
        /// رمز الخطأ (إن وجد)
        /// </summary>
        public string ErrorCode { get; set; }

        /// <summary>
        /// معرف الخطأ للتتبع
        /// </summary>
        public string ErrorId { get; set; }

        /// <summary>
        /// القيمة المرفوضة
        /// </summary>
        public string RejectedValue { get; set; }

        /// <summary>
        /// الكائن المتعلق بالخطأ
        /// </summary>
        public string Object { get; set; }
    }
}