using MediatR;
using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Pricing.Events {
    // أحداث التسعير
    public class PricingRuleChangedEvent : INotification
    {
        public Guid UnitId { get; set; }
        public Guid PropertyId { get; set; }
        public List<PricingRule> PricingRules { get; set; } = new();
        public DateTime ChangedAt { get; set; }
    }
}