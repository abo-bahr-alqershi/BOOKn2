using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Units.Commands.DeleteUnit;

/// <summary>
/// أمر لحذف الوحدة
/// Command to delete a unit
/// </summary>
public class DeleteUnitCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid UnitId { get; set; }
} 