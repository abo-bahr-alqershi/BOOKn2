using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان القيود المحاسبية - يسجل جميع العمليات المالية في النظام
/// Financial Transaction Entity - Records all financial operations in the system
/// </summary>
[Display(Name = "القيود المحاسبية")]
public class FinancialTransaction : BaseEntity<Guid>
{
    /// <summary>
    /// رقم القيد (تسلسلي وفريد)
    /// Transaction number (sequential and unique)
    /// </summary>
    [Required]
    [Display(Name = "رقم القيد")]
    public string TransactionNumber { get; set; }

    /// <summary>
    /// تاريخ القيد
    /// Transaction date
    /// </summary>
    [Required]
    [Display(Name = "تاريخ القيد")]
    public DateTime TransactionDate { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// نوع القيد المحاسبي
    /// Journal entry type
    /// </summary>
    [Required]
    [Display(Name = "نوع القيد")]
    public JournalEntryType EntryType { get; set; }

    /// <summary>
    /// نوع العملية المالية
    /// Transaction type
    /// </summary>
    [Required]
    [Display(Name = "نوع العملية")]
    public TransactionType TransactionType { get; set; }

    /// <summary>
    /// معرف الحساب المدين
    /// Debit account ID
    /// </summary>
    [Required]
    [Display(Name = "الحساب المدين")]
    public Guid DebitAccountId { get; set; }

    /// <summary>
    /// الحساب المدين
    /// Debit account
    /// </summary>
    [ForeignKey("DebitAccountId")]
    public virtual ChartOfAccount DebitAccount { get; set; }

    /// <summary>
    /// معرف الحساب الدائن
    /// Credit account ID
    /// </summary>
    [Required]
    [Display(Name = "الحساب الدائن")]
    public Guid CreditAccountId { get; set; }

    /// <summary>
    /// الحساب الدائن
    /// Credit account
    /// </summary>
    [ForeignKey("CreditAccountId")]
    public virtual ChartOfAccount CreditAccount { get; set; }

    /// <summary>
    /// المبلغ
    /// Amount
    /// </summary>
    [Required]
    [Display(Name = "المبلغ")]
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    [Required]
    [Display(Name = "العملة")]
    public string Currency { get; set; } = "YER";

    /// <summary>
    /// سعر الصرف (إذا كانت العملة مختلفة عن العملة الأساسية)
    /// Exchange rate (if currency is different from base currency)
    /// </summary>
    [Display(Name = "سعر الصرف")]
    [Column(TypeName = "decimal(18,4)")]
    public decimal ExchangeRate { get; set; } = 1;

    /// <summary>
    /// المبلغ بالعملة الأساسية
    /// Amount in base currency
    /// </summary>
    [Display(Name = "المبلغ بالعملة الأساسية")]
    [Column(TypeName = "decimal(18,2)")]
    public decimal BaseAmount { get; set; }

    /// <summary>
    /// وصف القيد
    /// Transaction description
    /// </summary>
    [Required]
    [Display(Name = "وصف القيد")]
    public string Description { get; set; }

    /// <summary>
    /// البيان التفصيلي
    /// Detailed narration
    /// </summary>
    [Display(Name = "البيان التفصيلي")]
    public string Narration { get; set; }

    /// <summary>
    /// رقم المستند المرجعي
    /// Reference document number
    /// </summary>
    [Display(Name = "رقم المستند المرجعي")]
    public string ReferenceNumber { get; set; }

    /// <summary>
    /// نوع المستند المرجعي (فاتورة، سند قبض، إلخ)
    /// Reference document type (Invoice, Receipt, etc.)
    /// </summary>
    [Display(Name = "نوع المستند")]
    public string DocumentType { get; set; }

    /// <summary>
    /// معرف الحجز المرتبط (إن وجد)
    /// Associated booking ID (if any)
    /// </summary>
    [Display(Name = "معرف الحجز")]
    public Guid? BookingId { get; set; }

    /// <summary>
    /// الحجز المرتبط
    /// Associated booking
    /// </summary>
    public virtual Booking Booking { get; set; }

    /// <summary>
    /// معرف الدفعة المرتبطة (إن وجد)
    /// Associated payment ID (if any)
    /// </summary>
    [Display(Name = "معرف الدفعة")]
    public Guid? PaymentId { get; set; }

    /// <summary>
    /// الدفعة المرتبطة
    /// Associated payment
    /// </summary>
    public virtual Payment Payment { get; set; }

    /// <summary>
    /// معرف المستخدم الطرف الأول (المدين عادة)
    /// First party user ID (usually debtor)
    /// </summary>
    [Display(Name = "الطرف الأول")]
    public Guid? FirstPartyUserId { get; set; }

    /// <summary>
    /// المستخدم الطرف الأول
    /// First party user
    /// </summary>
    [ForeignKey("FirstPartyUserId")]
    public virtual User FirstPartyUser { get; set; }

    /// <summary>
    /// معرف المستخدم الطرف الثاني (الدائن عادة)
    /// Second party user ID (usually creditor)
    /// </summary>
    [Display(Name = "الطرف الثاني")]
    public Guid? SecondPartyUserId { get; set; }

    /// <summary>
    /// المستخدم الطرف الثاني
    /// Second party user
    /// </summary>
    [ForeignKey("SecondPartyUserId")]
    public virtual User SecondPartyUser { get; set; }

    /// <summary>
    /// معرف العقار المرتبط (إن وجد)
    /// Associated property ID (if any)
    /// </summary>
    [Display(Name = "معرف العقار")]
    public Guid? PropertyId { get; set; }

    /// <summary>
    /// العقار المرتبط
    /// Associated property
    /// </summary>
    public virtual Property Property { get; set; }

    /// <summary>
    /// معرف الوحدة المرتبطة (إن وجد)
    /// Associated unit ID (if any)
    /// </summary>
    [Display(Name = "معرف الوحدة")]
    public Guid? UnitId { get; set; }

    /// <summary>
    /// الوحدة المرتبطة
    /// Associated unit
    /// </summary>
    public virtual Unit Unit { get; set; }

    /// <summary>
    /// حالة القيد
    /// Transaction status
    /// </summary>
    [Required]
    [Display(Name = "حالة القيد")]
    public TransactionStatus Status { get; set; } = TransactionStatus.Draft;

    /// <summary>
    /// تاريخ الترحيل
    /// Posting date
    /// </summary>
    [Display(Name = "تاريخ الترحيل")]
    public DateTime? PostingDate { get; set; }

    /// <summary>
    /// هل القيد مرحّل
    /// Is transaction posted
    /// </summary>
    [Display(Name = "مرحّل")]
    public bool IsPosted { get; set; } = false;

    /// <summary>
    /// هل القيد معكوس
    /// Is transaction reversed
    /// </summary>
    [Display(Name = "معكوس")]
    public bool IsReversed { get; set; } = false;

    /// <summary>
    /// معرف القيد العكسي (إن وجد)
    /// Reverse transaction ID (if any)
    /// </summary>
    [Display(Name = "القيد العكسي")]
    public Guid? ReverseTransactionId { get; set; }

    /// <summary>
    /// القيد العكسي
    /// Reverse transaction
    /// </summary>
    [ForeignKey("ReverseTransactionId")]
    public virtual FinancialTransaction ReverseTransaction { get; set; }

    /// <summary>
    /// السنة المالية
    /// Fiscal year
    /// </summary>
    [Display(Name = "السنة المالية")]
    public int FiscalYear { get; set; }

    /// <summary>
    /// الفترة المحاسبية (الشهر)
    /// Accounting period (month)
    /// </summary>
    [Display(Name = "الفترة المحاسبية")]
    public int FiscalPeriod { get; set; }

    /// <summary>
    /// معرف دفتر اليومية
    /// Journal ID
    /// </summary>
    [Display(Name = "دفتر اليومية")]
    public Guid? JournalId { get; set; }

    /// <summary>
    /// رقم الدفعة (للقيود المجمعة)
    /// Batch number (for batch entries)
    /// </summary>
    [Display(Name = "رقم الدفعة")]
    public string BatchNumber { get; set; }

    /// <summary>
    /// المرفقات (JSON لقائمة روابط المستندات)
    /// Attachments (JSON for document links list)
    /// </summary>
    [Display(Name = "المرفقات")]
    public string AttachmentsJson { get; set; }

    /// <summary>
    /// ملاحظات إضافية
    /// Additional notes
    /// </summary>
    [Display(Name = "ملاحظات")]
    public string Notes { get; set; }

    /// <summary>
    /// العمولة (إن وجدت)
    /// Commission (if any)
    /// </summary>
    [Display(Name = "العمولة")]
    [Column(TypeName = "decimal(18,2)")]
    public decimal? Commission { get; set; }

    /// <summary>
    /// نسبة العمولة
    /// Commission percentage
    /// </summary>
    [Display(Name = "نسبة العمولة")]
    [Column(TypeName = "decimal(5,2)")]
    public decimal? CommissionPercentage { get; set; }

    /// <summary>
    /// الضريبة (إن وجدت)
    /// Tax (if any)
    /// </summary>
    [Display(Name = "الضريبة")]
    [Column(TypeName = "decimal(18,2)")]
    public decimal? Tax { get; set; }

    /// <summary>
    /// نسبة الضريبة
    /// Tax percentage
    /// </summary>
    [Display(Name = "نسبة الضريبة")]
    [Column(TypeName = "decimal(5,2)")]
    public decimal? TaxPercentage { get; set; }

    /// <summary>
    /// الخصم (إن وجد)
    /// Discount (if any)
    /// </summary>
    [Display(Name = "الخصم")]
    [Column(TypeName = "decimal(18,2)")]
    public decimal? Discount { get; set; }

    /// <summary>
    /// نسبة الخصم
    /// Discount percentage
    /// </summary>
    [Display(Name = "نسبة الخصم")]
    [Column(TypeName = "decimal(5,2)")]
    public decimal? DiscountPercentage { get; set; }

    /// <summary>
    /// المبلغ الصافي بعد الخصومات والضرائب
    /// Net amount after discounts and taxes
    /// </summary>
    [Display(Name = "المبلغ الصافي")]
    [Column(TypeName = "decimal(18,2)")]
    public decimal NetAmount { get; set; }

    /// <summary>
    /// تاريخ الإنشاء
    /// Creation date
    /// </summary>
    [Display(Name = "تاريخ الإنشاء")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// معرف المستخدم الذي أنشأ القيد
    /// User ID who created the transaction
    /// </summary>
    [Display(Name = "أنشأه")]
    public Guid? CreatedBy { get; set; }

    /// <summary>
    /// المستخدم الذي أنشأ القيد
    /// User who created the transaction
    /// </summary>
    [ForeignKey("CreatedBy")]
    public virtual User CreatedByUser { get; set; }

    /// <summary>
    /// تاريخ آخر تحديث
    /// Last update date
    /// </summary>
    [Display(Name = "تاريخ آخر تحديث")]
    public DateTime? UpdatedAt { get; set; }

    /// <summary>
    /// معرف المستخدم الذي عدّل القيد
    /// User ID who updated the transaction
    /// </summary>
    [Display(Name = "عدّله")]
    public Guid? UpdatedBy { get; set; }

    /// <summary>
    /// المستخدم الذي عدّل القيد
    /// User who updated the transaction
    /// </summary>
    [ForeignKey("UpdatedBy")]
    public virtual User UpdatedByUser { get; set; }

    /// <summary>
    /// تاريخ الموافقة
    /// Approval date
    /// </summary>
    [Display(Name = "تاريخ الموافقة")]
    public DateTime? ApprovedAt { get; set; }

    /// <summary>
    /// معرف المستخدم الذي وافق على القيد
    /// User ID who approved the transaction
    /// </summary>
    [Display(Name = "وافق عليه")]
    public Guid? ApprovedBy { get; set; }

    /// <summary>
    /// المستخدم الذي وافق على القيد
    /// User who approved the transaction
    /// </summary>
    [ForeignKey("ApprovedBy")]
    public virtual User ApprovedByUser { get; set; }

    /// <summary>
    /// سبب الإلغاء (إن وجد)
    /// Cancellation reason (if any)
    /// </summary>
    [Display(Name = "سبب الإلغاء")]
    public string CancellationReason { get; set; }

    /// <summary>
    /// تاريخ الإلغاء
    /// Cancellation date
    /// </summary>
    [Display(Name = "تاريخ الإلغاء")]
    public DateTime? CancelledAt { get; set; }

    /// <summary>
    /// معرف المستخدم الذي ألغى القيد
    /// User ID who cancelled the transaction
    /// </summary>
    [Display(Name = "ألغاه")]
    public Guid? CancelledBy { get; set; }

    /// <summary>
    /// المستخدم الذي ألغى القيد
    /// User who cancelled the transaction
    /// </summary>
    [ForeignKey("CancelledBy")]
    public virtual User CancelledByUser { get; set; }

    /// <summary>
    /// هل القيد تلقائي (من النظام)
    /// Is automatic transaction (from system)
    /// </summary>
    [Display(Name = "قيد تلقائي")]
    public bool IsAutomatic { get; set; } = false;

    /// <summary>
    /// مصدر القيد التلقائي
    /// Automatic transaction source
    /// </summary>
    [Display(Name = "مصدر القيد")]
    public string AutomaticSource { get; set; }

    /// <summary>
    /// علامات إضافية للبحث والتصنيف
    /// Additional tags for search and categorization
    /// </summary>
    [Display(Name = "العلامات")]
    public string Tags { get; set; }
}

/// <summary>
/// أنواع القيود المحاسبية
/// Journal entry types
/// </summary>
public enum JournalEntryType
{
    [Display(Name = "قيد يومية عام")]
    GeneralJournal = 1,

    [Display(Name = "قيد مبيعات")]
    Sales = 2,

    [Display(Name = "قيد مشتريات")]
    Purchases = 3,

    [Display(Name = "قيد مقبوضات")]
    CashReceipts = 4,

    [Display(Name = "قيد مدفوعات")]
    CashPayments = 5,

    [Display(Name = "قيد تسوية")]
    Adjustment = 6,

    [Display(Name = "قيد إقفال")]
    Closing = 7,

    [Display(Name = "قيد افتتاحي")]
    Opening = 8,

    [Display(Name = "قيد عكسي")]
    Reversal = 9
}

/// <summary>
/// أنواع العمليات المالية
/// Transaction types
/// </summary>
public enum TransactionType
{
    [Display(Name = "حجز جديد")]
    NewBooking = 1,

    [Display(Name = "دفعة مقدمة")]
    AdvancePayment = 2,

    [Display(Name = "دفعة نهائية")]
    FinalPayment = 3,

    [Display(Name = "إلغاء حجز")]
    BookingCancellation = 4,

    [Display(Name = "استرداد مبلغ")]
    Refund = 5,

    [Display(Name = "عمولة منصة")]
    PlatformCommission = 6,

    [Display(Name = "دفعة للمالك")]
    OwnerPayout = 7,

    [Display(Name = "رسوم خدمة")]
    ServiceFee = 8,

    [Display(Name = "ضريبة")]
    Tax = 9,

    [Display(Name = "خصم")]
    Discount = 10,

    [Display(Name = "غرامة تأخير")]
    LateFee = 11,

    [Display(Name = "تعويض")]
    Compensation = 12,

    [Display(Name = "إيداع ضمان")]
    SecurityDeposit = 13,

    [Display(Name = "استرداد ضمان")]
    SecurityDepositRefund = 14,

    [Display(Name = "مصروفات تشغيلية")]
    OperationalExpense = 15,

    [Display(Name = "إيرادات أخرى")]
    OtherIncome = 16,

    [Display(Name = "تحويل بين حسابات")]
    InterAccountTransfer = 17,

    [Display(Name = "تسوية")]
    Adjustment = 18,

    [Display(Name = "رصيد افتتاحي")]
    OpeningBalance = 19,

    [Display(Name = "عمولة وكيل")]
    AgentCommission = 20
}

/// <summary>
/// حالات القيد المحاسبي
/// Transaction status
/// </summary>
public enum TransactionStatus
{
    [Display(Name = "مسودة")]
    Draft = 1,

    [Display(Name = "معلق")]
    Pending = 2,

    [Display(Name = "مرحّل")]
    Posted = 3,

    [Display(Name = "موافق عليه")]
    Approved = 4,

    [Display(Name = "مرفوض")]
    Rejected = 5,

    [Display(Name = "ملغي")]
    Cancelled = 6,

    [Display(Name = "معكوس")]
    Reversed = 7
}
