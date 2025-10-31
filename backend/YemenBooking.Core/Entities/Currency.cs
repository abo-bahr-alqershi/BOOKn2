namespace YemenBooking.Core.Entities;

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان العملة
/// Currency entity with string primary key (Code)
/// </summary>
[Display(Name = "كيان العملة")]
public class Currency
{
    /// <summary>
    /// رمز العملة (المعرف الأساسي)
    /// Currency code (primary key)
    /// </summary>
    [Key]
    [Display(Name = "رمز العملة")]
    public string Code { get; set; }

    /// <summary>
    /// الرمز باللغة العربية
    /// Arabic currency code
    /// </summary>
    public string ArabicCode { get; set; }

    /// <summary>
    /// اسم العملة
    /// Currency name
    /// </summary>
    public string Name { get; set; }

    /// <summary>
    /// اسم العملة بالعربية
    /// Arabic currency name
    /// </summary>
    public string ArabicName { get; set; }

    /// <summary>
    /// هل هي العملة الافتراضية
    /// Whether this is the default currency
    /// </summary>
    public bool IsDefault { get; set; }

    /// <summary>
    /// سعر الصرف بالنسبة للعملة الافتراضية
    /// Exchange rate relative to default currency; null for default
    /// </summary>
    public decimal? ExchangeRate { get; set; }

    /// <summary>
    /// تاريخ آخر تحديث لسعر الصرف
    /// Last update timestamp for the exchange rate
    /// </summary>
    public DateTime? LastUpdated { get; set; }

    /// <summary>
    /// عقارات تستخدم هذه العملة (ملاحة عكسية)
    /// Properties that use this currency (reverse navigation via Property.Currency)
    /// </summary>
    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();
}

