using MediatR;
using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Properties.Events
{
    // أحداث العقارات
    public class PropertyDeletedEvent : INotification
    {
        public Guid PropertyId { get; set; }
        public DateTime DeletedAt { get; set; }
    }
}