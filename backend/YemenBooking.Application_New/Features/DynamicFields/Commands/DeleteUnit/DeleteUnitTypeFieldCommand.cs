namespace YemenBooking.Application.Features.DynamicFields.Commands.DeleteUnit;

using MediatR;
using YemenBooking.Application.Common.Models;
using Unit = MediatR.Unit;

/// <summary>
/// حذف حقل ديناميكي من نوع الكيان
/// Delete dynamic field from property type
/// </summary>
public class DeleteUnitTypeFieldCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الحقل
    /// FieldId
    /// </summary>
    public string FieldId { get; set; }
} 