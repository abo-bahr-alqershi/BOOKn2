using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Indexing.Models;
using System;
using System.Threading.Tasks;
using System.Linq;

namespace YemenBooking.Api.Controllers
{
    /// <summary>
    /// Controller لاختبار نظام Redis والفهرسة
    /// </summary>
    [ApiController]
    [Route("api/test-redis")]
    public class TestRedisController : ControllerBase
    {
        private readonly IIndexingService _indexingService;
        private readonly ILogger<TestRedisController> _logger;

        public TestRedisController(
            IIndexingService indexingService,
            ILogger<TestRedisController> logger)
        {
            _indexingService = indexingService;
            _logger = logger;
        }

        /// <summary>
        /// اختبار الاتصال بـ Redis
        /// </summary>
        [HttpGet("connection")]
        public async Task<IActionResult> TestConnection()
        {
            try
            {
                _logger.LogInformation("🔍 بدء اختبار الاتصال بـ Redis...");
                
                // محاولة بحث بسيط
                var searchRequest = new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 1
                };

                var result = await _indexingService.SearchAsync(searchRequest);
                
                return Ok(new
                {
                    success = true,
                    message = "Redis متصل ويعمل بشكل صحيح",
                    totalProperties = result.TotalCount,
                    testTime = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ خطأ في اختبار Redis");
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }

        /// <summary>
        /// اختبار البحث البسيط
        /// </summary>
        [HttpGet("search-simple")]
        public async Task<IActionResult> TestSimpleSearch()
        {
            try
            {
                _logger.LogInformation("🔍 اختبار البحث البسيط...");
                
                var searchRequest = new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 10
                };

                var result = await _indexingService.SearchAsync(searchRequest);
                
                return Ok(new
                {
                    success = true,
                    totalCount = result.TotalCount,
                    propertiesCount = result.Properties?.Count ?? 0,
                    properties = result.Properties?.Take(3).Select(p => new
                    {
                        id = p.Id,
                        name = p.Name,
                        city = p.City,
                        price = p.MinPrice,
                        currency = p.Currency
                    })
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ خطأ في البحث البسيط");
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }

        /// <summary>
        /// اختبار البحث مع فلتر النوع
        /// </summary>
        [HttpGet("search-with-type")]
        public async Task<IActionResult> TestSearchWithType([FromQuery] string? propertyType = null)
        {
            try
            {
                _logger.LogInformation("🔍 اختبار البحث مع فلتر النوع: {PropertyType}", propertyType);
                
                var searchRequest = new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 10,
                    PropertyType = propertyType
                };

                var result = await _indexingService.SearchAsync(searchRequest);
                
                _logger.LogInformation("✅ نتيجة البحث: {Count} من {Total}", 
                    result.Properties?.Count ?? 0, result.TotalCount);
                
                return Ok(new
                {
                    success = true,
                    filter = new { propertyType },
                    totalCount = result.TotalCount,
                    propertiesCount = result.Properties?.Count ?? 0,
                    properties = result.Properties?.Take(5).Select(p => new
                    {
                        id = p.Id,
                        name = p.Name,
                        propertyType = p.PropertyType,
                        city = p.City,
                        price = p.MinPrice
                    })
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ خطأ في البحث مع فلتر النوع");
                return StatusCode(500, new
                {
                    success = false,
                    filter = new { propertyType },
                    error = ex.Message,
                    innerException = ex.InnerException?.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }

        /// <summary>
        /// اختبار البحث مع فلاتر متعددة
        /// </summary>
        [HttpPost("search-complex")]
        public async Task<IActionResult> TestComplexSearch([FromBody] PropertySearchRequest request)
        {
            try
            {
                _logger.LogInformation("🔍 اختبار البحث المعقد مع فلاتر متعددة");
                _logger.LogInformation("   - المدينة: {City}", request.City);
                _logger.LogInformation("   - النوع: {PropertyType}", request.PropertyType);
                _logger.LogInformation("   - السعر: {MinPrice} - {MaxPrice}", request.MinPrice, request.MaxPrice);
                _logger.LogInformation("   - التقييم: {MinRating}", request.MinRating);
                
                var result = await _indexingService.SearchAsync(request);
                
                _logger.LogInformation("✅ نتيجة البحث المعقد: {Count} من {Total}", 
                    result.Properties?.Count ?? 0, result.TotalCount);
                
                return Ok(new
                {
                    success = true,
                    filters = new
                    {
                        city = request.City,
                        propertyType = request.PropertyType,
                        minPrice = request.MinPrice,
                        maxPrice = request.MaxPrice,
                        minRating = request.MinRating,
                        amenities = request.RequiredAmenityIds?.Count ?? 0,
                        services = request.ServiceIds?.Count ?? 0,
                        unitType = request.UnitTypeId
                    },
                    totalCount = result.TotalCount,
                    propertiesCount = result.Properties?.Count ?? 0,
                    totalPages = result.TotalPages,
                    currentPage = result.PageNumber,
                    properties = result.Properties?.Select(p => new
                    {
                        id = p.Id,
                        name = p.Name,
                        propertyType = p.PropertyType,
                        city = p.City,
                        price = p.MinPrice,
                        currency = p.Currency,
                        rating = p.AverageRating,
                        capacity = p.MaxCapacity
                    })
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ خطأ في البحث المعقد");
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message,
                    innerException = ex.InnerException?.Message,
                    type = ex.GetType().Name,
                    stackTrace = ex.StackTrace
                });
            }
        }

        /// <summary>
        /// اختبار فهرسة عقار
        /// </summary>
        [HttpPost("index-property/{propertyId}")]
        public async Task<IActionResult> TestIndexProperty(Guid propertyId)
        {
            try
            {
                _logger.LogInformation("🔍 اختبار فهرسة العقار: {PropertyId}", propertyId);
                
                await _indexingService.OnPropertyCreatedAsync(propertyId);
                
                return Ok(new
                {
                    success = true,
                    message = $"تمت فهرسة العقار {propertyId} بنجاح",
                    propertyId = propertyId,
                    indexedAt = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ خطأ في فهرسة العقار");
                return StatusCode(500, new
                {
                    success = false,
                    propertyId = propertyId,
                    error = ex.Message,
                    innerException = ex.InnerException?.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }
    }
}
