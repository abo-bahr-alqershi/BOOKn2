using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Pricing;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Pricing.Commands.ManagePricing;


public class DeletePricingRuleCommandHandler : IRequestHandler<DeletePricingRuleCommand, ResultDto>
{
    private readonly IPricingRuleRepository _pricingRepository;
    private readonly ILogger<DeletePricingRuleCommandHandler> _logger;
    private readonly ICurrentUserService _currentUserService;

    public DeletePricingRuleCommandHandler(
        IPricingRuleRepository pricingRepository,
        ILogger<DeletePricingRuleCommandHandler> logger,
        ICurrentUserService currentUserService)
    {
        _pricingRepository = pricingRepository;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto> Handle(DeletePricingRuleCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // حذف قاعدة محددة بالمعرف
            if (request.PricingRuleId.HasValue)
            {
                var rule = await _pricingRepository.GetByIdAsync(request.PricingRuleId.Value);
                if (rule == null)
                    return ResultDto.Failure("قاعدة التسعير غير موجودة");

                if (rule.UnitId != request.UnitId)
                    return ResultDto.Failure("قاعدة التسعير لا تنتمي للوحدة المحددة");

                rule.IsDeleted = true;
                rule.DeletedAt = DateTime.UtcNow;
                rule.DeletedBy = Guid.Empty; // يجب تعيينه من السياق

                await _pricingRepository.UpdateAsync(rule);
                await _pricingRepository.SaveChangesAsync(cancellationToken);

                _logger.LogInformation($"تم حذف قاعدة التسعير {request.PricingRuleId} للوحدة {request.UnitId}");
                
                return ResultDto.Ok("تم حذف قاعدة التسعير بنجاح");
            }

            // حذف بالفترة الزمنية
            if (request.StartDate.HasValue && request.EndDate.HasValue)
            {
                if (request.StartDate.Value >= request.EndDate.Value)
                    return ResultDto.Failure("تاريخ البداية يجب أن يكون قبل تاريخ النهاية");

                var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.StartDate.Value);
                var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.EndDate.Value);

                await _pricingRepository.DeleteRangeAsync(
                    request.UnitId,
                    startUtc,
                    endUtc);

                _logger.LogInformation($"تم حذف قواعد التسعير للوحدة {request.UnitId} من {request.StartDate:yyyy-MM-dd} إلى {request.EndDate:yyyy-MM-dd}");
                
                return ResultDto.Ok($"تم حذف قواعد التسعير في الفترة المحددة");
            }

            return ResultDto.Failure("يجب تحديد معرف القاعدة أو الفترة الزمنية للحذف");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"خطأ في حذف قواعد التسعير للوحدة {request.UnitId}");
            return ResultDto.Failure($"حدث خطأ: {ex.Message}");
        }
    }
}