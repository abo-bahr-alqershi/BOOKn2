using System;
using System.Collections.Generic;
using System.Linq;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.ValueObjects;

namespace YemenBooking.Core.Seeds
{
    public class BookingServiceSeeder : ISeeder<BookingService>
    {
        private readonly IEnumerable<Booking> _bookings;
        private readonly IEnumerable<PropertyService> _services;
        private readonly Dictionary<Guid, Guid> _unitToProperty;

        public BookingServiceSeeder(
            IEnumerable<Booking> bookings,
            IEnumerable<PropertyService> services,
            IEnumerable<Unit> units)
        {
            _bookings = bookings;
            _services = services;
            _unitToProperty = units.ToDictionary(u => u.Id, u => u.PropertyId);
        }

        public IEnumerable<BookingService> SeedData()
        {
            var list = new List<BookingService>();
            var rnd = new Random(13579);

            foreach (var b in _bookings.Where(x => x.Status != BookingStatus.Cancelled))
            {
                if (!_unitToProperty.TryGetValue(b.UnitId, out var propertyId))
                    continue;

                var propertyServices = _services.Where(s => s.PropertyId == propertyId).ToList();
                if (!propertyServices.Any())
                    continue;

                var maxAttach = Math.Min(3, propertyServices.Count);
                var attachCount = rnd.Next(1, maxAttach + 1);

                foreach (var svc in propertyServices.OrderBy(_ => rnd.Next()).Take(attachCount))
                {
                    int quantity = 1;
                    switch (svc.PricingModel)
                    {
                        case PricingModel.PerPerson:
                            quantity = Math.Max(1, b.GuestsCount);
                            break;
                        case PricingModel.PerNight:
                            var nights = (b.CheckOut.Date - b.CheckIn.Date).Days;
                            quantity = Math.Max(1, nights);
                            break;
                        default:
                            quantity = 1;
                            break;
                    }

                    var bs = new BookingService
                    {
                        Id = Guid.NewGuid(),
                        BookingId = b.Id,
                        ServiceId = svc.Id,
                        Quantity = quantity,
                        TotalPrice = svc.Price * quantity,
                        CreatedAt = b.BookedAt.AddMinutes(rnd.Next(1, 120)),
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        IsDeleted = false
                    };

                    list.Add(bs);
                }
            }

            return list;
        }
    }
}
