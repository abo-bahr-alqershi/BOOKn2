namespace YemenBooking.Core.Indexing.Models
{
    /// <summary>
    /// طلب البحث في الفهرس
    /// </summary>
    public class PropertySearchRequest
    {
        public string? SearchText { get; set; }
        public string? City { get; set; }
        public string? PropertyType { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string? PreferredCurrency { get; set; }
        public decimal? MinRating { get; set; }
        public DateTime? CheckIn { get; set; }
        public DateTime? CheckOut { get; set; }
        public int? GuestsCount { get; set; }
        public List<string>? RequiredAmenityIds { get; set; }
        public List<string>? ServiceIds { get; set; }
        public string? UnitTypeId { get; set; }
        public Dictionary<string, string>? DynamicFieldFilters { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public int? RadiusKm { get; set; }
        public string? SortBy { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }

    /// <summary>
    /// نتيجة البحث في الفهرس
    /// </summary>
    public class PropertySearchResult
    {
        public List<PropertySearchItem> Properties { get; set; } = new();
        public int TotalCount { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public int TotalPages { get; set; }
    }

    /// <summary>
    /// عنصر نتيجة البحث
    /// </summary>
    public class PropertySearchItem
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string City { get; set; }
        public string PropertyType { get; set; }
        public decimal MinPrice { get; set; }
        public string Currency { get; set; }
        public decimal AverageRating { get; set; }
        public int StarRating { get; set; }
        public List<string> ImageUrls { get; set; } = new();
        public int MaxCapacity { get; set; }
        public int UnitsCount { get; set; }
        public Dictionary<string, string> DynamicFields { get; set; } = new();
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}