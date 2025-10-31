using System;

namespace YemenBooking.Core.Interfaces;

/// <summary>
/// واجهة قيمة الحقل
/// Field value interface
/// </summary>
public interface IFieldValue
{
    /// <summary>
    /// معرف القيمة
    /// Value ID
    /// </summary>
    Guid Id { get; }
    
    /// <summary>
    /// قيمة الحقل
    /// Field value
    /// </summary>
    string FieldValue { get; set; }
}
