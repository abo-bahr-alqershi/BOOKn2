// RedisIndexModels.cs
using System;
using System.Collections.Generic;
using StackExchange.Redis;
using MessagePack;
using LiteDB;

namespace YemenBooking.Infrastructure.Indexing.Models
{
    /// <summary>
    /// نموذج فهرس العقار محسّن لـ Redis
    /// </summary>
    [MessagePackObject]
    public class PropertyIndexModel
    {
        [Key(0)]
        public string Id { get; set; }

        [Key(1)]
        public string Name { get; set; }

        [Key(2)]
        public string NameLower { get; set; }

        [Key(3)]
        public string Description { get; set; }

        [Key(4)]
        public string City { get; set; }

        [Key(5)]
        public string Address { get; set; }

        [Key(6)]
        public string PropertyType { get; set; }

        [Key(7)]
        public Guid PropertyTypeId { get; set; }

        [Key(8)]
        public Guid OwnerId { get; set; }

        [Key(9)]
        public decimal MinPrice { get; set; }

        [Key(10)]
        public decimal MaxPrice { get; set; }

        [Key(11)]
        public string Currency { get; set; }

        [Key(12)]
        public int StarRating { get; set; }

        [Key(13)]
        public decimal AverageRating { get; set; }

        [Key(14)]
        public int ReviewsCount { get; set; }

        [Key(15)]
        public int ViewCount { get; set; }

        [Key(16)]
        public int BookingCount { get; set; }

        [Key(17)]
        public double Latitude { get; set; }

        [Key(18)]
        public double Longitude { get; set; }

        [Key(19)]
        public int MaxCapacity { get; set; }

        [Key(20)]
        public int UnitsCount { get; set; }

        [Key(21)]
        public bool IsActive { get; set; }

        [Key(22)]
        public bool IsFeatured { get; set; }

        [Key(23)]
        public bool IsApproved { get; set; }

        [Key(24)]
        public List<string> UnitIds { get; set; } = new();

        [Key(25)]
        public List<string> AmenityIds { get; set; } = new();

        [Key(26)]
        public List<string> ServiceIds { get; set; } = new();

        [Key(27)]
        public List<string> ImageUrls { get; set; } = new();

        [Key(28)]
        public Dictionary<string, string> DynamicFields { get; set; } = new();

        [Key(29)]
        public DateTime CreatedAt { get; set; }

        [Key(30)]
        public DateTime UpdatedAt { get; set; }

        [Key(31)]
        public long LastModifiedTicks { get; set; }

        public HashEntry[] ToHashEntries()
        {
            var entries = new List<HashEntry>
            {
                new("id", Id),
                new("name", Name),
                new("name_lower", NameLower),
                new("description", Description ?? ""),
                new("city", City),
                new("address", Address),
                new("property_type", PropertyType),
                new("property_type_id", PropertyTypeId.ToString()),
                new("owner_id", OwnerId.ToString()),
                new("min_price", MinPrice.ToString()),
                new("max_price", MaxPrice.ToString()),
                new("currency", Currency),
                new("star_rating", StarRating),
                new("average_rating", AverageRating.ToString()),
                new("reviews_count", ReviewsCount),
                new("view_count", ViewCount),
                new("booking_count", BookingCount),
                new("latitude", Latitude.ToString()),
                new("longitude", Longitude.ToString()),
                new("max_capacity", MaxCapacity),
                new("units_count", UnitsCount),
                new("is_active", IsActive.ToString()),
                new("is_featured", IsFeatured.ToString()),
                new("is_approved", IsApproved.ToString()),
                new("created_at", CreatedAt.Ticks),
                new("updated_at", UpdatedAt.Ticks),
                new("modified_ticks", LastModifiedTicks)
            };

            return entries.ToArray();
        }

        public static PropertyIndexModel FromHashEntries(HashEntry[] entries)
        {
            var dict = entries.ToDictionary(x => x.Name.ToString(), x => x.Value);

            return new PropertyIndexModel
            {
                Id = dict.GetValueOrDefault("id"),
                Name = dict.GetValueOrDefault("name"),
                NameLower = dict.GetValueOrDefault("name_lower"),
                Description = dict.GetValueOrDefault("description"),
                City = dict.GetValueOrDefault("city"),
                Address = dict.GetValueOrDefault("address"),
                PropertyType = dict.GetValueOrDefault("property_type"),
                PropertyTypeId = Guid.Parse(dict.GetValueOrDefault("property_type_id", Guid.Empty.ToString())),
                OwnerId = Guid.Parse(dict.GetValueOrDefault("owner_id", Guid.Empty.ToString())),
                MinPrice = decimal.Parse(dict.GetValueOrDefault("min_price", "0")),
                MaxPrice = decimal.Parse(dict.GetValueOrDefault("max_price", "0")),
                Currency = dict.GetValueOrDefault("currency"),
                StarRating = int.Parse(dict.GetValueOrDefault("star_rating", "0")),
                AverageRating = decimal.Parse(dict.GetValueOrDefault("average_rating", "0")),
                ReviewsCount = int.Parse(dict.GetValueOrDefault("reviews_count", "0")),
                ViewCount = int.Parse(dict.GetValueOrDefault("view_count", "0")),
                BookingCount = int.Parse(dict.GetValueOrDefault("booking_count", "0")),
                Latitude = double.Parse(dict.GetValueOrDefault("latitude", "0")),
                Longitude = double.Parse(dict.GetValueOrDefault("longitude", "0")),
                MaxCapacity = int.Parse(dict.GetValueOrDefault("max_capacity", "0")),
                UnitsCount = int.Parse(dict.GetValueOrDefault("units_count", "0")),
                IsActive = bool.Parse(dict.GetValueOrDefault("is_active", "false")),
                IsFeatured = bool.Parse(dict.GetValueOrDefault("is_featured", "false")),
                IsApproved = bool.Parse(dict.GetValueOrDefault("is_approved", "false")),
                CreatedAt = new DateTime(long.Parse(dict.GetValueOrDefault("created_at", "0"))),
                UpdatedAt = new DateTime(long.Parse(dict.GetValueOrDefault("updated_at", "0"))),
                LastModifiedTicks = long.Parse(dict.GetValueOrDefault("modified_ticks", "0"))
            };
        }
    }

        /// <summary>
    /// فهرس الإتاحة
    /// </summary>
    public class AvailabilityIndexDocument
    {
        [BsonId]
        public string Id { get; set; }
        public string PropertyId { get; set; }
        public string UnitId { get; set; }
        public List<DateRangeIndex> AvailableRanges { get; set; } = new();
        public DateTime UpdatedAt { get; set; }
    }

    /// <summary>
    /// نطاق تاريخي للإتاحة
    /// </summary>
    public class DateRangeIndex
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }

    /// <summary>
    /// فهرس التسعير الديناميكي
    /// </summary>
    public class PricingIndexDocument
    {
        [BsonId]
        public string Id { get; set; }
        public string PropertyId { get; set; }
        public string UnitId { get; set; }
        public decimal BasePrice { get; set; }
        public string Currency { get; set; }
        public List<PricingRuleIndex> PricingRules { get; set; } = new();
        public DateTime UpdatedAt { get; set; }
    }

    /// <summary>
    /// قاعدة تسعير
    /// </summary>
    public class PricingRuleIndex
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal Price { get; set; }
        public string RuleType { get; set; } // seasonal, weekend, special
    }

    /// <summary>
    /// فهرس الحقول الديناميكية
    /// </summary>
    public class DynamicFieldIndexDocument
    {
        [BsonId]
        public string Id { get; set; }
        public string FieldName { get; set; }
        public string FieldValue { get; set; }
        public List<string> PropertyIds { get; set; } = new();
        public DateTime UpdatedAt { get; set; }
    }

    /// <summary>
    /// فهرس المدن
    /// </summary>
    public class CityIndexDocument
    {
        [BsonId]
        public string City { get; set; }
        public int PropertyCount { get; set; }
        public List<string> PropertyIds { get; set; } = new();
        public DateTime UpdatedAt { get; set; }
    }

    /// <summary>
    /// فهرس المرافق
    /// </summary>
    public class AmenityIndexDocument
    {
        [BsonId]
        public string AmenityId { get; set; }
        public string AmenityName { get; set; }
        public int PropertyCount { get; set; }
        public List<string> PropertyIds { get; set; } = new();
        public DateTime UpdatedAt { get; set; }
    }

}

