namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

/// <summary>
/// كيان إجراء الإدارة
/// Admin Action entity
/// </summary>
[Display(Name = "كيان إجراء الإدارة")]
public class AdminAction : BaseEntity<Guid>
{
    /// <summary>
    /// معرف المدير
    /// Admin identifier
    /// </summary>
    [Display(Name = "معرف المدير")]
    public Guid AdminId { get; set; }
    
    /// <summary>
    /// معرف الهدف
    /// Target identifier
    /// </summary>
    [Display(Name = "معرف الهدف")]
    public Guid TargetId { get; set; }
    
    /// <summary>
    /// نوع الهدف (property, user, booking)
    /// Target type (property, user, booking)
    /// </summary>
    [Display(Name = "نوع الهدف")]
    public TargetType TargetType { get; set; }
    
    /// <summary>
    /// نوع الإجراء (create, update, delete, approve)
    /// Action type (create, update, delete, approve)
    /// </summary>
    [Display(Name = "نوع الإجراء")]
    public ActionType ActionType { get; set; }
    
    /// <summary>
    /// الطابع الزمني للإجراء
    /// Action timestamp
    /// </summary>
    [Display(Name = "الطابع الزمني للإجراء")]
    public DateTime Timestamp { get; set; }
    
    /// <summary>
    /// التغييرات (JSON)
    /// Changes (JSON)
    /// </summary>
    [Display(Name = "التغييرات")]
    public string Changes { get; set; }
    
    /// <summary>
    /// المدير المرتبط بالإجراء
    /// Admin associated with the action
    /// </summary>
    [Display(Name = "المدير المرتبط بالإجراء")]
    public virtual User Admin { get; set; }
} 