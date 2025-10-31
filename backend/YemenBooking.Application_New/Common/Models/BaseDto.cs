namespace YemenBooking.Application.Common.Models;

/// <summary>
/// DTO الأساسي لجميع كائنات النقل
/// Base DTO for all data transfer objects
/// </summary>
public abstract class BaseDto
{
    /// <summary>
    /// المعرف الفريد
    /// Unique identifier
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// تاريخ الإنشاء
    /// Creation date
    /// </summary>
    public DateTime CreatedAt { get; set; }
    
    /// <summary>
    /// تاريخ آخر تحديث
    /// Last update date
    /// </summary>
    public DateTime UpdatedAt { get; set; }
    
    /// <summary>
    /// حالة النشاط
    /// Active status
    /// </summary>
    public bool IsActive { get; set; }
}