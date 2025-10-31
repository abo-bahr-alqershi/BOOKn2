using MediatR;
using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Units.Events {
    // أحداث الوحدات
    public class UnitCreatedEvent : INotification
    {
        public Guid UnitId { get; set; }
        public Guid PropertyId { get; set; }
        public string Name { get; set; }
        public decimal BasePrice { get; set; }
        public int MaxCapacity { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}