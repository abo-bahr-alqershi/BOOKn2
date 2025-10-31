using System;
using System.Collections.Generic;
using Bogus;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية لكائن PropertyImage
    /// </summary>
    public class PropertyImageSeeder : ISeeder<PropertyImage>
    {
        public IEnumerable<PropertyImage> SeedData()
        {
            return new Faker<PropertyImage>()
                .RuleFor(img => img.Id, f => Guid.NewGuid())
                .RuleFor(img => img.PropertyId, f => Guid.NewGuid())
                .RuleFor(img => img.UnitId, f => (Guid?)null)
                .RuleFor(img => img.Name, f => f.System.FileName())
                .RuleFor(img => img.Url, f => f.Image.PicsumUrl())
                .RuleFor(img => img.SizeBytes, f => f.Random.Long(10000, 5000000))
                .RuleFor(img => img.Type, f => f.System.FileExt())
                .RuleFor(img => img.Category, f => f.PickRandom<ImageCategory>())
                .RuleFor(img => img.Caption, f => f.Lorem.Sentence())
                .RuleFor(img => img.AltText, f => f.Lorem.Sentence())
                .RuleFor(img => img.Tags, f => "[]")
                .RuleFor(img => img.Sizes, f => "{}")
                .RuleFor(img => img.IsMain, f => f.Random.Bool(0.1f))
                .RuleFor(img => img.SortOrder, f => f.Random.Number(0, 10))
                .RuleFor(img => img.Views, f => f.Random.Number(0, 1000))
                .RuleFor(img => img.Downloads, f => f.Random.Number(0, 500))
                .RuleFor(img => img.UploadedAt, f => DateTime.SpecifyKind(f.Date.Past(1), DateTimeKind.Utc))
                .RuleFor(img => img.DisplayOrder, f => f.Random.Number(0, 10))
                .RuleFor(img => img.Status, f => f.PickRandom<ImageStatus>())
                .RuleFor(img => img.IsMainImage, (f, img) => img.IsMain)
                .RuleFor(img => img.CreatedAt, f => DateTime.SpecifyKind(f.Date.Recent(), DateTimeKind.Utc))
                .RuleFor(img => img.UpdatedAt, f => DateTime.SpecifyKind(f.Date.Recent(), DateTimeKind.Utc))
                .RuleFor(img => img.IsActive, f => true)
                .RuleFor(img => img.IsDeleted, f => false)
                .Generate(50);
        }
    }
} 