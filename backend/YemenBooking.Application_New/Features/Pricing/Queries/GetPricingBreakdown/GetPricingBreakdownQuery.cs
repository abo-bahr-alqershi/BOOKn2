using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Pricing.Queries.GetPricingBreakdown;

public class GetPricingBreakdownQuery : IRequest<ResultDto<PricingBreakdownDto>>
{
    public Guid UnitId { get; set; }
    public DateTime CheckIn { get; set; }
    public DateTime CheckOut { get; set; }
}

public class PricingBreakdownDto
{
    public DateTime CheckIn { get; set; }
    public DateTime CheckOut { get; set; }
    public string Currency { get; set; }
    public List<DayPriceDto> Days { get; set; }
    public int TotalNights { get; set; }
    public decimal SubTotal { get; set; }
    public decimal? Discount { get; set; }
    public decimal? Taxes { get; set; }
    public decimal Total { get; set; }
}

public class DayPriceDto
{
    public DateTime Date { get; set; }
    public decimal Price { get; set; }
    public string PriceType { get; set; }
    public string? Description { get; set; }
}
