using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Analytics.Services;

namespace YemenBooking.Api.Controllers.Client
{
    public class AnalyticsController : BaseClientController
    {
        private readonly IAnalyticsTrackerService _analytics;

        public AnalyticsController(IMediator mediator, IAnalyticsTrackerService analytics)
            : base(mediator)
        {
            _analytics = analytics;
        }

        [HttpPost("section-impression")]
        [AllowAnonymous]
        public async Task<IActionResult> RecordSectionImpression([FromBody] SectionImpressionRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.SectionId))
                return BadRequest(new { success = false, message = "sectionId is required" });

            var props = new Dictionary<string, string>
            {
                ["sectionId"] = request.SectionId,
                ["timestamp"] = DateTime.UtcNow.ToString("o")
            };
            await _analytics.TrackEventAsync("section_impression", props);
            return NoContent();
        }

        [HttpPost("section-interaction")]
        [AllowAnonymous]
        public async Task<IActionResult> RecordSectionInteraction([FromBody] SectionInteractionRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.SectionId) || string.IsNullOrWhiteSpace(request.InteractionType))
                return BadRequest(new { success = false, message = "sectionId and interactionType are required" });

            var props = new Dictionary<string, string>
            {
                ["sectionId"] = request.SectionId,
                ["interactionType"] = request.InteractionType,
                ["timestamp"] = DateTime.UtcNow.ToString("o")
            };
            if (!string.IsNullOrWhiteSpace(request.ItemId))
                props["itemId"] = request.ItemId!;
            if (request.Metadata != null)
            {
                foreach (var kv in request.Metadata)
                {
                    var key = kv.Key?.ToString();
                    if (string.IsNullOrWhiteSpace(key)) continue;
                    var value = kv.Value?.ToString() ?? string.Empty;
                    // Prefix to avoid collisions with reserved keys
                    props[$"meta_{key}"] = value;
                }
            }

            await _analytics.TrackEventAsync("section_interaction", props);
            return NoContent();
        }

        public class SectionImpressionRequest
        {
            public string SectionId { get; set; } = string.Empty;
        }

        public class SectionInteractionRequest
        {
            public string SectionId { get; set; } = string.Empty;
            public string InteractionType { get; set; } = string.Empty;
            public string? ItemId { get; set; }
            public Dictionary<string, object>? Metadata { get; set; }
        }
    }
}
