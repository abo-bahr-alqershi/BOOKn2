namespace YemenBooking.Core.Entities;

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان الدور
/// Role entity
/// </summary>
[Display(Name = "كيان الدور")]
public class Role : BaseEntity<Guid>
{
    /// <summary>
    /// اسم الدور (admin, owner, manager, customer)
    /// Role name (admin, owner, manager, customer)
    /// </summary>
    [Display(Name = "اسم الدور")]
    public string Name { get; set; }
    
    /// <summary>
    /// المستخدمون المرتبطون بهذا الدور
    /// Users associated with this role
    /// </summary>
    [Display(Name = "المستخدمون المرتبطون بهذا الدور")]
    public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
} 