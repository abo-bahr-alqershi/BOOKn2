using MediatR;
using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Amenities.Events {
    // أحداث المرافق
    public class AmenitiesChangedEvent : INotification
    {
        public Guid PropertyId { get; set; }
        public List<Guid> AmenityIds { get; set; } = new();
        public DateTime ChangedAt { get; set; }
    }
}