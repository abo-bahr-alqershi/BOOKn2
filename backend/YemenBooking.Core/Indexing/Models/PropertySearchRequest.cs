using MessagePack;

namespace YemenBooking.Core.Indexing.Models
{
    /// <summary>
    /// طلب البحث في الفهرس
    /// </summary>
    [MessagePackObject]
    public class PropertySearchRequest
    {
        [Key(0)] public string? SearchText { get; set; }
        [Key(1)] public string? City { get; set; }
        [Key(2)] public string? PropertyType { get; set; }
        [Key(3)] public decimal? MinPrice { get; set; }
        [Key(4)] public decimal? MaxPrice { get; set; }
        [Key(5)] public string? PreferredCurrency { get; set; }
        [Key(6)] public decimal? MinRating { get; set; }
        [Key(7)] public DateTime? CheckIn { get; set; }
        [Key(8)] public DateTime? CheckOut { get; set; }
        [Key(9)] public int? GuestsCount { get; set; }
        [Key(10)] public List<string>? RequiredAmenityIds { get; set; }
        [Key(11)] public List<string>? ServiceIds { get; set; }
        [Key(12)] public string? UnitTypeId { get; set; }
        [Key(13)] public Dictionary<string, string>? DynamicFieldFilters { get; set; }
        [Key(14)] public double? Latitude { get; set; }
        [Key(15)] public double? Longitude { get; set; }
        [Key(16)] public int? RadiusKm { get; set; }
        [Key(17)] public string? SortBy { get; set; }
        [Key(18)] public int PageNumber { get; set; } = 1;
        [Key(19)] public int PageSize { get; set; } = 20;
        [Key(20)] public int? MinAdults { get; set; }
        [Key(21)] public int? MinChildren { get; set; }
    }

    /// <summary>
    /// نتيجة البحث في الفهرس
    /// </summary>
    [MessagePackObject]
    public class PropertySearchResult
    {
        [Key(0)] public List<PropertySearchItem> Properties { get; set; } = new();
        [Key(1)] public int TotalCount { get; set; }
        [Key(2)] public int PageNumber { get; set; }
        [Key(3)] public int PageSize { get; set; }
        [Key(4)] public int TotalPages { get; set; }
    }

    /// <summary>
    /// عنصر نتيجة البحث
    /// </summary>
    [MessagePackObject]
    public class PropertySearchItem
    {
        [Key(0)] public string Id { get; set; } = string.Empty;
        [Key(1)] public string Name { get; set; } = string.Empty;
        [Key(2)] public string City { get; set; } = string.Empty;
        [Key(3)] public string PropertyType { get; set; } = string.Empty;
        [Key(4)] public decimal MinPrice { get; set; }
        [Key(5)] public string Currency { get; set; } = "YER";
        [Key(6)] public decimal AverageRating { get; set; }
        [Key(7)] public int StarRating { get; set; }
        [Key(8)] public List<string> ImageUrls { get; set; } = new();
        [Key(9)] public int MaxCapacity { get; set; }
        [Key(10)] public int UnitsCount { get; set; }
        [Key(11)] public Dictionary<string, string> DynamicFields { get; set; } = new();
        [Key(12)] public double Latitude { get; set; }
        [Key(13)] public double Longitude { get; set; }
    }
}