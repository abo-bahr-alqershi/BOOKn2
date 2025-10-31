using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.PropertyTypes.Commands.DeleteProperty;

/// <summary>
/// أمر لحذف نوع الكيان
/// Command to delete a property type
/// </summary>
public class DeletePropertyTypeCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف نوع الكيان
    /// Property type identifier
    /// </summary>
    public Guid PropertyTypeId { get; set; }
} 