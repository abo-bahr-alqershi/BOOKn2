namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان دور المستخدم
/// User Role entity
/// </summary>
[Display(Name = "كيان دور المستخدم")]
public class UserRole : BaseEntity<Guid>
{
    /// <summary>
    /// معرف المستخدم
    /// User identifier
    /// </summary>
    [Display(Name = "معرف المستخدم")]
    public Guid UserId { get; set; }
    
    /// <summary>
    /// معرف الدور
    /// Role identifier
    /// </summary>
    [Display(Name = "معرف الدور")]
    public Guid RoleId { get; set; }
    
    /// <summary>
    /// تاريخ التخصيص
    /// Assignment date
    /// </summary>
    [Display(Name = "تاريخ التخصيص")]
    public DateTime AssignedAt { get; set; }
    
    /// <summary>
    /// المستخدم المرتبط بالدور
    /// User associated with the role
    /// </summary>
    [Display(Name = "المستخدم المرتبط بالدور")]
    public virtual User User { get; set; }
    
    /// <summary>
    /// الدور المرتبط بالمستخدم
    /// Role associated with the user
    /// </summary>
    [Display(Name = "الدور المرتبط بالمستخدم")]
    public virtual Role Role { get; set; }
} 