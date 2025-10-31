namespace YemenBooking.Application.Features.DynamicFields.DTOs;
using YemenBooking.Application.Features.Units.DTOs;

using System.Collections.Generic;

/// <summary>
/// بيانات نقل مجموعة الحقول مع الحقول المرتبطة
/// DTO for field group along with its fields
/// </summary>
public class FieldGroupWithFieldsDto
{
    /// <summary>
    /// معرف المجموعة
    /// GroupId
    /// </summary>
    public string GroupId { get; set; }

    /// <summary>
    /// اسم المجموعة
    /// GroupName
    /// </summary>
    public string GroupName { get; set; }

    /// <summary>
    /// الاسم المعروض للمجموعة
    /// DisplayName
    /// </summary>
    public string DisplayName { get; set; }

    /// <summary>
    /// وصف المجموعة
    /// Description
    /// </summary>
    public string Description { get; set; }

    /// <summary>
    /// ترتيب العرض
    /// SortOrder
    /// </summary>
    public int SortOrder { get; set; }

    /// <summary>
    /// هل المجموعة قابلة للطي
    /// IsCollapsible
    /// </summary>
    public bool IsCollapsible { get; set; }

    /// <summary>
    /// هل تكون الموسعة افتراضياً
    /// IsExpandedByDefault
    /// </summary>
    public bool IsExpandedByDefault { get; set; }

    /// <summary>
    /// قائمة الحقول المرتبطة
    /// Fields
    /// </summary>
    public List<UnitTypeFieldDto> Fields { get; set; }
} 