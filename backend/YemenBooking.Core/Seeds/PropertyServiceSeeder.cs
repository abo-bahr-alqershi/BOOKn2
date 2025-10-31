using System;
using System.Collections.Generic;
using System.Linq;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.ValueObjects;

namespace YemenBooking.Core.Seeds
{
    public class PropertyServiceSeeder : ISeeder<PropertyService>
    {
        private readonly IEnumerable<Property> _properties;
        public PropertyServiceSeeder(IEnumerable<Property> properties)
        {
            _properties = properties;
        }

        public IEnumerable<PropertyService> SeedData()
        {
            var list = new List<PropertyService>();
            var rnd = new Random(24680);

            var templates = new (string Name, PricingModel Model, decimal YerPrice, decimal UsdPrice, string Icon)[]
            {
                ("خدمة توصيل من وإلى المطار", PricingModel.Fixed, 15000m, 15m, "airport_shuttle"),
                ("إفطار", PricingModel.PerPerson, 2500m, 3m, "breakfast"),
                ("تنظيف إضافي", PricingModel.PerNight, 4000m, 4m, "cleaning_services"),
                ("غسيل ملابس", PricingModel.PerPerson, 1500m, 2m, "local_laundry_service"),
                ("نقل داخلي", PricingModel.Fixed, 8000m, 8m, "directions_bus"),
            };

            foreach (var p in _properties)
            {
                var currency = string.IsNullOrWhiteSpace(p.Currency) ? "YER" : p.Currency.ToUpperInvariant();
                var count = rnd.Next(3, templates.Length + 1);
                var selected = templates.OrderBy(_ => rnd.Next()).Take(count).ToList();
                foreach (var t in selected)
                {
                    var amount = currency == "USD" ? t.UsdPrice : t.YerPrice;
                    list.Add(new PropertyService
                    {
                        Id = Guid.NewGuid(),
                        PropertyId = p.Id,
                        Name = t.Name,
                        Description = null,
                        Icon = t.Icon,
                        PricingModel = t.Model,
                        Price = new Money(amount, currency),
                        CreatedAt = DateTime.UtcNow.AddDays(-rnd.Next(10, 60)),
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        IsDeleted = false
                    });
                }
            }

            return list;
        }
    }
}
