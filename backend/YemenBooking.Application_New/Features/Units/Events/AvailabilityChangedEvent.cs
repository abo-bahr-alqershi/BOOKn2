using MediatR;
using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Units.Events {
    // أحداث الإتاحة
    public class AvailabilityChangedEvent : INotification
    {
        public Guid UnitId { get; set; }
        public Guid PropertyId { get; set; }
        public List<(DateTime Start, DateTime End)> AvailableRanges { get; set; } = new();
        public DateTime ChangedAt { get; set; }
    }
}