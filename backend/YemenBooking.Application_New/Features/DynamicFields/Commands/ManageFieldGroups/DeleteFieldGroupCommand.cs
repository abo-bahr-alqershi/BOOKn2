namespace YemenBooking.Application.Features.DynamicFields.Commands.ManageFieldGroups;

using global::YemenBooking.Application.Common.Models;
using MediatR;
using Unit = MediatR.Unit;

/// <summary>
/// حذف مجموعة حقول
/// Delete field group
/// </summary>
public class DeleteFieldGroupCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف المجموعة
    /// GroupId
    /// </summary>
    public string GroupId { get; set; }
} 