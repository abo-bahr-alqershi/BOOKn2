using Microsoft.AspNetCore.Mvc;
using MediatR;
using YemenBooking.Application.Features.Pricing.Commands.BulkOperations;
using YemenBooking.Application.Features.Units.Commands.UpdateUnit;
using YemenBooking.Application.Features.Units.Commands.BulkOperations;
using YemenBooking.Application.Features.Units.Commands.ManageAvailability;
using YemenBooking.Application.Features.Units.Queries.CheckAvailability;
using YemenBooking.Application.Features.Units.Queries.GetUnitAvailability;

namespace YemenBooking.API.Controllers;

[ApiController]
[Route("api/admin/units/{unitId}/availability")]
public class UnitAvailabilityController : ControllerBase
{
    private readonly IMediator _mediator;

    public UnitAvailabilityController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("{year}/{month}")]
    public async Task<IActionResult> GetMonthlyAvailability(Guid unitId, int year, int month)
    {
        var query = new GetUnitAvailabilityQuery
        {
            UnitId = unitId,
            Year = year,
            Month = month
        };

        var result = await _mediator.Send(query);
        
        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> UpdateAvailability(Guid unitId, [FromBody] UpdateUnitAvailabilityCommand command)
    {
        command.UnitId = unitId;
        var result = await _mediator.Send(command);
        
        return Ok(result);
    }

    [HttpPost("bulk")]
    public async Task<IActionResult> BulkUpdateAvailability(Guid unitId, [FromBody] BulkUpdateAvailabilityCommand command)
    {
        command.UnitId = unitId;
        var result = await _mediator.Send(command);
        
        return Ok(result);
    }

    [HttpPost("clone")]
    public async Task<IActionResult> CloneAvailability(Guid unitId, [FromBody] CloneAvailabilityCommand command)
    {
        command.UnitId = unitId;
        var result = await _mediator.Send(command);
        
        return Ok(result);
    }

    [HttpDelete("{startDate}/{endDate}")]
    public async Task<IActionResult> DeleteAvailability(Guid unitId, DateTime startDate, DateTime endDate)
    {
        var command = new DeleteAvailabilityCommand
        {
            UnitId = unitId,
            StartDate = startDate,
            EndDate = endDate
        };

        var result = await _mediator.Send(command);
        
        return Ok(result);
    }

    [HttpGet("check")]
    public async Task<IActionResult> CheckAvailability(Guid unitId, [FromQuery] DateTime checkIn, [FromQuery] DateTime checkOut)
    {
        var query = new CheckAvailabilityQuery
        {
            UnitId = unitId,
            CheckIn = checkIn,
            CheckOut = checkOut
        };

        var result = await _mediator.Send(query);
        
        return Ok(result);
    }
}