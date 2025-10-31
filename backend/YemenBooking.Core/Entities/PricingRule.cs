namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان قواعد التسعير
/// Pricing rule entity
/// </summary>
[Display(Name = "كيان قواعد التسعير")]
public class PricingRule : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الوحدة
    /// Unit identifier
    /// </summary>
    [Display(Name = "معرف الوحدة")]
    public Guid UnitId { get; set; }
    public virtual Unit Unit { get; set; }

    /// <summary>
    /// نوع السعر
    /// Price type
    /// </summary>
    [Display(Name = "نوع السعر")]
    public string PriceType { get; set; } = null!;

    /// <summary>
    /// تاريخ بداية السعر
    /// Start date
    /// </summary>
    [Display(Name = "تاريخ بداية السعر")]
    public DateTime StartDate { get; set; }

    /// <summary>
    /// تاريخ نهاية السعر
    /// End date
    /// </summary>
    [Display(Name = "تاريخ نهاية السعر")]
    public DateTime EndDate { get; set; }
    /// <summary>
    /// وقت بداية السعر
    /// </summary>
    [Display(Name = "وقت بداية السعر")]
    public TimeSpan? StartTime { get; set; }
    /// <summary>
    /// وقت نهاية السعر
    /// </summary>
    [Display(Name = "وقت نهاية السعر")]
    public TimeSpan? EndTime { get; set; }

    /// <summary>
    /// مبلغ السعر
    /// Price amount
    /// </summary>
    [Display(Name = "مبلغ السعر")]
    public decimal PriceAmount { get; set; }

    /// <summary>
    /// فئة التسعير
    /// Pricing tier
    /// </summary>
    [Display(Name = "فئة التسعير")]
    public string PricingTier { get; set; } = null!;

    /// <summary>
    /// الزيادة أو الخصم بالنسبة المئوية
    /// Percentage change
    /// </summary>
    [Display(Name = "الزيادة أو الخصم بالنسبة المئوية")]
    public decimal? PercentageChange { get; set; }

    /// <summary>
    /// السعر الأدنى
    /// Minimum price
    /// </summary>
    [Display(Name = "السعر الأدنى")]
    public decimal? MinPrice { get; set; }

    /// <summary>
    /// السعر الأقصى
    /// Maximum price
    /// </summary>
    [Display(Name = "السعر الأقصى")]
    public decimal? MaxPrice { get; set; }

    /// <summary>
    /// الوصف
    /// Description
    /// </summary>
    [Display(Name = "الوصف")]
    public string? Description { get; set; }
    /// <summary>
    /// عملة السعر
    /// Currency of the price
    /// </summary>
    public string Currency { get; set; } = null!;

    /// <summary>
    /// الملاحة إلى كيان العملة
    /// Navigation to Currency entity
    /// </summary>
    public virtual Currency? CurrencyRef { get; set; }
} 