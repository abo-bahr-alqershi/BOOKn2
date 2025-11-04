using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Jobs;
// using BenchmarkDotNet.Diagnostics.Windows.Configs; // Not available in Linux
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.Entities;
using YemenBooking.IndexingTests.Infrastructure.Builders;


namespace YemenBooking.IndexingTests.Performance
{
    /// <summary>
    /// قياس أداء عمليات الفهرسة
    /// </summary>
    [MemoryDiagnoser]
    [ThreadingDiagnoser]
    [SimpleJob(RuntimeMoniker.Net80)]
    [MinColumn, MaxColumn, MeanColumn, MedianColumn]
    public class IndexingBenchmarks
    {
        private IServiceProvider _serviceProvider;
        private IIndexingService _indexingService;
        private YemenBookingDbContext _dbContext;
        private List<Property> _properties;
        private List<Guid> _propertyIds;
        
        [Params(1, 10, 50, 100)]
        public int PropertyCount { get; set; }
        
        [GlobalSetup]
        public void Setup()
        {
            // إعداد الخدمات
            var services = new ServiceCollection();
            
            // استخدام In-Memory Database للاختبارات
            services.AddDbContext<YemenBookingDbContext>(options =>
            {
                options.UseInMemoryDatabase($"BenchmarkDb_{Guid.NewGuid()}");
                options.EnableSensitiveDataLogging();
            });
            
            // تسجيل الخدمات المطلوبة
            services.AddScoped<IIndexingService, MockIndexingService>();
            services.AddLogging();
            
            _serviceProvider = services.BuildServiceProvider();
            _indexingService = _serviceProvider.GetRequiredService<IIndexingService>();
            _dbContext = _serviceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // إنشاء البيانات الاختبارية
            PrepareTestData();
        }
        
        private void PrepareTestData()
        {
            _properties = new List<Property>();
            _propertyIds = new List<Guid>();
            
            for (int i = 0; i < PropertyCount; i++)
            {
                var property = TestDataBuilder.CompleteProperty($"benchmark_{i}");
                _properties.Add(property);
                _propertyIds.Add(property.Id);
            }
            
            // حفظ في قاعدة البيانات
            _dbContext.Properties.AddRange(_properties);
            _dbContext.SaveChanges();
        }
        
        [GlobalCleanup]
        public void Cleanup()
        {
            _dbContext?.Dispose();
            (_serviceProvider as IDisposable)?.Dispose();
        }
        
        /// <summary>
        /// قياس أداء فهرسة عقار واحد
        /// </summary>
        [Benchmark(Baseline = true)]
        public async Task IndexSingleProperty()
        {
            if (_propertyIds.Any())
            {
                await _indexingService.OnPropertyCreatedAsync(_propertyIds.First());
            }
        }
        
        /// <summary>
        /// قياس أداء فهرسة عدة عقارات بالتتابع
        /// </summary>
        [Benchmark]
        public async Task IndexMultiplePropertiesSequential()
        {
            foreach (var propertyId in _propertyIds)
            {
                await _indexingService.OnPropertyCreatedAsync(propertyId);
            }
        }
        
        /// <summary>
        /// قياس أداء فهرسة عدة عقارات بالتوازي
        /// </summary>
        [Benchmark]
        public async Task IndexMultiplePropertiesParallel()
        {
            var tasks = _propertyIds.Select(id => 
                _indexingService.OnPropertyCreatedAsync(id)
            );
            
            await Task.WhenAll(tasks);
        }
        
        /// <summary>
        /// قياس أداء فهرسة بالدفعات
        /// </summary>
        [Benchmark]
        public async Task IndexPropertiesBatched()
        {
            const int batchSize = 10;
            var batches = _propertyIds
                .Select((id, index) => new { id, index })
                .GroupBy(x => x.index / batchSize)
                .Select(g => g.Select(x => x.id).ToList());
            
            foreach (var batch in batches)
            {
                var tasks = batch.Select(id => 
                    _indexingService.OnPropertyCreatedAsync(id)
                );
                await Task.WhenAll(tasks);
            }
        }
        
        /// <summary>
        /// قياس أداء تحديث الفهرس
        /// </summary>
        [Benchmark]
        public async Task UpdatePropertyIndex()
        {
            if (_propertyIds.Any())
            {
                await _indexingService.OnPropertyUpdatedAsync(_propertyIds.First());
            }
        }
        
        /// <summary>
        /// قياس أداء حذف من الفهرس
        /// </summary>
        [Benchmark]
        public async Task RemovePropertyFromIndex()
        {
            if (_propertyIds.Any())
            {
                await _indexingService.OnPropertyDeletedAsync(_propertyIds.First());
            }
        }
    }
    
    /// <summary>
    /// Mock implementation للاختبارات
    /// </summary>
    internal class MockIndexingService : IIndexingService
    {
        public Task OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            // محاكاة عملية الفهرسة
            return Task.CompletedTask;
        }
        
        public Task OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            // محاكاة عملية التحديث
            return Task.CompletedTask;
        }
        
        public Task OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            // محاكاة عملية الحذف
            return Task.CompletedTask;
        }
        
        public Task<Core.Indexing.Models.PropertySearchResult> SearchAsync(
            Core.Indexing.Models.PropertySearchRequest request,
            CancellationToken cancellationToken = default)
        {
            // محاكاة عملية البحث
            return Task.FromResult(new Core.Indexing.Models.PropertySearchResult
            {
                Properties = new List<Core.Indexing.Models.PropertySearchItem>(),
                TotalCount = 0,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalPages = 0
            });
        }
        
        public Task OnUnitCreatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            return Task.CompletedTask;
        }
        
        public Task OnUnitUpdatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            return Task.CompletedTask;
        }
        
        public Task OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            return Task.CompletedTask;
        }
        
        public Task OnAvailabilityChangedAsync(Guid unitId, Guid propertyId, List<(DateTime Start, DateTime End)> availableRanges, CancellationToken cancellationToken = default)
        {
            return Task.CompletedTask;
        }
        
        public Task OnPricingRuleChangedAsync(Guid unitId, Guid propertyId, List<PricingRule> pricingRules, CancellationToken cancellationToken = default)
        {
            return Task.CompletedTask;
        }
        
        public Task OnDynamicFieldChangedAsync(Guid propertyId, string fieldName, string fieldValue, bool isAdd, CancellationToken cancellationToken = default)
        {
            return Task.CompletedTask;
        }
        
        public Task OptimizeDatabaseAsync()
        {
            return Task.CompletedTask;
        }
        
        public Task RebuildIndexAsync(CancellationToken cancellationToken = default)
        {
            return Task.CompletedTask;
        }
    }
}
