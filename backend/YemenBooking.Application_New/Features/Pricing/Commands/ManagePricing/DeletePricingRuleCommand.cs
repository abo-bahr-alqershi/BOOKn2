using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Pricing.Commands.ManagePricing;

public class DeletePricingRuleCommand : IRequest<ResultDto>
{
    public Guid UnitId { get; set; }
    public Guid? PricingRuleId { get; set; } // حذف قاعدة محددة
    public DateTime? StartDate { get; set; } // حذف بالفترة
    public DateTime? EndDate { get; set; }
}
