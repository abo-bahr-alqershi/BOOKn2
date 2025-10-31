namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

/// <summary>
/// كيان الموظف
/// Staff entity
/// </summary>
[Display(Name = "كيان الموظف")]
public class Staff : BaseEntity<Guid>
{
    /// <summary>
    /// معرف المستخدم
    /// User identifier
    /// </summary>
    [Display(Name = "معرف المستخدم")]
    public Guid UserId { get; set; }
    
    /// <summary>
    /// معرف الكيان
    /// Property identifier
    /// </summary>
    [Display(Name = "معرف الكيان")]
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// منصب الموظف (مدير، موظف استقبال، نظافة)
    /// Staff position (Manager, Receptionist, Housekeeping)
    /// </summary>
    [Display(Name = "منصب الموظف")]
    public StaffPosition Position { get; set; }
    
    /// <summary>
    /// الصلاحيات (JSON)
    /// Permissions (JSON)
    /// </summary>
    [Display(Name = "الصلاحيات")]
    public string Permissions { get; set; }
    
    /// <summary>
    /// المستخدم المرتبط بالموظف
    /// User associated with the staff
    /// </summary>
    [Display(Name = "المستخدم المرتبط بالموظف")]
    public virtual User User { get; set; }
    
    /// <summary>
    /// الكيان المرتبط بالموظف
    /// Property associated with the staff
    /// </summary>
    [Display(Name = "الكيان المرتبط بالموظف")]
    public virtual Property Property { get; set; }
}