namespace YemenBooking.Application.Features.DynamicFields.Commands.ManageFieldGroups;

using global::YemenBooking.Application.Common.Models;
using MediatR;
using Unit = MediatR.Unit;

/// <summary>
/// تحديث مجموعة حقول
/// Update existing field group
/// </summary>
public class UpdateFieldGroupCommand : IRequest<ResultDto<Unit>>
{
    /// <summary>
    /// معرف المجموعة
    /// GroupId
    /// </summary>
    public string GroupId { get; set; } = string.Empty;

    /// <summary>
    /// اسم المجموعة
    /// GroupName
    /// </summary>
    public string GroupName { get; set; } = string.Empty;

    /// <summary>
    /// الاسم المعروض للمجموعة
    /// DisplayName
    /// </summary>
    public string DisplayName { get; set; } = string.Empty;

    /// <summary>
    /// وصف المجموعة
    /// Description
    /// </summary>
    public string Description { get; set; } = string.Empty;

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
    /// هل تكون موسعة افتراضياً
    /// IsExpandedByDefault
    /// </summary>
    public bool IsExpandedByDefault { get; set; }
}
