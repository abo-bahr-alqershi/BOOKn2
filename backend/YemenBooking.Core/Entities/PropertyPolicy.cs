namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

/// <summary>
/// كيان سياسة الكيان
/// Property Policy entity
/// </summary>
[Display(Name = "كيان سياسة الكيان")]
public class PropertyPolicy : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الكيان
    /// Property identifier
    /// </summary>
    [Display(Name = "معرف الكيان")]
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// نوع السياسة (إلغاء، تعديل، دخول، أطفال، حيوانات)
    /// Policy type (Cancellation, Modification, CheckIn, Children, Pets)
    /// </summary>
    [Display(Name = "نوع السياسة")]
    public PolicyType Type { get; set; }
    
    /// <summary>
    /// عدد أيام نافذة الإلغاء قبل تاريخ الوصول
    /// Number of days before check-in to allow cancellation
    /// </summary>
    [Display(Name = "عدد أيام نافذة الإلغاء قبل تاريخ الوصول")]
    public int CancellationWindowDays { get; set; }
    
    /// <summary>
    /// يتطلب الدفع الكامل قبل التأكيد
    /// Requires full payment before confirmation
    /// </summary>
    [Display(Name = "يتطلب الدفع الكامل قبل التأكيد")]
    public bool RequireFullPaymentBeforeConfirmation { get; set; }
    
    /// <summary>
    /// الحد الأدنى لنسبة الدفع المقدمة (كنسبة مئوية)
    /// Minimum deposit percentage (as percentage)
    /// </summary>
    [Display(Name = "الحد الأدنى لنسبة الدفع المقدمة")]
    public decimal MinimumDepositPercentage { get; set; }
    
    /// <summary>
    /// الحد الأدنى للساعات قبل تسجيل الوصول لتعديل الحجز
    /// Minimum hours before check-in to allow modification
    /// </summary>
    [Display(Name = "الحد الأدنى للساعات قبل تسجيل الوصول لتعديل الحجز")]
    public int MinHoursBeforeCheckIn { get; set; }
    
    /// <summary>
    /// وصف السياسة
    /// Policy description
    /// </summary>
    [Display(Name = "وصف السياسة")]
    public string Description { get; set; }
    
    /// <summary>
    /// قواعد السياسة (JSON)
    /// Policy rules (JSON)
    /// </summary>
    [Display(Name = "قواعد السياسة")]
    public string Rules { get; set; }
    
    /// <summary>
    /// الكيان المرتبط بالسياسة
    /// Property associated with the policy
    /// </summary>
    [Display(Name = "الكيان المرتبط بالسياسة")]
    public virtual Property Property { get; set; }
}