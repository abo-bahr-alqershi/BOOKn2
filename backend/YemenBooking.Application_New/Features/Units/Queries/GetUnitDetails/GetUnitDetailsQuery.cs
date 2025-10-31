using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Units.Queries.GetUnitDetails;

/// <summary>
/// استعلام الحصول على تفاصيل الوحدة
/// Query to get unit details
/// </summary>
public class GetUnitDetailsQuery : IRequest<ResultDto<UnitDetailsDto>>
{
    /// <summary>
    /// معرف الوحدة
    /// </summary>
    public Guid UnitId { get; set; }
    
    /// <summary>
    /// تاريخ الوصول (لحساب السعر)
    /// </summary>
    public DateTime? CheckIn { get; set; }
    
    /// <summary>
    /// تاريخ المغادرة (لحساب السعر)
    /// </summary>
    public DateTime? CheckOut { get; set; }
}