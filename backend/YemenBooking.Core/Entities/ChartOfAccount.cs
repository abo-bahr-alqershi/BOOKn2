using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان دليل الحسابات - يحدد جميع الحسابات المحاسبية في النظام
/// Chart of Accounts Entity - Defines all accounting accounts in the system
/// </summary>
[Display(Name = "دليل الحسابات")]
public class ChartOfAccount : BaseEntity<Guid>
{
    /// <summary>
    /// رقم الحساب (مثال: 1000, 1100, 2000)
    /// Account number (e.g., 1000, 1100, 2000)
    /// </summary>
    [Required]
    [Display(Name = "رقم الحساب")]
    public string AccountNumber { get; set; }

    /// <summary>
    /// اسم الحساب بالعربية
    /// Account name in Arabic
    /// </summary>
    [Required]
    [Display(Name = "اسم الحساب بالعربية")]
    public string NameAr { get; set; }

    /// <summary>
    /// اسم الحساب بالإنجليزية
    /// Account name in English
    /// </summary>
    [Required]
    [Display(Name = "اسم الحساب بالإنجليزية")]
    public string NameEn { get; set; }

    /// <summary>
    /// نوع الحساب (أصول، التزامات، حقوق ملكية، إيرادات، مصروفات)
    /// Account type (Assets, Liabilities, Equity, Revenue, Expenses)
    /// </summary>
    [Required]
    [Display(Name = "نوع الحساب")]
    public AccountType AccountType { get; set; }

    /// <summary>
    /// تصنيف الحساب (حساب رئيسي أو فرعي)
    /// Account category (Main or Sub)
    /// </summary>
    [Required]
    [Display(Name = "تصنيف الحساب")]
    public AccountCategory Category { get; set; }

    /// <summary>
    /// معرف الحساب الرئيسي (للحسابات الفرعية)
    /// Parent account ID (for sub-accounts)
    /// </summary>
    [Display(Name = "معرف الحساب الرئيسي")]
    public Guid? ParentAccountId { get; set; }

    /// <summary>
    /// الحساب الرئيسي
    /// Parent account
    /// </summary>
    public virtual ChartOfAccount ParentAccount { get; set; }

    /// <summary>
    /// الحسابات الفرعية
    /// Sub-accounts
    /// </summary>
    public virtual ICollection<ChartOfAccount> SubAccounts { get; set; } = new List<ChartOfAccount>();

    /// <summary>
    /// طبيعة الحساب (مدين أو دائن)
    /// Account nature (Debit or Credit)
    /// </summary>
    [Required]
    [Display(Name = "طبيعة الحساب")]
    public AccountNature NormalBalance { get; set; }

    /// <summary>
    /// مستوى الحساب في الهيكل الشجري
    /// Account level in the hierarchy
    /// </summary>
    [Display(Name = "مستوى الحساب")]
    public int Level { get; set; } = 1;

    /// <summary>
    /// وصف الحساب
    /// Account description
    /// </summary>
    [Display(Name = "وصف الحساب")]
    public string Description { get; set; }

    /// <summary>
    /// الرصيد الحالي للحساب
    /// Current account balance
    /// </summary>
    [Display(Name = "الرصيد الحالي")]
    public decimal Balance { get; set; } = 0;

    /// <summary>
    /// العملة المستخدمة للحساب
    /// Currency used for the account
    /// </summary>
    [Display(Name = "العملة")]
    public string Currency { get; set; } = "YER";

    /// <summary>
    /// هل الحساب نشط
    /// Is account active
    /// </summary>
    [Display(Name = "الحساب نشط")]
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// هل الحساب محمي من الحذف (حسابات النظام الأساسية)
    /// Is account protected from deletion (system core accounts)
    /// </summary>
    [Display(Name = "حساب محمي")]
    public bool IsSystemAccount { get; set; } = false;

    /// <summary>
    /// يمكن ترحيل القيود إليه مباشرة
    /// Can post journal entries directly
    /// </summary>
    [Display(Name = "يمكن الترحيل إليه")]
    public bool CanPost { get; set; } = false;

    /// <summary>
    /// معرف المستخدم المرتبط (للحسابات الشخصية)
    /// Associated user ID (for personal accounts)
    /// </summary>
    [Display(Name = "معرف المستخدم المرتبط")]
    public Guid? UserId { get; set; }

    /// <summary>
    /// المستخدم المرتبط
    /// Associated user
    /// </summary>
    public virtual User User { get; set; }

    /// <summary>
    /// معرف العقار المرتبط (لحسابات العقارات)
    /// Associated property ID (for property accounts)
    /// </summary>
    [Display(Name = "معرف العقار المرتبط")]
    public Guid? PropertyId { get; set; }

    /// <summary>
    /// العقار المرتبط
    /// Associated property
    /// </summary>
    public virtual Property Property { get; set; }

    /// <summary>
    /// تاريخ الإنشاء
    /// Creation date
    /// </summary>
    [Display(Name = "تاريخ الإنشاء")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// تاريخ آخر تحديث
    /// Last update date
    /// </summary>
    [Display(Name = "تاريخ آخر تحديث")]
    public DateTime? UpdatedAt { get; set; }

    /// <summary>
    /// معرف المستخدم الذي أنشأ الحساب
    /// User ID who created the account
    /// </summary>
    [Display(Name = "أنشأه")]
    public Guid? CreatedBy { get; set; }

    /// <summary>
    /// معرف المستخدم الذي عدّل الحساب
    /// User ID who updated the account
    /// </summary>
    [Display(Name = "عدّله")]
    public Guid? UpdatedBy { get; set; }

    /// <summary>
    /// القيود المحاسبية المدينة
    /// Debit journal entries
    /// </summary>
    public virtual ICollection<FinancialTransaction> DebitTransactions { get; set; } = new List<FinancialTransaction>();

    /// <summary>
    /// القيود المحاسبية الدائنة
    /// Credit journal entries
    /// </summary>
    public virtual ICollection<FinancialTransaction> CreditTransactions { get; set; } = new List<FinancialTransaction>();
}

/// <summary>
/// أنواع الحسابات المحاسبية
/// Account types
/// </summary>
public enum AccountType
{
    [Display(Name = "أصول")]
    Assets = 1,
    
    [Display(Name = "التزامات")]
    Liabilities = 2,
    
    [Display(Name = "حقوق الملكية")]
    Equity = 3,
    
    [Display(Name = "إيرادات")]
    Revenue = 4,
    
    [Display(Name = "مصروفات")]
    Expenses = 5
}

/// <summary>
/// تصنيف الحساب
/// Account category
/// </summary>
public enum AccountCategory
{
    [Display(Name = "حساب رئيسي")]
    Main = 1,
    
    [Display(Name = "حساب فرعي")]
    Sub = 2
}

/// <summary>
/// طبيعة الحساب المحاسبي
/// Account nature
/// </summary>
public enum AccountNature
{
    [Display(Name = "مدين")]
    Debit = 1,
    
    [Display(Name = "دائن")]
    Credit = 2
}
