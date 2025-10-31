using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Units.Queries.GetAvailableUnits;

/// <summary>
/// استعلام الحصول على الوحدات المتاحة
/// Query to get available units
/// </summary>
public class GetAvailableUnitsQuery : IRequest<ResultDto<AvailableUnitsResponse>>
{
    /// <summary>
    /// معرف الكيان
    /// </summary>
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// تاريخ الوصول
    /// </summary>
    public DateTime? CheckIn { get; set; }
    
    /// <summary>
    /// تاريخ المغادرة
    /// </summary>
    public DateTime? CheckOut { get; set; }
    
    /// <summary>
    /// عدد الضيوف
    /// </summary>
    public int GuestsCount { get; set; }
}