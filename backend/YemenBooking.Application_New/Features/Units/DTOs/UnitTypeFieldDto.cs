namespace YemenBooking.Application.Features.Units.DTOs;

using System.Collections.Generic;

/// <summary>
/// بيانات نقل الحقول الديناميكية لنوع الكيان
/// DTO for UnitTypeField entity
/// </summary>
public class UnitTypeFieldDto
{
    /// <summary>
    /// معرف الحقل
    /// FieldId
    /// </summary>
    public string FieldId { get; set; }

    /// <summary>
    /// معرف نوع االوحدة
    /// UnitTypeId
    /// </summary>
    public string UnitTypeId { get; set; }

    /// <summary>
    /// معرف نوع الحقل
    /// FieldTypeId
    /// </summary>
    public string FieldTypeId { get; set; }

    /// <summary>
    /// اسم الحقل
    /// FieldName
    /// </summary>
    public string FieldName { get; set; }

    /// <summary>
    /// الاسم المعروض للحقل
    /// DisplayName
    /// </summary>
    public string DisplayName { get; set; }

    /// <summary>
    /// وصف الحقل
    /// Description
    /// </summary>
    public string Description { get; set; }

    /// <summary>
    /// خيارات الحقل (JSON)
    /// FieldOptions
    /// </summary>
    public Dictionary<string, object> FieldOptions { get; set; }

    /// <summary>
    /// قواعد التحقق المخصصة (JSON)
    /// ValidationRules
    /// </summary>
    public Dictionary<string, object> ValidationRules { get; set; }

    /// <summary>
    /// هل الحقل إلزامي
    /// IsRequired
    /// </summary>
    public bool IsRequired { get; set; }

    /// <summary>
    /// هل الحقل قابل للفلترة
    /// IsSearchable
    /// </summary>
    public bool IsSearchable { get; set; }

    /// <summary>
    /// هل الحقل عام
    /// IsPublic
    /// </summary>
    public bool IsPublic { get; set; }

    /// <summary>
    /// ترتيب الحقل
    /// SortOrder
    /// </summary>
    public int SortOrder { get; set; }

    /// <summary>
    /// فئة الحقل
    /// Category
    /// </summary>
    public string Category { get; set; }

    /// <summary>
    /// معرف المجموعة المرتبطة (إن وجدت)
    /// GroupId (optional)
    /// </summary>
    public string GroupId { get; set; }

    /// <summary>
    /// يحدد ما إذا كان الحقل مخصص للوحدات
    /// IsForUnits
    /// </summary>
    public bool IsForUnits { get; set; }
    /// <summary>
    /// هل يظهر في الكروت؟
    /// Show in cards
    /// </summary>
    public bool ShowInCards { get; set; }

    /// <summary>
    /// هل الحقل فلترة أساسية؟
    /// Is primary filter
    /// </summary>
    public bool IsPrimaryFilter { get; set; }

    /// <summary>
    /// أولوية الترتيب
    /// Order priority
    /// </summary>
    public int Priority { get; set; }
} 