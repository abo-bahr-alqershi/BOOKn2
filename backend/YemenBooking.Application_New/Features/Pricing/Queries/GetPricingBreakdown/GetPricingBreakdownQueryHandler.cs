using MediatR;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Pricing.Services;

namespace YemenBooking.Application.Features.Pricing.Queries.GetPricingBreakdown;

public class GetPricingBreakdownQueryHandler : IRequestHandler<GetPricingBreakdownQuery, ResultDto<PricingBreakdownDto>>
{
    private readonly IPricingService _pricingService;
    private readonly ICurrentUserService _currentUserService;

    public GetPricingBreakdownQueryHandler(IPricingService pricingService, ICurrentUserService currentUserService)
    {
        _pricingService = pricingService;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto<PricingBreakdownDto>> Handle(GetPricingBreakdownQuery request, CancellationToken cancellationToken)
    {
        try
        {
            // Normalize incoming dates (local -> UTC) before pricing
            var checkInUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckIn);
            var checkOutUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckOut);

            var breakdown = await _pricingService.GetPricingBreakdownAsync(
                request.UnitId,
                checkInUtc,
                checkOutUtc);

            return ResultDto<PricingBreakdownDto>.Ok(breakdown);
        }
        catch (Exception ex)
        {
            return ResultDto<PricingBreakdownDto>.Failure($"حدث خطأ: {ex.Message}");
        }
    }
}