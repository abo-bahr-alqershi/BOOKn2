using MediatR;
using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Units.Events {

    public class UnitUpdatedEvent : INotification
    {
        public Guid UnitId { get; set; }
        public Guid PropertyId { get; set; }
        public string Name { get; set; }
        public decimal BasePrice { get; set; }
        public int MaxCapacity { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}