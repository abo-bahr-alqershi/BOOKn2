using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Concurrent;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Api.Middlewares
{
    /// <summary>
    /// Middleware لتتبع آخر ظهور المستخدم
    /// Tracks user's last seen activity
    /// </summary>
    public class UserActivityTrackingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<UserActivityTrackingMiddleware> _logger;
        private readonly IMemoryCache _cache;
        private readonly IServiceScopeFactory _serviceScopeFactory;
        
        // قاموس لتتبع آخر وقت تحديث لكل مستخدم
        private static readonly ConcurrentDictionary<Guid, DateTime> _lastUpdateTimes = new();
        
        // الحد الأدنى للفترة الزمنية بين التحديثات (بالثواني)
        private const int MinUpdateIntervalSeconds = 60; // تحديث كل دقيقة كحد أدنى
        
        // Semaphore للحد من عدد العمليات المتزامنة
        private static readonly SemaphoreSlim _updateSemaphore = new(10); // حد أقصى 10 عمليات متزامنة

        public UserActivityTrackingMiddleware(
            RequestDelegate next,
            ILogger<UserActivityTrackingMiddleware> logger,
            IMemoryCache cache,
            IServiceScopeFactory serviceScopeFactory)
        {
            _next = next;
            _logger = logger;
            _cache = cache;
            _serviceScopeFactory = serviceScopeFactory;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            Guid? userId = null;
            if (context.User?.Identity?.IsAuthenticated == true)
            {
                userId = GetUserIdFromContext(context);
            }

            if (userId.HasValue)
            {
                // Fire and forget - لا ننتظر اكتمال التحديث
                _ = Task.Run(async () =>
                {
                    try
                    {
                        await UpdateUserLastSeenInBackgroundAsync(userId.Value);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error occurred while tracking user activity in background");
                    }
                });
            }

            // المتابعة مع باقي pipeline فوراً دون انتظار
            await _next(context);
        }

        private async Task UpdateUserLastSeenInBackgroundAsync(Guid userId)
        {
            // التحقق من عدم تحديث المستخدم مؤخراً
            if (ShouldSkipUpdate(userId))
            {
                _logger.LogTrace($"Skipping LastSeen update for user {userId} (too soon)");
                return;
            }

            // محاولة الحصول على Semaphore للحد من العمليات المتزامنة
            var acquired = await _updateSemaphore.WaitAsync(TimeSpan.FromSeconds(1));
            if (!acquired)
            {
                _logger.LogTrace($"Skipping LastSeen update for user {userId} (semaphore busy)");
                return;
            }

            try
            {
                // إنشاء scope جديد للحصول على DbContext منفصل
                using var scope = _serviceScopeFactory.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();

                // تحديث آخر ظهور للمستخدم
                var currentTime = DateTime.UtcNow;
                
                // استخدام ExecuteUpdateAsync للأداء الأفضل (EF Core 7+)
                var updateResult = await dbContext.Users
                    .Where(u => u.Id == userId)
                    .ExecuteUpdateAsync(setters => setters
                        .SetProperty(u => u.LastSeen, currentTime));

                if (updateResult > 0)
                {
                    // تحديث وقت آخر تحديث في القاموس
                    _lastUpdateTimes.AddOrUpdate(userId, currentTime, (key, old) => currentTime);
                    _logger.LogDebug($"Updated LastSeen for user {userId} at {currentTime}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Error updating LastSeen for user {userId}", userId);
            }
            finally
            {
                _updateSemaphore.Release();
            }
        }

        /// <summary>
        /// الحصول على معرف المستخدم من HttpContext مع التخزين المؤقت
        /// </summary>
        private Guid? GetUserIdFromContext(HttpContext context)
        {
            // مفتاح التخزين المؤقت
            var cacheKey = $"user_id_{context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? context.User.FindFirst("id")?.Value ?? context.User.FindFirst("sub")?.Value ?? context.User.FindFirst("userId")?.Value ?? context.User.FindFirst("user_id")?.Value ?? context.User.Identity?.Name}";
            
            // محاولة الحصول من التخزين المؤقت
            if (_cache.TryGetValue<Guid>(cacheKey, out var cachedUserId))
            {
                return cachedUserId;
            }

            // البحث في Claims
            var userIdClaim = context.User.FindFirst(ClaimTypes.NameIdentifier) 
                              ?? context.User.FindFirst("id")
                              ?? context.User.FindFirst("sub")
                              ?? context.User.FindFirst("userId")
                              ?? context.User.FindFirst("user_id");

            if (userIdClaim == null || string.IsNullOrEmpty(userIdClaim.Value))
            {
                return null;
            }

            // محاولة تحويل معرف المستخدم إلى Guid
            if (!Guid.TryParse(userIdClaim.Value, out var userId))
            {
                _logger.LogWarning($"Unable to parse user ID: {userIdClaim.Value}");
                return null;
            }

            // حفظ في التخزين المؤقت لمدة 5 دقائق
            _cache.Set(cacheKey, userId, TimeSpan.FromMinutes(5));
            return userId;
        }

        /// <summary>
        /// التحقق من الحاجة لتخطي التحديث بناءً على آخر وقت تحديث
        /// </summary>
        private bool ShouldSkipUpdate(Guid userId)
        {
            if (!_lastUpdateTimes.TryGetValue(userId, out var lastUpdate))
            {
                // لم يتم التحديث من قبل، يجب التحديث
                return false;
            }

            var timeSinceLastUpdate = DateTime.UtcNow - lastUpdate;
            return timeSinceLastUpdate.TotalSeconds < MinUpdateIntervalSeconds;
        }
    }

    /// <summary>
    /// Extension methods لتسجيل الـ Middleware
    /// </summary>
    public static class UserActivityTrackingMiddlewareExtensions
    {
        /// <summary>
        /// تسجيل Middleware تتبع نشاط المستخدم
        /// </summary>
        public static IApplicationBuilder UseUserActivityTracking(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<UserActivityTrackingMiddleware>();
        }
    }
}
