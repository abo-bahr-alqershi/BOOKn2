using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.Commands.DeleteProperty;

/// <summary>
/// أمر لحذف الكيان
/// Command to delete a property
/// </summary>
public class DeletePropertyCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الكيان
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }
} 