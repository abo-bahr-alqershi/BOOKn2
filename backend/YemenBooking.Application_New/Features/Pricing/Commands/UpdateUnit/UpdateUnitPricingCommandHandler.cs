using MediatR;
using YemenBooking.Application.Features.Pricing;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Pricing.Commands.UpdateUnit;

public class UpdateUnitPricingCommandHandler : IRequestHandler<UpdateUnitPricingCommand, ResultDto>
{
    private readonly IPricingRuleRepository _pricingRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly ICurrentUserService _currentUserService;

    public UpdateUnitPricingCommandHandler(
        IPricingRuleRepository pricingRepository,
        IUnitRepository unitRepository,
        ICurrentUserService currentUserService)
    {
        _pricingRepository = pricingRepository;
        _unitRepository = unitRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto> Handle(UpdateUnitPricingCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // Normalize to local day boundaries (inclusive end) then convert to UTC to avoid off-by-one
            var localStart = new DateTime(request.StartDate.Year, request.StartDate.Month, request.StartDate.Day, 12, 0, 0);
            var localEnd = new DateTime(request.EndDate.Year, request.EndDate.Month, request.EndDate.Day, 23, 59, 59, 999);
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localStart);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localEnd);

            if (endUtc < startUtc)
                return ResultDto.Failure("تاريخ النهاية يجب أن لا يكون قبل تاريخ البداية");

            // Ensure unit exists to avoid FK violations
            var unit = await _unitRepository.GetByIdAsync(request.UnitId, cancellationToken);
            if (unit == null)
                return ResultDto.Failure("الوحدة غير موجودة");

            if (request.OverwriteExisting)
            {
                await _pricingRepository.DeleteRangeAsync(request.UnitId, startUtc, endUtc);
            }

            // Build rule; rely on repository BulkCreateAsync to normalize currency and strings
            var rule = new PricingRule
            {
                Id = Guid.NewGuid(),
                UnitId = request.UnitId,
                PriceType = string.IsNullOrWhiteSpace(request.PriceType) ? "Custom" : request.PriceType.Trim(),
                StartDate = startUtc,
                EndDate = endUtc,
                StartTime = request.StartTime,
                EndTime = request.EndTime,
                PriceAmount = request.Price,
                Currency = (request.Currency ?? unit.BasePrice?.Currency ?? "YER")!,
                PricingTier = string.IsNullOrWhiteSpace(request.PricingTier) ? "1" : request.PricingTier.Trim(),
                PercentageChange = request.PercentageChange,
                MinPrice = request.MinPrice,
                MaxPrice = request.MaxPrice,
                Description = request.Description,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _pricingRepository.BulkCreateAsync(new[] { rule });
            return ResultDto.Ok();
        }
        catch (Exception ex)
        {
            var inner = ex.InnerException?.Message;
            var msg = ex.Message + (inner != null ? $" | Inner: {inner}" : string.Empty);
            return ResultDto.Failure($"حدث خطأ: {msg}");
        }
    }
}