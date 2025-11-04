using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.IndexingTests.Infrastructure.Utilities
{
    /// <summary>
    /// أدوات مساعدة للاختبارات
    /// </summary>
    public static class TestUtilities
    {
        /// <summary>
        /// إنشاء معرف فريد للاختبار
        /// </summary>
        public static string GenerateTestId(string prefix = "TEST")
        {
            return $"{prefix}_{DateTime.UtcNow:yyyyMMddHHmmss}_{Guid.NewGuid():N}";
        }
        
        /// <summary>
        /// إنشاء أسماء فريدة
        /// </summary>
        public static string GenerateUniqueName(string baseName)
        {
            return $"{baseName}_{Guid.NewGuid():N.Substring(0, 8)}";
        }
        
        /// <summary>
        /// تنفيذ عملية مع timeout
        /// </summary>
        public static async Task<T> ExecuteWithTimeoutAsync<T>(
            Func<CancellationToken, Task<T>> operation,
            TimeSpan timeout)
        {
            using var cts = new CancellationTokenSource(timeout);
            
            try
            {
                return await operation(cts.Token);
            }
            catch (OperationCanceledException) when (cts.IsCancellationRequested)
            {
                throw new TimeoutException($"Operation timed out after {timeout}");
            }
        }
        
        /// <summary>
        /// تنفيذ عملية مع إعادة المحاولة
        /// </summary>
        public static async Task<T> RetryAsync<T>(
            Func<Task<T>> operation,
            int maxAttempts = 3,
            TimeSpan? delay = null,
            Func<Exception, bool> shouldRetry = null)
        {
            delay ??= TimeSpan.FromSeconds(1);
            shouldRetry ??= ex => true;
            
            Exception lastException = null;
            
            for (int attempt = 1; attempt <= maxAttempts; attempt++)
            {
                try
                {
                    return await operation();
                }
                catch (Exception ex)
                {
                    lastException = ex;
                    
                    if (attempt < maxAttempts && shouldRetry(ex))
                    {
                        var backoffDelay = TimeSpan.FromMilliseconds(
                            delay.Value.TotalMilliseconds * Math.Pow(2, attempt - 1)
                        );
                        await Task.Delay(backoffDelay);
                    }
                    else
                    {
                        throw;
                    }
                }
            }
            
            throw lastException ?? new Exception("Retry failed");
        }
        
        /// <summary>
        /// انتظار شرط معين
        /// </summary>
        public static async Task WaitForConditionAsync(
            Func<Task<bool>> condition,
            TimeSpan timeout,
            TimeSpan? pollInterval = null,
            string timeoutMessage = null)
        {
            pollInterval ??= TimeSpan.FromMilliseconds(100);
            var deadline = DateTime.UtcNow.Add(timeout);
            
            while (DateTime.UtcNow < deadline)
            {
                if (await condition())
                    return;
                
                var remainingTime = deadline - DateTime.UtcNow;
                if (remainingTime <= TimeSpan.Zero)
                    break;
                
                var delay = remainingTime < pollInterval.Value ? remainingTime : pollInterval.Value;
                await Task.Delay(delay);
            }
            
            throw new TimeoutException(timeoutMessage ?? $"Condition not met within {timeout}");
        }
        
        /// <summary>
        /// تنظيف قاعدة البيانات
        /// </summary>
        public static async Task CleanDatabaseAsync(YemenBookingDbContext context)
        {
            // حذف البيانات بالترتيب الصحيح لتجنب انتهاك FK
            var tables = new[]
            {
                "bookings",
                "unit_availabilities",
                "unit_amenities",
                "units",
                "property_amenities",
                "property_images",
                "properties"
            };
            
            foreach (var table in tables)
            {
                try
                {
                    await context.Database.ExecuteSqlRawAsync($"TRUNCATE TABLE {table} CASCADE");
                }
                catch
                {
                    // تجاهل الأخطاء في حالة عدم وجود الجدول
                }
            }
            
            context.ChangeTracker.Clear();
        }
        
        /// <summary>
        /// إنشاء scope معزول
        /// </summary>
        public static IServiceScope CreateIsolatedScope(IServiceProvider serviceProvider)
        {
            return serviceProvider.CreateScope();
        }
        
        /// <summary>
        /// تنفيذ عملية في scope معزول
        /// </summary>
        public static async Task<T> ExecuteInIsolatedScopeAsync<T>(
            IServiceProvider serviceProvider,
            Func<IServiceScope, Task<T>> operation)
        {
            using var scope = CreateIsolatedScope(serviceProvider);
            return await operation(scope);
        }
        
        /// <summary>
        /// مقارنة قوائم بغض النظر عن الترتيب
        /// </summary>
        public static bool ListsAreEquivalent<T>(IEnumerable<T> list1, IEnumerable<T> list2)
        {
            var l1 = list1?.ToList() ?? new List<T>();
            var l2 = list2?.ToList() ?? new List<T>();
            
            return l1.Count == l2.Count && !l1.Except(l2).Any();
        }
        
        /// <summary>
        /// توليد بيانات عشوائية
        /// </summary>
        public static class RandomData
        {
            private static readonly Random _random = new Random();
            private static readonly string[] _arabicCities = 
            {
                "صنعاء", "عدن", "تعز", "الحديدة", "إب", "ذمار", "المكلا"
            };
            
            private static readonly string[] _arabicNames = 
            {
                "فندق", "منتجع", "شقة", "فيلا", "شاليه", "نزل", "دار"
            };
            
            public static string GetRandomCity()
            {
                return _arabicCities[_random.Next(_arabicCities.Length)];
            }
            
            public static string GetRandomPropertyName()
            {
                var prefix = _arabicNames[_random.Next(_arabicNames.Length)];
                var suffix = _random.Next(1, 100);
                return $"{prefix} {suffix}";
            }
            
            public static decimal GetRandomPrice(decimal min = 50, decimal max = 1000)
            {
                return (decimal)(_random.NextDouble() * (double)(max - min) + (double)min);
            }
            
            public static int GetRandomCapacity(int min = 1, int max = 10)
            {
                return _random.Next(min, max + 1);
            }
            
            public static DateTime GetRandomDate(int daysFromNow = 30)
            {
                return DateTime.UtcNow.AddDays(_random.Next(1, daysFromNow + 1));
            }
        }
    }
}
