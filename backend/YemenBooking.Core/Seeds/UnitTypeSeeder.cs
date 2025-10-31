using System;
using System.Collections.Generic;
using Bogus;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية لكائن UnitType
    /// </summary>
    public class UnitTypeSeeder : ISeeder<UnitType>
    {
        public IEnumerable<UnitType> SeedData()
        {
            return new Faker<UnitType>()
                .RuleFor(ut => ut.Id, f => Guid.NewGuid())
                .RuleFor(ut => ut.Description, f => f.Lorem.Sentence())
                .RuleFor(ut => ut.DefaultPricingRules, f => "[]")
                .RuleFor(ut => ut.PropertyTypeId, f => Guid.NewGuid())
                .RuleFor(ut => ut.Name, f => f.Commerce.Product())
                .RuleFor(ut => ut.MaxCapacity, f => f.Random.Number(1, 10))
                .Generate(10);
        }
    }
} 