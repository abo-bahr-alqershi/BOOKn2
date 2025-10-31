using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.PropertyTypes.Commands.DeleteUnit;

/// <summary>
/// أمر لحذف نوع الوحدة
/// Command to delete a unit type
/// </summary>
public class DeleteUnitTypeCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف نوع الوحدة
    /// Unit type identifier
    /// </summary>
    public Guid UnitTypeId { get; set; }
} 