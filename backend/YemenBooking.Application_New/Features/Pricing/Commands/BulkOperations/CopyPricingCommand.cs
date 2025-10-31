using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Pricing.Commands.BulkOperations;

public class CopyPricingCommand : IRequest<ResultDto>
{
    public Guid UnitId { get; set; }
    public DateTime SourceStartDate { get; set; }
    public DateTime SourceEndDate { get; set; }
    public DateTime TargetStartDate { get; set; }
    public int RepeatCount { get; set; } = 1;
    public string AdjustmentType { get; set; } = "none"; // none, fixed, percentage
    public decimal AdjustmentValue { get; set; } = 0;
    public bool OverwriteExisting { get; set; } = false;
}
