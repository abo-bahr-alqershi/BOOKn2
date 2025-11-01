using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Redis;
using YemenBooking.Infrastructure.Redis.Cache;
using YemenBooking.Infrastructure.Redis.Monitoring;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.Api.Controllers
{
    /// <summary>
    /// واجهة إدارة نظام Redis
    /// توفر نقاط نهاية لإدارة ومراقبة نظام الفهرسة والبحث
    /// </summary>
    [ApiController]
    [Route("api/admin/redis")]
    [Authorize(Roles = "Admin,SystemAdmin")]
    public class RedisAdminController : ControllerBase
    {
        private readonly IIndexingService _indexingService;
        private readonly IMultiLevelCache _cacheManager;
        private readonly ErrorHandlingAndMonitoring _errorHandler;
        private readonly ILogger<RedisAdminController> _logger;

        /// <summary>
        /// مُنشئ وحدة التحكم الإدارية
        /// </summary>
        public RedisAdminController(
            IIndexingService indexingService,
            IMultiLevelCache cacheManager,
            ErrorHandlingAndMonitoring errorHandler,
            ILogger<RedisAdminController> logger)
        {
            _indexingService = indexingService;
            _cacheManager = cacheManager;
            _errorHandler = errorHandler;
            _logger = logger;
        }

        #region إدارة الفهارس

        /// <summary>
        /// إعادة بناء الفهرس الكامل
        /// </summary>
        /// <remarks>
        /// عملية ثقيلة تستغرق وقتاً طويلاً
        /// يُنصح بتشغيلها في أوقات قليلة الحركة
        /// </remarks>
        [HttpPost("rebuild-index")]
        public async Task<IActionResult> RebuildIndex()
        {
            try
            {
                _logger.LogInformation("طلب إعادة بناء الفهرس من {User}", User.Identity?.Name);
                
                // يمكن تشغيلها في الخلفية
                _ = Task.Run(async () =>
                {
                    try
                    {
                        await _indexingService.RebuildIndexAsync();
                        _logger.LogInformation("✅ اكتملت إعادة بناء الفهرس");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "❌ فشلت إعادة بناء الفهرس");
                    }
                });
                
                return Accepted(new 
                { 
                    message = "بدأت عملية إعادة بناء الفهرس في الخلفية",
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في بدء إعادة بناء الفهرس");
                return StatusCode(500, new { error = "فشل في بدء إعادة البناء" });
            }
        }

        /// <summary>
        /// تحسين قاعدة البيانات
        /// </summary>
        /// <remarks>
        /// ينظف البيانات القديمة ويحسن الأداء
        /// </remarks>
        [HttpPost("optimize")]
        public async Task<IActionResult> OptimizeDatabase()
        {
            try
            {
                _logger.LogInformation("طلب تحسين قاعدة البيانات من {User}", User.Identity?.Name);
                
                await _indexingService.OptimizeDatabaseAsync();
                
                return Ok(new 
                { 
                    message = "تم تحسين قاعدة البيانات بنجاح",
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحسين قاعدة البيانات");
                return StatusCode(500, new { error = "فشل في التحسين" });
            }
        }

        /// <summary>
        /// فهرسة عقار محدد
        /// </summary>
        [HttpPost("index-property/{propertyId}")]
        public async Task<IActionResult> IndexProperty(Guid propertyId)
        {
            try
            {
                _logger.LogInformation("طلب فهرسة العقار {PropertyId} من {User}", 
                    propertyId, User.Identity?.Name);
                
                await _indexingService.OnPropertyCreatedAsync(propertyId);
                
                return Ok(new 
                { 
                    message = $"تمت فهرسة العقار {propertyId} بنجاح",
                    propertyId = propertyId,
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في فهرسة العقار {PropertyId}", propertyId);
                return StatusCode(500, new { error = "فشل في الفهرسة" });
            }
        }

        #endregion

        #region إدارة الكاش

        /// <summary>
        /// مسح الكاش بالكامل
        /// </summary>
        [HttpDelete("cache/flush")]
        public async Task<IActionResult> FlushCache()
        {
            try
            {
                _logger.LogWarning("طلب مسح الكاش من {User}", User.Identity?.Name);
                
                await _cacheManager.FlushAsync();
                
                return Ok(new 
                { 
                    message = "تم مسح الكاش بنجاح",
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في مسح الكاش");
                return StatusCode(500, new { error = "فشل في مسح الكاش" });
            }
        }

        /// <summary>
        /// الحصول على إحصائيات الكاش
        /// </summary>
        [HttpGet("cache/stats")]
        public async Task<IActionResult> GetCacheStatistics()
        {
            try
            {
                var stats = await _cacheManager.GetStatisticsAsync();
                
                return Ok(new
                {
                    statistics = stats,
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في جلب إحصائيات الكاش");
                return StatusCode(500, new { error = "فشل في جلب الإحصائيات" });
            }
        }

        /// <summary>
        /// إعادة تعيين إحصائيات الكاش
        /// </summary>
        [HttpPost("cache/reset-stats")]
        public async Task<IActionResult> ResetCacheStatistics()
        {
            try
            {
                await _cacheManager.ResetStatisticsAsync();
                
                return Ok(new 
                { 
                    message = "تم إعادة تعيين إحصائيات الكاش",
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في إعادة تعيين الإحصائيات");
                return StatusCode(500, new { error = "فشل في إعادة التعيين" });
            }
        }

        #endregion

        #region المراقبة والإحصائيات

        /// <summary>
        /// الحصول على إحصائيات النظام الشاملة
        /// </summary>
        [HttpGet("stats")]
        public async Task<IActionResult> GetSystemStatistics()
        {
            try
            {
                if (_indexingService is RedisIndexingSystem redisSystem)
                {
                    var stats = await redisSystem.GetSystemStatisticsAsync();
                    
                    return Ok(new
                    {
                        statistics = stats,
                        timestamp = DateTime.UtcNow
                    });
                }
                
                return NotFound(new { error = "نظام Redis غير مفعل" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في جلب إحصائيات النظام");
                return StatusCode(500, new { error = "فشل في جلب الإحصائيات" });
            }
        }

        /// <summary>
        /// الحصول على إحصائيات الأداء
        /// </summary>
        [HttpGet("performance")]
        public async Task<IActionResult> GetPerformanceStatistics()
        {
            try
            {
                var stats = await _errorHandler.GetPerformanceStatisticsAsync();
                
                return Ok(new
                {
                    performance = stats,
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في جلب إحصائيات الأداء");
                return StatusCode(500, new { error = "فشل في جلب الإحصائيات" });
            }
        }

        /// <summary>
        /// فحص صحة النظام
        /// </summary>
        [HttpGet("health")]
        public async Task<IActionResult> CheckSystemHealth()
        {
            try
            {
                var health = await _errorHandler.CheckSystemHealthAsync();
                
                var statusCode = health.Status switch
                {
                    HealthStatus.Healthy => 200,
                    HealthStatus.Degraded => 200,
                    HealthStatus.Unhealthy => 503,
                    _ => 200
                };
                
                return StatusCode(statusCode, new
                {
                    health = health,
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في فحص صحة النظام");
                return StatusCode(500, new { error = "فشل في الفحص الصحي" });
            }
        }

        #endregion

        #region البحث التجريبي

        /// <summary>
        /// بحث تجريبي في العقارات
        /// </summary>
        /// <remarks>
        /// نقطة نهاية للاختبار والتصحيح
        /// </remarks>
        [HttpPost("search/test")]
        [AllowAnonymous] // للاختبار فقط - يجب إزالته في الإنتاج
        public async Task<IActionResult> TestSearch([FromBody] PropertySearchRequest request)
        {
            try
            {
                var stopwatch = System.Diagnostics.Stopwatch.StartNew();
                var result = await _indexingService.SearchAsync(request);
                stopwatch.Stop();
                
                return Ok(new
                {
                    result = result,
                    executionTimeMs = stopwatch.ElapsedMilliseconds,
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في البحث التجريبي");
                return StatusCode(500, new { error = "فشل في البحث" });
            }
        }

        #endregion

        #region معلومات النظام

        /// <summary>
        /// الحصول على معلومات النظام
        /// </summary>
        [HttpGet("info")]
        public IActionResult GetSystemInfo()
        {
            return Ok(new
            {
                system = "Redis Indexing System",
                version = "2.0.0",
                environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT"),
                features = new
                {
                    indexing = true,
                    search = true,
                    multiLevelCache = true,
                    availability = true,
                    monitoring = true,
                    luaScripts = true,
                    rediSearch = "auto-detect"
                },
                documentation = "/api/admin/redis/docs",
                timestamp = DateTime.UtcNow
            });
        }

        /// <summary>
        /// الحصول على التوثيق
        /// </summary>
        [HttpGet("docs")]
        [AllowAnonymous]
        public IActionResult GetDocumentation()
        {
            return Ok(new
            {
                title = "Redis Indexing System API Documentation",
                endpoints = new[]
                {
                    new { method = "POST", path = "/api/admin/redis/rebuild-index", description = "إعادة بناء الفهرس الكامل" },
                    new { method = "POST", path = "/api/admin/redis/optimize", description = "تحسين قاعدة البيانات" },
                    new { method = "POST", path = "/api/admin/redis/index-property/{id}", description = "فهرسة عقار محدد" },
                    new { method = "DELETE", path = "/api/admin/redis/cache/flush", description = "مسح الكاش" },
                    new { method = "GET", path = "/api/admin/redis/cache/stats", description = "إحصائيات الكاش" },
                    new { method = "GET", path = "/api/admin/redis/stats", description = "إحصائيات النظام" },
                    new { method = "GET", path = "/api/admin/redis/performance", description = "إحصائيات الأداء" },
                    new { method = "GET", path = "/api/admin/redis/health", description = "فحص صحة النظام" },
                    new { method = "POST", path = "/api/admin/redis/search/test", description = "بحث تجريبي" },
                    new { method = "GET", path = "/api/admin/redis/info", description = "معلومات النظام" }
                },
                authentication = "Bearer Token with Admin role",
                documentation = "https://github.com/yemenbooking/docs/redis",
                support = "support@yemenbooking.com"
            });
        }

        #endregion
    }
}
