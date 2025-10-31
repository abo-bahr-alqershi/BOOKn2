using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Infrastructure.Services;
using StackExchange.Redis;
using System.Diagnostics;

namespace YemenBooking.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HealthCheckController : ControllerBase
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly ILogger<HealthCheckController> _logger;

        public HealthCheckController(
            IRedisConnectionManager redisManager,
            ILogger<HealthCheckController> logger)
        {
            _redisManager = redisManager;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var health = new
            {
                Status = "Healthy",
                Timestamp = DateTime.UtcNow,
                Services = new
                {
                    Api = "OK",
                    Redis = await CheckRedisHealth()
                }
            };

            return Ok(health);
        }

        [HttpGet("redis")]
        public async Task<IActionResult> RedisHealth()
        {
            var health = await GetDetailedRedisHealth();
            return Ok(health);
        }

        [HttpGet("redis/detailed")]
        public async Task<IActionResult> RedisDetailedHealth()
        {
            try
            {
                var db = _redisManager.GetDatabase();
                var server = _redisManager.GetServer();

                var info = await server.InfoAsync();
                var memorySection = info.FirstOrDefault(s => s.Key == "Memory");
                var statsSection = info.FirstOrDefault(s => s.Key == "Stats");
                var serverSection = info.FirstOrDefault(s => s.Key == "Server");

                var totalKeys = await db.ExecuteAsync("DBSIZE");
                
                var propertiesCount = 0L;
                if (await db.KeyExistsAsync("properties:all"))
                {
                    propertiesCount = await db.SetLengthAsync("properties:all");
                }

                var indexCounts = new Dictionary<string, long>();
                var indexes = new[] { "properties:by_price", "properties:by_rating", "properties:by_created", "properties:by_bookings" };
                foreach (var idx in indexes)
                {
                    if (await db.KeyExistsAsync(idx))
                    {
                        indexCounts[idx] = await db.SortedSetLengthAsync(idx);
                    }
                }

                var geoCount = 0L;
                if (await db.KeyExistsAsync("properties:geo"))
                {
                    geoCount = await db.SortedSetLengthAsync("properties:geo");
                }

                var rediSearchAvailable = false;
                try
                {
                    var modules = await server.ExecuteAsync("MODULE", "LIST");
                    rediSearchAvailable = modules.ToString().Contains("search", StringComparison.OrdinalIgnoreCase);
                }
                catch { }

                var stopwatch = Stopwatch.StartNew();
                await db.StringSetAsync("health:test", "ping");
                var writeLatency = stopwatch.ElapsedMilliseconds;
                
                stopwatch.Restart();
                await db.StringGetAsync("health:test");
                var readLatency = stopwatch.ElapsedMilliseconds;
                
                await db.KeyDeleteAsync("health:test");

                var memoryStats = new Dictionary<string, string>();
                if (memorySection.Any())
                {
                    foreach (var item in memorySection)
                    {
                        if (item.Key.Contains("used_memory") || item.Key.Contains("fragmentation"))
                        {
                            memoryStats[item.Key] = item.Value;
                        }
                    }
                }

                var operationStats = new Dictionary<string, string>();
                if (statsSection.Any())
                {
                    foreach (var item in statsSection)
                    {
                        if (item.Key.Contains("commands") || item.Key.Contains("keyspace") || item.Key.Contains("ops"))
                        {
                            operationStats[item.Key] = item.Value;
                        }
                    }
                }

                var serverInfo = new Dictionary<string, string>();
                if (serverSection.Any())
                {
                    foreach (var item in serverSection)
                    {
                        if (item.Key.Contains("version") || item.Key.Contains("mode") || item.Key.Contains("uptime"))
                        {
                            serverInfo[item.Key] = item.Value;
                        }
                    }
                }

                var hitRate = 0.0;
                if (operationStats.TryGetValue("keyspace_hits", out var hitsStr) && 
                    operationStats.TryGetValue("keyspace_misses", out var missesStr))
                {
                    if (long.TryParse(hitsStr, out var hits) && long.TryParse(missesStr, out var misses))
                    {
                        var total = hits + misses;
                        if (total > 0)
                        {
                            hitRate = (double)hits / total * 100;
                        }
                    }
                }

                var health = new
                {
                    Status = "Healthy",
                    Connected = true,
                    Timestamp = DateTime.UtcNow,
                    Server = serverInfo,
                    Memory = memoryStats,
                    Performance = new
                    {
                        WriteLatencyMs = writeLatency,
                        ReadLatencyMs = readLatency,
                        PerformanceRating = (writeLatency < 10 && readLatency < 10) ? "Excellent" : 
                                          (writeLatency < 50 && readLatency < 50) ? "Good" : "Slow"
                    },
                    Data = new
                    {
                        TotalKeys = totalKeys.ToString(),
                        PropertiesCount = propertiesCount,
                        GeoLocationsCount = geoCount,
                        Indexes = indexCounts
                    },
                    Operations = new
                    {
                        Stats = operationStats,
                        CacheHitRate = $"{hitRate:F2}%",
                        CacheEfficiency = hitRate > 80 ? "Excellent" : hitRate > 50 ? "Good" : "Poor"
                    },
                    Features = new
                    {
                        RediSearchAvailable = rediSearchAvailable,
                        SearchMode = rediSearchAvailable ? "RediSearch (FT.SEARCH)" : "Manual (Redis Structures)"
                    }
                };

                return Ok(health);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في فحص صحة Redis");
                return StatusCode(500, new
                {
                    Status = "Unhealthy",
                    Connected = false,
                    Error = ex.Message,
                    Timestamp = DateTime.UtcNow
                });
            }
        }

        private async Task<object> GetDetailedRedisHealth()
        {
            try
            {
                var isConnected = await _redisManager.IsConnectedAsync();
                if (!isConnected)
                {
                    return new
                    {
                        Status = "Unhealthy",
                        Connected = false,
                        Message = "فشل الاتصال بـ Redis"
                    };
                }

                var db = _redisManager.GetDatabase();
                var stopwatch = Stopwatch.StartNew();
                await db.PingAsync();
                var latency = stopwatch.ElapsedMilliseconds;

                var totalKeys = await db.ExecuteAsync("DBSIZE");

                return new
                {
                    Status = "Healthy",
                    Connected = true,
                    LatencyMs = latency,
                    TotalKeys = totalKeys.ToString(),
                    Timestamp = DateTime.UtcNow
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في فحص Redis");
                return new
                {
                    Status = "Unhealthy",
                    Connected = false,
                    Error = ex.Message
                };
            }
        }

        private async Task<string> CheckRedisHealth()
        {
            try
            {
                var isConnected = await _redisManager.IsConnectedAsync();
                return isConnected ? "OK" : "Disconnected";
            }
            catch
            {
                return "Error";
            }
        }
    }
}
