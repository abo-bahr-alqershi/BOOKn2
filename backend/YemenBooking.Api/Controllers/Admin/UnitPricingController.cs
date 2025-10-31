using Microsoft.AspNetCore.Mvc;
using MediatR;
using YemenBooking.Application.Features.Pricing.Commands.ManagePricing;
using YemenBooking.Application.Features.Pricing.Commands.BulkOperations;
using YemenBooking.Application.Features.Pricing.Commands.SeasonalPricing;
using YemenBooking.Application.Features.Pricing.Commands.UpdateUnit;
using YemenBooking.Application.Features.Pricing.Queries.GetSeasonalPricing;
using YemenBooking.Application.Features.Pricing.Queries.GetUnitPricing;

namespace YemenBooking.API.Controllers;

[ApiController]
[Route("api/admin/units/{unitId}/pricing")]
public class UnitPricingController : ControllerBase
{
    private readonly IMediator _mediator;

    public UnitPricingController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("{year}/{month}")]
    public async Task<IActionResult> GetMonthlyPricing(Guid unitId, int year, int month)
    {
        var query = new GetUnitPricingQuery
        {
            UnitId = unitId,
            Year = year,
            Month = month
        };

        var result = await _mediator.Send(query);
        
        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> UpdatePricing(Guid unitId, [FromBody] UpdateUnitPricingCommand command)
    {
        command.UnitId = unitId;
// تكملة UnitPricingController.cs
        var result = await _mediator.Send(command);
        
        return Ok(result);
    }

    [HttpPost("bulk")]
    public async Task<IActionResult> BulkUpdatePricing(Guid unitId, [FromBody] BulkUpdatePricingCommand command)
    {
        command.UnitId = unitId;
        var result = await _mediator.Send(command);

        return Ok(result);
    }

    [HttpPost("copy")]
    public async Task<IActionResult> CopyPricing(Guid unitId, [FromBody] CopyPricingCommand command)
    {
        command.UnitId = unitId;
        var result = await _mediator.Send(command);
        
        return Ok(result);
    }

    [HttpDelete("{pricingId}")]
    public async Task<IActionResult> DeletePricing(Guid unitId, Guid pricingId)
    {
        var command = new DeletePricingRuleCommand
        {
            UnitId = unitId,
            PricingRuleId = pricingId
        };

        var result = await _mediator.Send(command);
        
        if (!result.IsSuccess)
            return BadRequest(result.Errors);
            
        return NoContent();
    }

    [HttpGet("templates")]
    public async Task<IActionResult> GetPricingTemplates(Guid unitId)
    {
        var query = new GetSeasonalPricingQuery { UnitId = unitId };
        var result = await _mediator.Send(query);
        
        if (!result.IsSuccess)
            return BadRequest(result.Errors);
            
        return Ok(result.Data);
    }

    [HttpPost("apply-template")]
    public async Task<IActionResult> ApplyTemplate(Guid unitId, [FromBody] ApplySeasonalPricingCommand command)
    {
        command.UnitId = unitId;
        var result = await _mediator.Send(command);
        
        return Ok(result);
    }
}