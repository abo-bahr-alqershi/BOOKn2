using MediatR;
using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Units.Events {
    public class UnitDeletedEvent : INotification
    {
        public Guid UnitId { get; set; }
        public Guid PropertyId { get; set; }
        public DateTime DeletedAt { get; set; }
    }
}