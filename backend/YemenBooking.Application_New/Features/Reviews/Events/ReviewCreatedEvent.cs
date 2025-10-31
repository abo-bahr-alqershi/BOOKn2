using MediatR;
using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Reviews.Events {
    // أحداث المراجعات
    public class ReviewCreatedEvent : INotification
    {
        public Guid ReviewId { get; set; }
        public Guid PropertyId { get; set; }
        public decimal NewAverageRating { get; set; }
        public DateTime CreatedAt { get; set; }
    }

}