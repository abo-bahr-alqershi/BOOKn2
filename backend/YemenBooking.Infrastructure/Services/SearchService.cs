using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Features.Units.Services;
using System.Linq;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة البحث
    /// Search service implementation
    /// </summary>
    public class SearchService : ISearchService
    {
        private readonly ILogger<SearchService> _logger;
        private readonly IUserRepository _userRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IAvailabilityService _availabilityService;

        public SearchService(
            ILogger<SearchService> logger,
            IUserRepository userRepository,
            IPropertyRepository propertyRepository,
            IAvailabilityService availabilityService)
        {
            _logger = logger;
            _userRepository = userRepository;
            _propertyRepository = propertyRepository;
            _availabilityService = availabilityService;
        }

        public Task<IEnumerable<User>> SearchUsersAsync(string searchTerm, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("البحث عن المستخدمين باستخدام: {SearchTerm}", searchTerm);
            return _userRepository.SearchUsersAsync(searchTerm, cancellationToken);
        }

        public async Task<IEnumerable<Property>> SearchPropertiesAsync(
            string searchTerm,
            DateTime? checkIn = null,
            DateTime? checkOut = null,
            int? guestCount = null,
            Guid? propertyTypeId = null,
            decimal? minPrice = null,
            decimal? maxPrice = null,
            string? city = null,
            double? latitude = null,
            double? longitude = null,
            double? radiusKm = null,
            CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("البحث عن الكيانات باستخدام: {SearchTerm}", searchTerm);
            IEnumerable<Property> properties;
            if (latitude.HasValue && longitude.HasValue && radiusKm.HasValue)
            {
                properties = await _propertyRepository.GetPropertiesNearLocationAsync(latitude.Value, longitude.Value, radiusKm.Value, cancellationToken);
            }
            else
            {
                properties = await _propertyRepository.SearchPropertiesAsync(searchTerm, cancellationToken);
            }
            if (!string.IsNullOrEmpty(city))
                properties = properties.Where(p => p.City.Equals(city, StringComparison.OrdinalIgnoreCase));
            if (propertyTypeId.HasValue)
                properties = properties.Where(p => p.TypeId == propertyTypeId.Value);
            // Filter by availability
            if (checkIn.HasValue && checkOut.HasValue)
            {
                var results = new List<Property>();
                foreach (var prop in properties)
                {
                    var availableUnits = await _availabilityService.GetAvailableUnitsInPropertyAsync(prop.Id, checkIn.Value, checkOut.Value, guestCount ?? 1, cancellationToken);
                    if (availableUnits.Any())
                        results.Add(prop);
                }
                properties = results;
            }
            // Price filtering
            if (minPrice.HasValue || maxPrice.HasValue)
            {
                properties = properties.Where(p => p.Units.Any(u =>
                    (!minPrice.HasValue || u.BasePrice.Amount >= minPrice.Value) &&
                    (!maxPrice.HasValue || u.BasePrice.Amount <= maxPrice.Value)));
            }
            return properties;
        }

        public async Task<IEnumerable<object>> GetPopularDestinationsAsync(int count, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على الوجهات الشائعة بحد أقصى: {Count}", count);
            var props = await _propertyRepository.GetPopularDestinationsAsync(count, cancellationToken);
            return props.Select(p => new { p.City, p.ViewCount }).Take(count);
        }

        public async Task<decimal> CalculatePopularityAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("حساب الشعبية للكيان: {PropertyId}", propertyId);
            var prop = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
            return prop != null && prop.BookingCount + prop.ViewCount > 0
                ? (decimal)prop.BookingCount / (prop.BookingCount + prop.ViewCount)
                : 0m;
        }

        public async Task<(IEnumerable<Property> PropertyDto, int TotalCount)> AdvancedSearchAsync(
            Dictionary<string, object> searchCriteria,
            int page = 1,
            int pageSize = 20,
            string? sortBy = null,
            bool sortDescending = false,
            CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("البحث المتقدم باستخدام معايير: {@Criteria}", searchCriteria);
            // TODO: بناء استعلام ديناميكي بناءً على المعايير
            var properties = await _propertyRepository.GetPropertiesByOwnerAsync(Guid.Empty, cancellationToken);
            var propertyList = properties as IList<Property> ?? properties.ToList();
            return (PropertyDto: propertyList, TotalCount: propertyList.Count);
        }

        public Task<IEnumerable<string>> GetSearchSuggestionsAsync(
            string partialTerm,
            string searchType = "property",
            int maxSuggestions = 10,
            CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على اقتراحات البحث: {PartialTerm} من النوع {Type}", partialTerm, searchType);
            if (searchType.Equals("user", StringComparison.OrdinalIgnoreCase))
                return _userRepository.SearchUsersAsync(partialTerm, cancellationToken)
                    .ContinueWith(t => t.Result.Select(u => u.Name).Take(maxSuggestions), cancellationToken);
            return _propertyRepository.SearchPropertiesAsync(partialTerm, cancellationToken)
                .ContinueWith(t => t.Result.Select(p => p.Name).Take(maxSuggestions), cancellationToken);
        }

        public Task<bool> IndexDataAsync(string entityType, object data, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("فهرسة البيانات للنوع: {EntityType}", entityType);
            // TODO: دمج مع محرك بحث خارجي مثل Elasticsearch
            return Task.FromResult(true);
        }

        public Task<bool> RebuildSearchIndexAsync(string? entityType = null, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("إعادة بناء فهرس البحث للنوع: {EntityType}", entityType);
            // TODO: دمج مع محرك بحث خارجي لإعادة فهرسة كاملة
            return Task.FromResult(true);
        }
    }
} 