namespace YemenBooking.Application.Features.DynamicFields.Commands.ManageFields;
using YemenBooking.Application.Features.DynamicFields.DTOs;

using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using Unit = MediatR.Unit;

/// <summary>
/// إعادة ترتيب الحقول الديناميكية لنوع الوحدة
/// Reorder dynamic fields for unit type
/// </summary>
public class ReorderUnitTypeFieldsCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف نوع الوحدة
    /// UnitTypeId
    /// </summary>
    public string UnitTypeId { get; set; }

    /// <summary>
    /// طلبات ترتيب الحقول
    /// FieldOrders
    /// </summary>
    public List<FieldOrderDto> FieldOrders { get; set; }
} 