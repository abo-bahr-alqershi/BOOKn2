using MediatR;
using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Properties.Events
{
    public class PropertyUpdatedEvent : INotification
    {
        public Guid PropertyId { get; set; }
        public string Name { get; set; }
        public string City { get; set; }
        public string PropertyType { get; set; }
        public decimal BasePrice { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

}