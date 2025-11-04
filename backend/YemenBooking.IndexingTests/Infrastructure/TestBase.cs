using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Threading;
using System.Linq;
using Xunit;
using Xunit.Abstractions;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Entities;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using StackExchange.Redis;
using Polly;
using System.Diagnostics;
using Microsoft.AspNetCore.Http;

namespace YemenBooking.IndexingTests.Infrastructure
{
    /// <summary>
    /// الفئة الأساسية لجميع الاختبارات - بدون static state
    /// كل اختبار معزول تماماً عن الآخر
    /// تطبق مبادئ العزل الكامل والحتمية
    /// </summary>
    public abstract class TestBase : IAsyncLifetime, IDisposable
    {
        protected readonly ITestOutputHelper Output;
        protected IServiceProvider ServiceProvider;
        protected IServiceScope TestScope;
        protected readonly string TestId;
        protected readonly CancellationTokenSource TestCancellation;
        
        // خدمات أساسية لكل اختبار
        protected YemenBookingDbContext DbContext;
        protected IIndexingService IndexingService;
        protected IRedisConnectionManager RedisManager;
        protected IDatabase RedisDatabase;
        protected ILogger<TestBase> Logger;
        
        // TestContainers
        protected TestContainerFixture ContainerFixture;
        
        // للتتبع والتنظيف
        private readonly List<Guid> _trackedEntities = new();
        private readonly List<string> _trackedRedisKeys = new();
        private readonly List<IDisposable> _disposables = new();
        private readonly SemaphoreSlim _cleanupLock = new(1, 1);
        
        // Redis key prefix للعزل
        protected readonly string RedisKeyPrefix;
        
        protected TestBase(ITestOutputHelper output)
        {
            Output = output ?? throw new ArgumentNullException(nameof(output));
            TestId = $"Test_{Guid.NewGuid():N}";
            RedisKeyPrefix = $"test:{TestId}:";
            TestCancellation = new CancellationTokenSource();
            
            // سيتم تهيئة الخدمات في InitializeAsync
        }
        
        /// <summary>
        /// تهيئة الاختبار - يتم استدعاؤها قبل كل اختبار
        /// </summary>
        public virtual async Task InitializeAsync()
        {
            var stopwatch = Stopwatch.StartNew();
            Output.WriteLine($"🚀 Initializing test: {TestId} at {DateTime.UtcNow:HH:mm:ss.fff}");
            
            try
            {
                // تهيئة TestContainers إذا لزم
                if (UseTestContainers())
                {
                    ContainerFixture = new TestContainerFixture();
                    await ContainerFixture.InitializeAsync();
                    _disposables.Add(ContainerFixture);
                }
                
                // إنشاء ServiceProvider مخصص لهذا الاختبار
                var services = new ServiceCollection();
                await ConfigureServicesAsync(services);
                
                var provider = services.BuildServiceProvider();
                _disposables.Add(provider);
                
                // إنشاء scope منفصل للاختبار
                TestScope = provider.CreateScope();
                _disposables.Add(TestScope);
                
                ServiceProvider = TestScope.ServiceProvider;
                
                // الحصول على الخدمات الأساسية
                DbContext = ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                IndexingService = ServiceProvider.GetRequiredService<IIndexingService>();
                RedisManager = ServiceProvider.GetRequiredService<IRedisConnectionManager>();
                RedisDatabase = RedisManager.GetDatabase();
                Logger = ServiceProvider.GetRequiredService<ILogger<TestBase>>();
                
                // تهيئة قاعدة البيانات
                await InitializeDatabaseAsync();
                
                // التحقق من جاهزية الخدمات
                await VerifyServicesReadyAsync();
                
                stopwatch.Stop();
                Output.WriteLine($"✅ Test {TestId} initialized successfully in {stopwatch.ElapsedMilliseconds}ms");
            }
            catch (Exception ex)
            {
                Output.WriteLine($"❌ Failed to initialize test {TestId}: {ex.Message}");
                throw;
            }
        }
        
        /// <summary>
        /// تكوين الخدمات للاختبار - يمكن للفئات المشتقة تخصيصها
        /// </summary>
        protected virtual async Task ConfigureServicesAsync(IServiceCollection services)
        {
            // إضافة Configuration
            var configData = new Dictionary<string, string>();
            
            if (UseTestContainers() && ContainerFixture != null)
            {
                // استخدام TestContainers connection strings
                configData["ConnectionStrings:Redis"] = ContainerFixture.RedisConnectionString;
                configData["ConnectionStrings:DefaultConnection"] = ContainerFixture.PostgresConnectionString;
            }
            else
            {
                // استخدام In-Memory للاختبارات السريعة
                configData["ConnectionStrings:Redis"] = "localhost:6379";
            }
            
            configData["Redis:DefaultDatabase"] = "0";
            configData["Redis:ConnectTimeout"] = "5000";
            configData["Redis:ConnectRetry"] = "3";
            configData["Redis:AbortOnConnectFail"] = "false";
            
            var configuration = new ConfigurationBuilder()
                .AddInMemoryCollection(configData)
                .Build();
            
            services.AddSingleton<IConfiguration>(configuration);
            
            // تسجيل قاعدة البيانات
            if (UseTestContainers() && ContainerFixture != null)
            {
                // استخدام PostgreSQL حقيقي
                services.AddDbContext<YemenBookingDbContext>(options =>
                {
                    options.UseNpgsql(ContainerFixture.PostgresConnectionString);
                    options.EnableSensitiveDataLogging();
                    options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
                });
            }
            else
            {
                // استخدام In-Memory Database للاختبارات السريعة
                var dbName = $"TestDb_{TestId}_{Guid.NewGuid():N}";
                services.AddDbContext<YemenBookingDbContext>(options =>
                {
                    options.UseInMemoryDatabase(dbName);
                    options.EnableSensitiveDataLogging();
                    options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
                });
            }
            
            // تسجيل خدمات Redis الحقيقية
            services.AddSingleton<IRedisConnectionManager, RedisConnectionManager>();
            
            // تسجيل خدمة الفهرسة الحقيقية
            services.AddScoped<IIndexingService, IndexingService>();
            
            // تسجيل IHttpContextAccessor المطلوب لـ DbContext
            services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();
            
            // تسجيل Logging
            services.AddLogging(builder =>
            {
                builder.AddConsole();
                builder.SetMinimumLevel(LogLevel.Debug);
            });
            
            await Task.CompletedTask;
        }
        
        /// <summary>
        /// تهيئة قاعدة البيانات للاختبار
        /// </summary>
        protected virtual async Task InitializeDatabaseAsync()
        {
            try
            {
                // إنشاء قاعدة البيانات والجداول إذا لزم
                if (UseTestContainers() && ContainerFixture != null)
                {
                    // إنشاء قاعدة البيانات من EF Core migrations
                    await DbContext.Database.EnsureDeletedAsync();
                    await DbContext.Database.EnsureCreatedAsync();
                }
                else
                {
                    // لقواعد البيانات InMemory
                    await DbContext.Database.EnsureCreatedAsync();
                }
                // إضافة بيانات Cities الأساسية
                var cities = new[]
                {
                    new City { Name = "صنعاء", Country = "اليمن", ImagesJson = "[]" },
                    new City { Name = "عدن", Country = "اليمن", ImagesJson = "[]" },
                    new City { Name = "تعز", Country = "اليمن", ImagesJson = "[]" },
                    new City { Name = "الحديدة", Country = "اليمن", ImagesJson = "[]" },
                    new City { Name = "إب", Country = "اليمن", ImagesJson = "[]" }
                };
                
                // إضافة بيانات PropertyTypes الأساسية
                var propertyTypes = new[]
                {
                    new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000001"), Name = "منتجع", Description = "منتجع سياحي" },
                    new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000002"), Name = "شقق مفروشة", Description = "شقق مفروشة للإيجار" },
                    new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000003"), Name = "فندق", Description = "فندق" },
                    new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000004"), Name = "فيلا", Description = "فيلا سكنية" },
                    new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000005"), Name = "شاليه", Description = "شاليه شاطئي" }
                };
                
                // إضافة بيانات UnitTypes الأساسية
                var unitTypes = new[]
                {
                    new UnitType { Id = Guid.Parse("20000000-0000-0000-0000-000000000001"), Name = "غرفة مفردة", Description = "غرفة لشخص واحد" },
                    new UnitType { Id = Guid.Parse("20000000-0000-0000-0000-000000000002"), Name = "غرفة مزدوجة", Description = "غرفة لشخصين" },
                    new UnitType { Id = Guid.Parse("20000000-0000-0000-0000-000000000003"), Name = "جناح", Description = "جناح فندقي" },
                    new UnitType { Id = Guid.Parse("20000000-0000-0000-0000-000000000004"), Name = "شقة", Description = "شقة كاملة" }
                };
                
                // إضافة بيانات Amenities الأساسية
                var amenities = new[]
                {
                    new Amenity { Id = Guid.Parse("10000000-0000-0000-0000-000000000001"), Name = "WiFi", Description = "WiFi Internet", Icon = "wifi" },
                    new Amenity { Id = Guid.Parse("10000000-0000-0000-0000-000000000002"), Name = "موقف سيارات", Description = "موقف سيارات مجاني", Icon = "parking" },
                    new Amenity { Id = Guid.Parse("10000000-0000-0000-0000-000000000003"), Name = "مسبح", Description = "مسبح", Icon = "pool" },
                    new Amenity { Id = Guid.Parse("10000000-0000-0000-0000-000000000004"), Name = "مطعم", Description = "مطعم في الموقع", Icon = "restaurant" },
                    new Amenity { Id = Guid.Parse("10000000-0000-0000-0000-000000000005"), Name = "صالة رياضية", Description = "صالة رياضية مجهزة", Icon = "gym" }
                };
                
                // إضافة بيانات Currency الأساسية
                var currencies = new[]
                {
                    new Currency { 
                        Code = "YER", 
                        ArabicCode = "ر.ي",
                        Name = "Yemeni Rial",
                        ArabicName = "ريال يمني", 
                        IsDefault = true,
                        ExchangeRate = null
                    },
                    new Currency { 
                        Code = "USD", 
                        ArabicCode = "$",
                        Name = "US Dollar",
                        ArabicName = "دولار أمريكي", 
                        IsDefault = false,
                        ExchangeRate = 250m
                    },
                    new Currency { 
                        Code = "SAR", 
                        ArabicCode = "ر.س",
                        Name = "Saudi Riyal",
                        ArabicName = "ريال سعودي", 
                        IsDefault = false,
                        ExchangeRate = 67m
                    }
                };
                
                // تجنب الإضافة المكررة إذا كانت البيانات موجودة بالفعل
                if (!DbContext.Cities.Any(c => c.Name == cities[0].Name))
                {
                    await DbContext.Cities.AddRangeAsync(cities);
                }
                
                if (!DbContext.PropertyTypes.Any(pt => pt.Id == propertyTypes[0].Id))
                {
                    await DbContext.PropertyTypes.AddRangeAsync(propertyTypes);
                }
                
                if (!DbContext.UnitTypes.Any(ut => ut.Id == unitTypes[0].Id))
                {
                    await DbContext.UnitTypes.AddRangeAsync(unitTypes);
                }
                
                if (!DbContext.Amenities.Any(a => a.Id == amenities[0].Id))
                {
                    await DbContext.Amenities.AddRangeAsync(amenities);
                }
                
                if (!DbContext.Currencies.Any(c => c.Code == "YER"))
                {
                    await DbContext.Currencies.AddRangeAsync(currencies);
                }
                
                await DbContext.SaveChangesAsync();
                DbContext.ChangeTracker.Clear();
                
                Output.WriteLine($"✅ Database initialized with base data");
            }
            catch (Exception ex)
            {
                Output.WriteLine($"⚠️ Error initializing database: {ex.Message}");
            }
        }
        
        /// <summary>
        /// تنظيف الاختبار - يتم استدعاؤها بعد كل اختبار
        /// </summary>
        public virtual async Task DisposeAsync()
        {
            await _cleanupLock.WaitAsync();
            try
            {
                var stopwatch = Stopwatch.StartNew();
                Output.WriteLine($"🧹 Cleaning up test: {TestId} at {DateTime.UtcNow:HH:mm:ss.fff}");
                
                // إلغاء أي عمليات جارية
                TestCancellation.Cancel();
                
                // تنظيف البيانات المتتبعة بالتوازي
                var cleanupTasks = new List<Task>();
                
                if (_trackedEntities.Any())
                {
                    cleanupTasks.Add(CleanupTrackedEntitiesAsync());
                }
                
                if (_trackedRedisKeys.Any())
                {
                    cleanupTasks.Add(CleanupRedisKeysAsync());
                }
                
                if (cleanupTasks.Any())
                {
                    await Task.WhenAll(cleanupTasks);
                }
                
                // تنظيف الموارد
                foreach (var disposable in _disposables.AsEnumerable().Reverse())
                {
                    try
                    {
                        disposable?.Dispose();
                    }
                    catch (Exception ex)
                    {
                        Output.WriteLine($"⚠️ Error disposing resource: {ex.Message}");
                    }
                }
                
                stopwatch.Stop();
                Output.WriteLine($"✅ Test {TestId} cleaned up successfully in {stopwatch.ElapsedMilliseconds}ms");
            }
            catch (Exception ex)
            {
                Output.WriteLine($"❌ Error during cleanup: {ex.Message}");
            }
            finally
            {
                _cleanupLock.Release();
            }
        }
        
        public virtual void Dispose()
        {
            // التنظيف الإضافي إذا لزم
            TestCancellation?.Dispose();
            _cleanupLock?.Dispose();
        }
        
        #region Helper Methods
        
        /// <summary>
        /// إنشاء scope منفصل للعمليات المتزامنة
        /// </summary>
        protected IServiceScope CreateIsolatedScope()
        {
            var scope = ServiceProvider.CreateScope();
            _disposables.Add(scope);
            return scope;
        }
        
        /// <summary>
        /// تتبع كيان للتنظيف التلقائي
        /// </summary>
        protected void TrackEntity(Guid entityId)
        {
            _trackedEntities.Add(entityId);
        }
        
        /// <summary>
        /// تتبع عدة كيانات للتنظيف
        /// </summary>
        protected void TrackEntities(IEnumerable<Guid> entityIds)
        {
            _trackedEntities.AddRange(entityIds);
        }
        
        /// <summary>
        /// تنظيف الكيانات المتتبعة
        /// </summary>
        protected virtual async Task CleanupTrackedEntitiesAsync()
        {
            if (!_trackedEntities.Any())
                return;
                
            try
            {
                Output.WriteLine($"🗑️ Cleaning up {_trackedEntities.Count} tracked entities");
                
                // التنظيف سيتم تنفيذه في الفئات المشتقة حسب نوع قاعدة البيانات
                await PerformEntityCleanupAsync(_trackedEntities);
                
                _trackedEntities.Clear();
            }
            catch (Exception ex)
            {
                Output.WriteLine($"⚠️ Error cleaning tracked entities: {ex.Message}");
            }
        }
        
        /// <summary>
        /// تنفيذ التنظيف الفعلي للكيانات
        /// </summary>
        protected virtual async Task PerformEntityCleanupAsync(List<Guid> entityIds)
        {
            if (!entityIds.Any()) return;
            
            try
            {
                // التنظيف بالترتيب العكسي لتجنب مشاكل FK
                using var scope = CreateIsolatedScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                
                // حذف الوحدات أولاً
                var units = await dbContext.Units
                    .Where(u => entityIds.Contains(u.Id) || entityIds.Contains(u.PropertyId))
                    .ToListAsync();
                
                if (units.Any())
                {
                    dbContext.Units.RemoveRange(units);
                }
                
                // حذف العقارات
                var properties = await dbContext.Properties
                    .Where(p => entityIds.Contains(p.Id))
                    .ToListAsync();
                
                if (properties.Any())
                {
                    dbContext.Properties.RemoveRange(properties);
                }
                
                await dbContext.SaveChangesAsync();
                dbContext.ChangeTracker.Clear();
            }
            catch (Exception ex)
            {
                Output.WriteLine($"⚠️ Error cleaning entities: {ex.Message}");
            }
        }
        
        /// <summary>
        /// انتظار شرط معين مع timeout - polling pattern
        /// </summary>
        protected async Task<T> WaitForConditionAsync<T>(
            Func<Task<T>> checkCondition,
            Func<T, bool> isConditionMet,
            TimeSpan timeout,
            TimeSpan? pollInterval = null)
        {
            pollInterval ??= TimeSpan.FromMilliseconds(100);
            var deadline = DateTime.UtcNow.Add(timeout);
            
            while (DateTime.UtcNow < deadline)
            {
                TestCancellation.Token.ThrowIfCancellationRequested();
                
                var result = await checkCondition();
                if (isConditionMet(result))
                {
                    return result;
                }
                
                var remainingTime = deadline - DateTime.UtcNow;
                if (remainingTime <= TimeSpan.Zero)
                    break;
                    
                var delay = remainingTime < pollInterval.Value ? remainingTime : pollInterval.Value;
                await Task.Delay(delay, TestCancellation.Token);
            }
            
            throw new TimeoutException($"Condition not met within {timeout}");
        }
        
        /// <summary>
        /// انتظار حتى يصبح شرط صحيحاً
        /// </summary>
        protected async Task WaitUntilAsync(
            Func<Task<bool>> condition,
            TimeSpan timeout,
            string timeoutMessage = null)
        {
            await WaitForConditionAsync(
                condition,
                result => result,
                timeout);
        }
        
        /// <summary>
        /// قياس وقت التنفيذ
        /// </summary>
        protected async Task<(T Result, TimeSpan Duration)> MeasureAsync<T>(Func<Task<T>> operation)
        {
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            var result = await operation();
            stopwatch.Stop();
            
            Output.WriteLine($"⏱️ Operation completed in {stopwatch.ElapsedMilliseconds}ms");
            return (result, stopwatch.Elapsed);
        }
        
        /// <summary>
        /// تنفيذ عملية مع إعادة المحاولة
        /// </summary>
        protected async Task<T> RetryAsync<T>(
            Func<Task<T>> operation,
            int maxAttempts = 3,
            TimeSpan? delay = null)
        {
            delay ??= TimeSpan.FromSeconds(1);
            
            for (int attempt = 1; attempt <= maxAttempts; attempt++)
            {
                try
                {
                    return await operation();
                }
                catch (Exception ex) when (attempt < maxAttempts)
                {
                    Output.WriteLine($"⚠️ Attempt {attempt} failed: {ex.Message}. Retrying...");
                    await Task.Delay(delay.Value, TestCancellation.Token);
                }
            }
            
            // المحاولة الأخيرة - دع الاستثناء يظهر
            return await operation();
        }
        
        /// <summary>
        /// تنظيف مفاتيح Redis المتتبعة
        /// </summary>
        protected virtual async Task CleanupRedisKeysAsync()
        {
            if (!_trackedRedisKeys.Any()) return;
            
            try
            {
                var keys = _trackedRedisKeys.Select(k => (RedisKey)k).ToArray();
                await RedisDatabase.KeyDeleteAsync(keys);
                _trackedRedisKeys.Clear();
                
                Output.WriteLine($"🗑️ Cleaned {keys.Length} Redis keys");
            }
            catch (Exception ex)
            {
                Output.WriteLine($"⚠️ Error cleaning Redis keys: {ex.Message}");
            }
        }
        
        /// <summary>
        /// تتبع مفتاح Redis للتنظيف
        /// </summary>
        protected void TrackRedisKey(string key)
        {
            _trackedRedisKeys.Add(key);
        }
        
        /// <summary>
        /// التحقق من جاهزية الخدمات
        /// </summary>
        protected virtual async Task VerifyServicesReadyAsync()
        {
            // التحقق من Redis
            if (RedisManager != null)
            {
                var isConnected = await WaitForConditionAsync(
                    async () => await RedisManager.IsConnectedAsync(),
                    result => result,
                    TimeSpan.FromSeconds(10)
                );
                
                if (!isConnected)
                {
                    throw new InvalidOperationException("Redis is not ready");
                }
            }
            
            // التحقق من قاعدة البيانات
            if (DbContext != null)
            {
                await DbContext.Database.CanConnectAsync();
            }
        }
        
        /// <summary>
        /// هل يستخدم الاختبار TestContainers
        /// </summary>
        protected virtual bool UseTestContainers()
        {
            // يمكن للفئات المشتقة تخصيص هذا
            return false;
        }
        
        /// <summary>
        /// إنشاء مفتاح Redis معزول للاختبار
        /// </summary>
        protected string GetRedisKey(string key)
        {
            var fullKey = $"{RedisKeyPrefix}{key}";
            TrackRedisKey(fullKey);
            return fullKey;
        }
        
        /// <summary>
        /// انتظار حتى تصبح البيانات متاحة في Redis (Eventually Consistent)
        /// </summary>
        protected async Task<T> WaitForRedisDataAsync<T>(
            Func<Task<T>> getData,
            Func<T, bool> isDataReady,
            TimeSpan? timeout = null)
        {
            timeout ??= TimeSpan.FromSeconds(5);
            
            return await Policy
                .HandleResult<T>(result => !isDataReady(result))
                .WaitAndRetryAsync(
                    retryCount: 50,
                    sleepDurationProvider: _ => TimeSpan.FromMilliseconds(100))
                .ExecuteAsync(getData);
        }
        
        #endregion
    }
    
}
