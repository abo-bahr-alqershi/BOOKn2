namespace YemenBooking.Core.Interfaces;

/// <summary>
/// الواجهة الأساسية لجميع الكيانات في النظام
/// Base interface for all entities in the system
/// </summary>
public interface IBaseEntity<TId>
    where TId : struct{
    /// <summary>
    /// المعرف الفريد للكيان
    /// Unique identifier for the entity
    /// </summary>
    TId Id { get; set; }
    
    /// <summary>
    /// تاريخ إنشاء الكيان
    /// Creation date of the entity
    /// </summary>
    DateTime CreatedAt { get; set; }
    
    /// <summary>
    /// تاريخ آخر تحديث للكيان (اختياري)
    /// Last update date of the entity (optional)
    /// </summary>
    DateTime UpdatedAt { get; set; }
    
    /// <summary>
    /// حالة نشاط الكيان
    /// Activity status of the entity
    /// </summary>
    bool IsActive { get; set; }
}