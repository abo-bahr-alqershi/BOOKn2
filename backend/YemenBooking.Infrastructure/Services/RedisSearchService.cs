// RedisSearchService.cs
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using MessagePack;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Infrastructure.Indexing.Models;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Services
{
    public class RedisSearchService
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly ILogger<RedisSearchService> _logger;
        private readonly IDatabase _db;

        public RedisSearchService(
            IRedisConnectionManager redisManager,
            ILogger<RedisSearchService> logger)
        {
            _redisManager = redisManager;
            _logger = logger;
            _db = _redisManager.GetDatabase();
        }

        public async Task<PropertySearchResult> SearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                // محاولة استخدام RediSearch إذا كان متاحاً
                if (await IsRediSearchAvailable())
                {
                    return await SearchWithRediSearchAsync(request, cancellationToken);
                }

                // استخدام البحث اليدوي
                return await ManualSearchAsync(request, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في البحث");
                throw;
            }
        }

        private async Task<bool> IsRediSearchAvailable()
        {
            try
            {
                await _db.ExecuteAsync("FT.INFO", "idx:properties");
                return true;
            }
            catch
            {
                return false;
            }
        }

        private async Task<PropertySearchResult> SearchWithRediSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var query = BuildRediSearchQuery(request);
            var offset = (request.PageNumber - 1) * request.PageSize;
            
            var searchCommand = $@"
                FT.SEARCH idx:properties 
                ""{query}""
                LIMIT {offset} {request.PageSize}
                {GetSortByClause(request.SortBy)}
            ";

            var result = await _db.ExecuteAsync(searchCommand);
            
            // تحليل النتائج وإرجاعها
            return ParseRediSearchResults(result, request);
        }

        private async Task<PropertySearchResult> ManualSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var propertyIds = new HashSet<string>();
            
            // البدء بجميع العقارات المعتمدة
            var allProperties = await GetApprovedProperties();
            propertyIds = new HashSet<string>(allProperties);

            // تطبيق الفلاتر
            if (!string.IsNullOrWhiteSpace(request.City))
            {
                var cityProperties = await _db.SetMembersAsync($"city:{request.City}");
                propertyIds.IntersectWith(cityProperties.Select(x => x.ToString()));
            }

            if (!string.IsNullOrWhiteSpace(request.PropertyType))
            {
                var typeProperties = await _db.SetMembersAsync($"type:{request.PropertyType}");
                propertyIds.IntersectWith(typeProperties.Select(x => x.ToString()));
            }

            if (request.RequiredAmenityIds?.Any() == true)
            {
                foreach (var amenityId in request.RequiredAmenityIds)
                {
                    var amenityProperties = await _db.SetMembersAsync($"amenity:{amenityId}");
                    propertyIds.IntersectWith(amenityProperties.Select(x => x.ToString()));
                }
            }

            if (request.ServiceIds?.Any() == true)
            {
                foreach (var serviceId in request.ServiceIds)
                {
                    var serviceProperties = await _db.SetMembersAsync($"service:{serviceId}");
                    propertyIds.IntersectWith(serviceProperties.Select(x => x.ToString()));
                }
            }

            // جلب التفاصيل وتطبيق الفلاتر المتقدمة
            var properties = new List<PropertyIndexModel>();
            
            foreach (var propertyId in propertyIds)
            {
                var property = await GetPropertyDetails(propertyId);
                if (property == null) continue;

                // فلترة النص
                if (!string.IsNullOrWhiteSpace(request.SearchText))
                {
                    var searchLower = request.SearchText.ToLower();
                    if (!property.NameLower.Contains(searchLower) &&
                        !property.Description.ToLower().Contains(searchLower) &&
                        !property.Address.ToLower().Contains(searchLower))
                    {
                        continue;
                    }
                }

                // فلترة السعر
                if (request.MinPrice.HasValue && property.MinPrice < request.MinPrice.Value)
                    continue;
                    
                if (request.MaxPrice.HasValue && property.MinPrice > request.MaxPrice.Value)
                    continue;

                // فلترة التقييم
                if (request.MinRating.HasValue && property.AverageRating < request.MinRating.Value)
                    continue;

                // فلترة السعة
                if (request.GuestsCount.HasValue && property.MaxCapacity < request.GuestsCount.Value)
                    continue;

                // فلترة الإتاحة
                if (request.CheckIn.HasValue && request.CheckOut.HasValue)
                {
                    var isAvailable = await CheckAvailability(propertyId, 
                        request.CheckIn.Value, request.CheckOut.Value);
                    if (!isAvailable) continue;
                }

                // فلترة الحقول الديناميكية
                if (request.DynamicFieldFilters?.Any() == true)
                {
                    bool matchAllDynamicFields = true;
                    foreach (var filter in request.DynamicFieldFilters)
                    {
                        if (!property.DynamicFields.ContainsKey(filter.Key) ||
                            property.DynamicFields[filter.Key] != filter.Value)
                        {
                            matchAllDynamicFields = false;
                            break;
                        }
                    }
                    if (!matchAllDynamicFields) continue;
                }

                // البحث الجغرافي
                if (request.Latitude.HasValue && request.Longitude.HasValue)
                {
                    var distance = CalculateDistance(
                        request.Latitude.Value, request.Longitude.Value,
                        property.Latitude, property.Longitude);
                    
                    var radiusKm = request.RadiusKm ?? 50;
                    if (distance > radiusKm) continue;
                }

                properties.Add(property);
            }

            // الترتيب
            properties = ApplySorting(properties, request.SortBy, request.Latitude, request.Longitude);

            // التصفح
            var totalCount = properties.Count;
            var pagedProperties = properties
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToList();

            return new PropertySearchResult
            {
                Properties = pagedProperties.Select(p => new PropertySearchItem
                {
                    Id = p.Id,
                    Name = p.Name,
                    City = p.City,
                    PropertyType = p.PropertyType,
                    MinPrice = p.MinPrice,
                    Currency = p.Currency,
                    AverageRating = p.AverageRating,
                    StarRating = p.StarRating,
                    ImageUrls = p.ImageUrls,
                    MaxCapacity = p.MaxCapacity,
                    UnitsCount = p.UnitsCount,
                    DynamicFields = p.DynamicFields,
                    Latitude = p.Latitude,
                    Longitude = p.Longitude
                }).ToList(),
                TotalCount = totalCount,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalPages = (int)Math.Ceiling((double)totalCount / request.PageSize)
            };
        }

        private async Task<List<string>> GetApprovedProperties()
        {
            var allPropertyIds = await _db.SetMembersAsync("properties:all");
            var approvedProperties = new List<string>();

            foreach (var propertyId in allPropertyIds)
            {
                var isApproved = await _db.HashGetAsync($"property:{propertyId}", "is_approved");
                if (isApproved == "True")
                {
                    approvedProperties.Add(propertyId.ToString());
                }
            }

            return approvedProperties;
        }

        private async Task<PropertyIndexModel> GetPropertyDetails(string propertyId)
        {
            // محاولة جلب البيانات المسلسلة أولاً (أسرع)
            var serializedData = await _db.StringGetAsync($"property:{propertyId}:bin");
            
            if (!serializedData.IsNullOrEmpty)
            {
                return MessagePackSerializer.Deserialize<PropertyIndexModel>(serializedData);
            }

            // جلب من Hash
            var hashData = await _db.HashGetAllAsync($"property:{propertyId}");
            
            if (hashData.Length > 0)
            {
                var model = PropertyIndexModel.FromHashEntries(hashData);
                
                // جلب القوائم المرتبطة
                model.UnitIds = (await _db.SetMembersAsync($"property:units:{propertyId}"))
                    .Select(x => x.ToString()).ToList();
                
                // جلب الحقول الديناميكية
                var dynamicFields = hashData
                    .Where(x => x.Name.ToString().StartsWith("df_"))
                    .ToDictionary(
                        x => x.Name.ToString().Substring(3),
                        x => x.Value.ToString());
                
                model.DynamicFields = dynamicFields;
                
                return model;
            }

            return null;
        }

        private async Task<bool> CheckAvailability(string propertyId, DateTime checkIn, DateTime checkOut)
        {
            var unitIds = await _db.SetMembersAsync($"property:units:{propertyId}");
            
            foreach (var unitId in unitIds)
            {
                var availabilityKey = $"availability:{unitId}";
                var ranges = await _db.SortedSetRangeByScoreAsync(
                    availabilityKey,
                    0,
                    checkOut.Ticks);

                foreach (var range in ranges)
                {
                    var parts = range.ToString().Split(':');
                    if (parts.Length == 2)
                    {
                        var start = new DateTime(long.Parse(parts[0]));
                        var end = new DateTime(long.Parse(parts[1]));
                        
                        if (start <= checkIn && end >= checkOut)
                        {
                            return true; // وجدنا وحدة متاحة
                        }
                    }
                }
            }

            return false;
        }

        private List<PropertyIndexModel> ApplySorting(
            List<PropertyIndexModel> properties,
            string? sortBy,
            double? lat,
            double? lon)
        {
            return sortBy?.ToLower() switch
            {
                "price_asc" => properties.OrderBy(p => p.MinPrice).ToList(),
                "price_desc" => properties.OrderByDescending(p => p.MinPrice).ToList(),
                "rating" => properties.OrderByDescending(p => p.AverageRating)
                    .ThenByDescending(p => p.ReviewsCount).ToList(),
                "newest" => properties.OrderByDescending(p => p.CreatedAt).ToList(),
                "popularity" => properties.OrderByDescending(p => p.BookingCount)
                    .ThenByDescending(p => p.ViewCount).ToList(),
                "distance" => (lat.HasValue && lon.HasValue)
                    ? properties.OrderBy(p => CalculateDistance(lat.Value, lon.Value, p.Latitude, p.Longitude))
                        .ToList()
                    : properties,
                _ => properties.OrderByDescending(p => p.AverageRating)
                    .ThenByDescending(p => p.ReviewsCount).ToList()
            };
        }

        private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371; // كيلومتر
            var dLat = ToRadians(lat2 - lat1);
            var dLon = ToRadians(lon2 - lon1);
            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            return R * c;
        }

        private double ToRadians(double degrees) => degrees * Math.PI / 180;

        private string BuildRediSearchQuery(PropertySearchRequest request)
        {
            var queryParts = new List<string>();

            if (!string.IsNullOrWhiteSpace(request.SearchText))
            {
                queryParts.Add($"(@name:{request.SearchText}* | @description:{request.SearchText}*)");
            }

            if (!string.IsNullOrWhiteSpace(request.City))
            {
                queryParts.Add($"@city:{{{request.City}}}");
            }

            if (!string.IsNullOrWhiteSpace(request.PropertyType))
            {
                queryParts.Add($"@property_type:{{{request.PropertyType}}}");
            }

            if (request.MinPrice.HasValue || request.MaxPrice.HasValue)
            {
                var min = request.MinPrice ?? 0;
                var max = request.MaxPrice ?? decimal.MaxValue;
                queryParts.Add($"@min_price:[{min} {max}]");
            }

            if (request.MinRating.HasValue)
            {
                queryParts.Add($"@average_rating:[{request.MinRating.Value} inf]");
            }

            if (request.GuestsCount.HasValue)
            {
                queryParts.Add($"@max_capacity:[{request.GuestsCount.Value} inf]");
            }

            queryParts.Add("@is_approved:{True}");

            return queryParts.Any() ? string.Join(" ", queryParts) : "*";
        }

        private string GetSortByClause(string? sortBy)
        {
            return sortBy?.ToLower() switch
            {
                "price_asc" => "SORTBY min_price ASC",
                "price_desc" => "SORTBY min_price DESC",
                "rating" => "SORTBY average_rating DESC",
                "newest" => "SORTBY created_at DESC",
                "popularity" => "SORTBY booking_count DESC",
                _ => "SORTBY average_rating DESC"
            };
        }

        private PropertySearchResult ParseRediSearchResults(RedisResult result, PropertySearchRequest request)
        {
            // تحليل نتائج RediSearch
            // هذا يعتمد على تنسيق الإخراج الفعلي لـ RediSearch
            var properties = new List<PropertySearchItem>();
            
            // كود تحليل النتائج هنا...
            
            return new PropertySearchResult
            {
                Properties = properties,
                TotalCount = properties.Count,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalPages = (int)Math.Ceiling((double)properties.Count / request.PageSize)
            };
        }
    }
}