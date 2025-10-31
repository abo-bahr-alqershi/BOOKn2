namespace YemenBooking.Application.Features.DynamicFields.Commands.CreateUnit;

using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;

/// <summary>
/// إنشاء حقل ديناميكي جديد لنوع الوحدة
/// Create new dynamic field for unit type
/// </summary>
public class CreateUnitTypeFieldCommand : IRequest<ResultDto<string>>
{
    /// <summary>
    /// معرف نوع الوحدة
    /// UnitTypeId
    /// </summary>
    public required string UnitTypeId { get; set; }

    /// <summary>
    /// معرف نوع الحقل
    /// FieldTypeId
    /// </summary>
    public required string FieldTypeId { get; set; }

    /// <summary>
    /// اسم الحقل
    /// FieldName
    /// </summary>
    public required string FieldName { get; set; }

    /// <summary>
    /// الاسم المعروض للحقل
    /// DisplayName
    /// </summary>
    public required string DisplayName { get; set; }

    /// <summary>
    /// وصف الحقل
    /// Description
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// خيارات الحقل (JSON)
    /// FieldOptions
    /// </summary>
    public Dictionary<string, object>? FieldOptions { get; set; }

    /// <summary>
    /// قواعد التحقق المخصصة (JSON)
    /// ValidationRules
    /// </summary>
    public Dictionary<string, object>? ValidationRules { get; set; }

    /// <summary>
    /// هل الحقل إلزامي
    /// IsRequired
    /// </summary>
    public bool IsRequired { get; set; }

    /// <summary>
    /// هل يظهر في البحث
    /// IsSearchable
    /// </summary>
    public bool IsSearchable { get; set; }

    /// <summary>
    /// هل يظهر للعملاء
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
    public string? Category { get; set; }

    /// <summary>
    /// يحدد ما إذا كان الحقل مخصص للوحدات
    /// IsForUnits
    /// </summary>
    public bool IsForUnits { get; set; }

    /// <summary>
    /// مجموعة الحقول المرتبطة
    /// GroupId (اختياري)
    /// </summary>
    public string? GroupId { get; set; }
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