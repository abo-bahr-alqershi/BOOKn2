using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Amenities.Commands.ManageAmenities;

/// <summary>
/// أمر لحذف مرفق
/// Command to delete an amenity
/// </summary>
public class DeleteAmenityCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف المرفق
    /// Amenity identifier
    /// </summary>
    public Guid AmenityId { get; set; }
} 