using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Redis;
using YemenBooking.Infrastructure.Redis.Configuration;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.Entities;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Infrastructure.Repositories;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Services;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.IndexingTests.Tests
{
    /// <summary>
    /// الفئة الأساسية لجميع الاختبارات
    /// توفر الإعدادات المشتركة والوظائف المساعدة
    /// </summary>
    public abstract class TestBase : IClassFixture<TestDatabaseFixture>, IDisposable
    {
        protected readonly TestDatabaseFixture _fixture;
        protected readonly IServiceScope _scope;
        protected readonly YemenBookingDbContext _dbContext;
        protected readonly IIndexingService _indexingService;
        protected readonly ILogger<TestBase> _logger;
        protected readonly ITestOutputHelper _output;
        protected readonly Random _random = new Random();
        private static bool _baseDataInitialized = false;
        private static readonly SemaphoreSlim _initLock = new SemaphoreSlim(1, 1);
        
        // ✅ عداد للتتبع الذكي للتنظيف
        private int _entityCount = 0;
        private const int MAX_ENTITIES_BEFORE_CLEANUP = 50; // رفع العدد إلى 50 بدلاً من 5

        /// <summary>
        /// منشئ الاختبار الأساسي
        /// </summary>
        protected TestBase(TestDatabaseFixture fixture, ITestOutputHelper output)
        {
            _fixture = fixture;
            _output = output;
            _scope = _fixture.ServiceProvider.CreateScope();
            _dbContext = _scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            _indexingService = _scope.ServiceProvider.GetRequiredService<IIndexingService>();
            _logger = _scope.ServiceProvider.GetRequiredService<ILogger<TestBase>>();
            
            // ✅ التهيئة الآمنة بدون حلقات - يتم مرة واحدة فقط
            // ✅ تنفيذ متزامن لتجنب مشاكل DbContext concurrency
            EnsureBaseDataInitializedAsync().GetAwaiter().GetResult();
        }
        
        /// <summary>
        /// إنشاء scope منفصل للعمليات المتزامنة - لتجنب DbContext concurrency
        /// </summary>
        protected IServiceScope CreateIsolatedScope()
        {
            return _fixture.ServiceProvider.CreateScope();
        }
        
        /// <summary>
        /// الحصول على DbContext منفصل للعمليات المتزامنة
        /// </summary>
        protected YemenBookingDbContext GetIsolatedDbContext()
        {
            var scope = CreateIsolatedScope();
            return scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
        }
        
        /// <summary>
        /// الحصول على IIndexingService منفصل للعمليات المتزامنة
        /// </summary>
        protected IIndexingService GetIsolatedIndexingService(IServiceScope scope)
        {
            return scope.ServiceProvider.GetRequiredService<IIndexingService>();
        }
        
        /// <summary>
        /// قراءة كيان بدون tracking - حل احترافي لتجنب DbContext conflicts
        /// </summary>
        protected async Task<T?> GetEntityNoTrackingAsync<T>(Guid id) where T : class
        {
            return await _dbContext.Set<T>()
                .AsNoTracking()
                .FirstOrDefaultAsync(e => EF.Property<Guid>(e, "Id") == id);
        }
        
        /// <summary>
        /// قراءة قائمة كيانات بدون tracking
        /// </summary>
        protected async Task<List<T>> GetEntitiesNoTrackingAsync<T>(System.Linq.Expressions.Expression<Func<T, bool>> predicate) where T : class
        {
            return await _dbContext.Set<T>()
                .AsNoTracking()
                .Where(predicate)
                .ToListAsync();
        }
        
        /// <summary>
        /// انتظار ذكي حتى تكتمل الفهرسة - polling مع timeout بدلاً من delay ثابت
        /// </summary>
        protected async Task<PropertySearchResult> WaitForIndexingAsync(
            PropertySearchRequest searchRequest,
            int expectedMinCount,
            int maxAttempts = 10,
            int delayMs = 500)
        {
            PropertySearchResult? result = null;
            int attempts = 0;
            
            while (attempts < maxAttempts)
            {
                result = await _indexingService.SearchAsync(searchRequest);
                
                if (result?.TotalCount >= expectedMinCount)
                {
                    _output.WriteLine($"  ✅ تم العثور على {result.TotalCount} نتيجة بعد {attempts + 1} محاولة");
                    return result;
                }
                
                attempts++;
                if (attempts < maxAttempts)
                {
                    await Task.Delay(delayMs);
                }
            }
            
            // إذا فشلت جميع المحاولات، أعد آخر نتيجة
            _output.WriteLine($"  ⚠️ تحذير: تم العثور على {result?.TotalCount ?? 0} فقط بعد {attempts} محاولة");
            return result ?? new PropertySearchResult { Properties = new List<PropertySearchItem>(), TotalCount = 0 };
        }
        
        /// <summary>
        /// انتظار ذكي حتى تختفي النتائج (للحذف) - polling مع timeout
        /// </summary>
        protected async Task<bool> WaitForDeletionAsync(
            Guid propertyId,
            int maxAttempts = 10,
            int delayMs = 500)
        {
            int attempts = 0;
            
            while (attempts < maxAttempts)
            {
                var searchRequest = new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 100
                };
                
                var result = await _indexingService.SearchAsync(searchRequest);
                var found = result.Properties.Any(p => p.Id == propertyId.ToString());
                
                if (!found)
                {
                    _output.WriteLine($"  ✅ تم التأكد من حذف العقار بعد {attempts + 1} محاولة");
                    return true;
                }
                
                attempts++;
                if (attempts < maxAttempts)
                {
                    await Task.Delay(delayMs);
                }
            }
            
            _output.WriteLine($"  ⚠️ تحذير: العقار ما زال موجوداً بعد {attempts} محاولة");
            return false;
        }
        
        /// <summary>
        /// تنظيف كاش البحث - لضمان قراءة البيانات الحية من Redis
        /// </summary>
        protected async Task FlushSearchCacheAsync()
        {
            try
            {
                // ✅ استدعاء clear cache من IIndexingService إن كان موجوداً
                var cacheMethod = _indexingService.GetType().GetMethod("ClearSearchCacheAsync");
                if (cacheMethod != null)
                {
                    var task = cacheMethod.Invoke(_indexingService, null) as Task;
                    if (task != null)
                    {
                        await task;
                        _output.WriteLine("  🗑️ تم تنظيف كاش البحث");
                    }
                }
            }
            catch (Exception ex)
            {
                _output.WriteLine($"  ⚠️ تحذير: فشل تنظيف الكاش - {ex.Message}");
            }
        }
        
        /// <summary>
        /// التأكد من تهيئة البيانات الأساسية مرة واحدة فقط
        /// </summary>
        private async Task EnsureBaseDataInitializedAsync()
        {
            if (_baseDataInitialized) return;
            
            await _initLock.WaitAsync();
            try
            {
                if (_baseDataInitialized) return;
                
                await TestDataHelper.EnsureAllBaseDataAsync(_dbContext);
                _baseDataInitialized = true;
            }
            finally
            {
                _initLock.Release();
            }
        }

        /// <summary>
        /// إنشاء عقار اختباري
        /// </summary>
        protected async Task<Property> CreateTestPropertyAsync(
            string name = null,
            string city = null,
            Guid? typeId = null,
            decimal minPrice = 100,
            bool isActive = true,
            bool isApproved = true,
            bool createUnits = true)
        {
            // استخدام TestDataHelper لإنشاء عقار صحيح
            var property = TestDataHelper.CreateValidProperty(
                name: name ?? $"عقار اختباري {_random.Next(1000, 9999)}",
                city: city ?? GetRandomCity(),
                typeId: typeId ?? GetRandomPropertyType()
            );
            
            property.IsActive = isActive;
            property.IsApproved = isApproved;

            // ضمان وجود المدينة لتجنب انتهاك FK Cities.City
            var cityExists = await _dbContext.Cities
                .AsNoTracking()  // ✅ عدم تتبع الاستعلام
                .AnyAsync(c => c.Name == property.City);
                
            if (!cityExists)
            {
                var newCity = new YemenBooking.Core.Entities.City { Name = property.City, Country = "اليمن" };
                _dbContext.Cities.Add(newCity);
                await _dbContext.SaveChangesAsync();
            }

            _dbContext.Properties.Add(property);
            await _dbContext.SaveChangesAsync();

            // ✅ إنشاء وحدات فقط إذا طُلِب ذلك
            if (createUnits)
            {
                await CreateTestUnitsForPropertyAsync(property.Id, _random.Next(1, 3));
            }

            // ✅ العقار جاهز للاستخدام مباشرة - متتبع في DbContext
            return property;
        }

        /// <summary>
        /// إنشاء وحدات اختبارية للعقار
        /// </summary>
        protected async Task CreateTestUnitsForPropertyAsync(Guid propertyId, int count = 2)
        {
            // ✅ حد أقصى 3 وحدات لتجنب التراكم الزائد
            count = Math.Min(count, 3);
            
            // اختر نوع وحدة موجود لضمان سلامة FK
            var existingUnitTypeId = await _dbContext.UnitTypes
                .AsNoTracking()  // ✅ عدم تتبع الاستعلام
                .Select(ut => ut.Id)
                .FirstOrDefaultAsync();
                
            if (existingUnitTypeId == Guid.Empty)
            {
                // ضمان تهيئة الأنواع الأساسية في حال لم تكن موجودة لأي سبب
                await TestDataHelper.EnsureAllBaseDataAsync(_dbContext);
                existingUnitTypeId = await _dbContext.UnitTypes
                    .AsNoTracking()
                    .Select(ut => ut.Id)
                    .FirstOrDefaultAsync();
            }

            var existingCount = await _dbContext.Units
                .AsNoTracking()  // ✅ عدم تتبع الاستعلام
                .CountAsync(u => u.PropertyId == propertyId);
                
            var units = new List<Unit>();
            for (int i = 0; i < count; i++)
            {
                // استخدام TestDataHelper لإنشاء وحدة صحيحة
                var uniqueName = $"وحدة {existingCount + i + 1}-{propertyId.ToString().Substring(0, 8)}";
                var unit = TestDataHelper.CreateValidUnit(propertyId, uniqueName);
                if (existingUnitTypeId != Guid.Empty)
                {
                    unit.UnitTypeId = existingUnitTypeId;
                }

                units.Add(unit);
            }

            // ✅ إضافة دفعة واحدة بدلاً من حلقة
            if (units.Any())
            {
                _dbContext.Units.AddRange(units);
                await _dbContext.SaveChangesAsync();
            }
        }

        /// <summary>
        /// إنشاء بيانات اختبار شاملة
        /// </summary>
        protected async Task<List<Property>> CreateComprehensiveTestDataAsync()
        {
            var properties = new List<Property>();

            // إنشاء عقارات في مدن مختلفة
            var cities = new[] { "صنعاء", "عدن", "تعز", "الحديدة", "إب" };
            var types = GetAllPropertyTypes();

            int propertyCount = 0;
            foreach (var city in cities)
            {
                foreach (var type in types)
                {
                    var property = await CreateTestPropertyAsync(
                        name: $"{GetPropertyTypeName(type)} في {city}",
                        city: city,
                        typeId: type,
                        minPrice: _random.Next(50, 1000),
                        isActive: true,
                        isApproved: true
                    );
                    properties.Add(property);
                    
                    propertyCount++;
                    _entityCount++;
                    
                    // ✅ تنظيف ChangeTracker بشكل ذكي فقط عند الضرورة
                    if (_entityCount >= MAX_ENTITIES_BEFORE_CLEANUP)
                    {
                        await SmartCleanupAsync();
                        _entityCount = 0;
                    }
                }
            }

            // ✅ تنظيف نهائي ذكي
            await SmartCleanupAsync();
            
            // ✅ إعادة تحميل العقارات بدون تتبع
            var propertyIds = properties.Select(p => p.Id).ToList();
            return await _dbContext.Properties
                .AsNoTracking()
                .Where(p => propertyIds.Contains(p.Id))
                .ToListAsync();
        }

        /// <summary>
        /// تنظيف البيانات الاختبارية
        /// </summary>
        protected async Task CleanupTestDataAsync()
        {
            // حذف جميع البيانات الاختبارية
            _dbContext.Units.RemoveRange(_dbContext.Units);
            _dbContext.Properties.RemoveRange(_dbContext.Properties);
            await _dbContext.SaveChangesAsync();

            // تنظيف Redis
            // var db = _redisManager.GetDatabase();
            // await db.ExecuteAsync("FLUSHDB");
        }

        /// <summary>
        /// التحقق من نتائج البحث
        /// </summary>
        protected void AssertSearchResults(
            PropertySearchResult result,
            int? expectedMinCount = null,
            int? expectedMaxCount = null,
            string expectedCity = null,
            Guid? expectedType = null,
            decimal? expectedMinPrice = null,
            decimal? expectedMaxPrice = null)
        {
            Assert.NotNull(result);
            Assert.NotNull(result.Properties);

            if (expectedMinCount.HasValue)
                Assert.True(result.TotalCount >= expectedMinCount.Value,
                    $"العدد الفعلي {result.TotalCount} أقل من المتوقع {expectedMinCount}");

            if (expectedMaxCount.HasValue)
                Assert.True(result.TotalCount <= expectedMaxCount.Value,
                    $"العدد الفعلي {result.TotalCount} أكثر من المتوقع {expectedMaxCount}");

            if (!string.IsNullOrEmpty(expectedCity))
                Assert.All(result.Properties, p =>
                    Assert.Equal(expectedCity, p.City, StringComparer.OrdinalIgnoreCase));

            if (expectedType.HasValue)
                Assert.All(result.Properties, p =>
                    Assert.Equal(expectedType.Value.ToString(), p.PropertyType));

            if (expectedMinPrice.HasValue)
                Assert.All(result.Properties, p =>
                    Assert.True(p.MinPrice >= expectedMinPrice.Value));

            if (expectedMaxPrice.HasValue)
                Assert.All(result.Properties, p =>
                    Assert.True(p.MinPrice <= expectedMaxPrice.Value));
        }

        /// <summary>
        /// قياس زمن التنفيذ
        /// </summary>
        protected async Task<(T Result, long ElapsedMs)> MeasureExecutionTimeAsync<T>(
            Func<Task<T>> action, 
            string operationName)
        {
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            var result = await action();
            stopwatch.Stop();

            _output.WriteLine($"⏱️ {operationName}: {stopwatch.ElapsedMilliseconds}ms");
            
            return (result, stopwatch.ElapsedMilliseconds);
        }

        #region Helper Methods

        private string GetRandomCity()
        {
            var cities = new[] { "صنعاء", "عدن", "تعز", "الحديدة", "إب", "ذمار", "المكلا" };
            return cities[_random.Next(cities.Length)];
        }

        private Guid GetRandomPropertyType()
        {
            var types = GetAllPropertyTypes();
            return types[_random.Next(types.Length)];
        }

        private Guid GetRandomUnitType()
        {
            // معرفات أنواع الوحدات الافتراضية
            var types = new[]
            {
                Guid.Parse("20000000-0000-0000-0000-000000000001"), // غرفة مفردة
                Guid.Parse("20000000-0000-0000-0000-000000000002"), // غرفة مزدوجة
                Guid.Parse("20000000-0000-0000-0000-000000000003"), // جناح
                Guid.Parse("20000000-0000-0000-0000-000000000004"), // شقة
            };
            return types[_random.Next(types.Length)];
        }

        private Guid[] GetAllPropertyTypes()
        {
            return new[]
            {
                Guid.Parse("30000000-0000-0000-0000-000000000001"), // منتجع
                Guid.Parse("30000000-0000-0000-0000-000000000002"), // شقق مفروشة
                Guid.Parse("30000000-0000-0000-0000-000000000003"), // فندق
                Guid.Parse("30000000-0000-0000-0000-000000000004"), // فيلا
                Guid.Parse("30000000-0000-0000-0000-000000000005"), // شاليه
            };
        }

        private string GetPropertyTypeName(Guid typeId)
        {
            var typeNames = new Dictionary<string, string>
            {
                ["30000000-0000-0000-0000-000000000001"] = "منتجع",
                ["30000000-0000-0000-0000-000000000002"] = "شقق مفروشة",
                ["30000000-0000-0000-0000-000000000003"] = "فندق",
                ["30000000-0000-0000-0000-000000000004"] = "فيلا",
                ["30000000-0000-0000-0000-000000000005"] = "شاليه",
            };

            return typeNames.GetValueOrDefault(typeId.ToString(), "عقار");
        }

        #endregion

        /// <summary>
        /// تنظيف ذكي لـ ChangeTracker مع الحفاظ على البيانات المهمة
        /// </summary>
        protected async Task SmartCleanupAsync()
        {
            // حفظ التغييرات المعلقة أولاً
            if (_dbContext.ChangeTracker.HasChanges())
            {
                await _dbContext.SaveChangesAsync();
            }
            
            // تنظيف الكيانات غير المعدلة فقط
            var entriesToClear = _dbContext.ChangeTracker.Entries()
                .Where(e => e.State == EntityState.Unchanged || e.State == EntityState.Detached)
                .ToList();
                
            foreach (var entry in entriesToClear)
            {
                entry.State = EntityState.Detached;
            }
        }
        
        public virtual void Dispose()
        {
            // ✅ الحل الاحترافي: تنظيف شامل وآمن
            try
            {
                // 1. حفظ أي تغييرات معلقة
                if (_dbContext?.ChangeTracker?.HasChanges() == true)
                {
                    try
                    {
                        _dbContext.SaveChanges();
                    }
                    catch { /* تجاهل أخطاء الحفظ عند التنظيف */ }
                }
                
                // 2. تنظيف كامل للـ ChangeTracker
                _dbContext?.ChangeTracker?.Clear();
                
                // 3. إزالة tracking من جميع الكيانات
                var entries = _dbContext?.ChangeTracker?.Entries()?.ToList();
                if (entries != null)
                {
                    foreach (var entry in entries)
                    {
                        entry.State = EntityState.Detached;
                    }
                }
            }
            catch (Exception ex)
            {
                _output?.WriteLine($"⚠️ تحذير أثناء التنظيف: {ex.Message}");
            }
            finally
            {
                // 4. تحرير الموارد
                _scope?.Dispose();
            }
        }
    }
}
