namespace YemenBooking.Application.Features.DynamicFields.Commands.UpdateUnit;

using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using Unit = MediatR.Unit;

/// <summary>
/// تحديث حقل ديناميكي لنوع الوحدة
/// Update existing dynamic field for unit type
/// </summary>
public class UpdateUnitTypeFieldCommand : IRequest<ResultDto<Unit>>
{
    /// <summary>
    /// معرف الحقل
    /// FieldId
    /// </summary>
    public string FieldId { get; set; } = string.Empty;

    /// <summary>
    /// اسم الحقل
    /// FieldName
    /// </summary>
    public string FieldName { get; set; } = string.Empty;

    /// <summary>
    /// الاسم المعروض للحقل
    /// DisplayName
    /// </summary>
    public string DisplayName { get; set; } = string.Empty;

    /// <summary>
    /// وصف الحقل
    /// Description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// خيارات الحقل (JSON)
    /// FieldOptions
    /// </summary>
    public Dictionary<string, object> FieldOptions { get; set; } = new();

    /// <summary>
    /// قواعد التحقق المخصصة (JSON)
    /// ValidationRules
    /// </summary>
    public Dictionary<string, object> ValidationRules { get; set; } = new();

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
    public string Category { get; set; } = string.Empty;

    /// <summary>
    /// يحدد ما إذا كان الحقل مخصص للوحدات
    /// IsForUnits
    /// </summary>
    public bool IsForUnits { get; set; }
    /// <summary>
    /// مجموعة الحقول المرتبطة (اختياري)
    /// GroupId (optional)
    /// </summary>
    public string? GroupId { get; set; }
    /// <summary>
    /// هل يظهر في الكروت؟ (اختياري)
    /// Show in cards
    /// </summary>
    public bool? ShowInCards { get; set; }

    /// <summary>
    /// هل الحقل فلترة أساسية؟ (اختياري)
    /// Is primary filter
    /// </summary>
    public bool? IsPrimaryFilter { get; set; }

    /// <summary>
    /// أولوية الترتيب (اختياري)
    /// Order priority
    /// </summary>
    public int? Priority { get; set; }

    /// <summary>
    /// نوع الحقل (اختياري عند التحديث)
    /// FieldTypeId (optional on update)
    /// </summary>
    public string? FieldTypeId { get; set; }
}