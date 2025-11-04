using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Configs;
using BenchmarkDotNet.Jobs;
using BenchmarkDotNet.Order;
using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using YemenBooking.IndexingTests.Infrastructure.Builders;

namespace YemenBooking.IndexingTests.Performance
{
    /// <summary>
    /// اختبارات أداء البحث
    /// يستخدم BenchmarkDotNet لقياس الأداء بدقة
    /// </summary>
    [MemoryDiagnoser]
    [ThreadingDiagnoser]
    [SimpleJob(RuntimeMoniker.Net80)]
    [Orderer(SummaryOrderPolicy.FastestToSlowest)]
    [Config(typeof(BenchmarkConfig))]
    public class SearchBenchmarks
    {
        private IIndexingService _indexingService;
        private List<PropertySearchRequest> _searchRequests;
        private TestContainerFixture _containers;
        private IServiceProvider _serviceProvider;

        [GlobalSetup]
        public async Task Setup()
        {
            // إعداد الحاويات
            _containers = new TestContainerFixture();
            await _containers.InitializeAsync();

            // إعداد الخدمات
            var services = new ServiceCollection();
            ConfigureServices(services);
            _serviceProvider = services.BuildServiceProvider();
            
            _indexingService = _serviceProvider.GetRequiredService<IIndexingService>();

            // إعداد البيانات الاختبارية
            await PrepareTestDataAsync();
            
            // إعداد طلبات البحث المختلفة
            PrepareSearchRequests();
        }

        [GlobalCleanup]
        public async Task Cleanup()
        {
            _serviceProvider?.Dispose();
            await _containers.DisposeAsync();
        }

        private void ConfigureServices(IServiceCollection services)
        {
            // تكوين الخدمات المطلوبة
            services.AddSingleton(_containers);
            // إضافة باقي الخدمات...
        }

        private async Task PrepareTestDataAsync()
        {
            // إنشاء بيانات اختبارية متنوعة
            var properties = new List<Property>();
            
            for (int i = 0; i < 1000; i++)
            {
                var property = TestDataBuilder.CompleteProperty($"bench_{i}");
                properties.Add(property);
            }

            // فهرسة البيانات
            foreach (var property in properties)
            {
                await _indexingService.OnPropertyCreatedAsync(property.Id);
            }
        }

        private void PrepareSearchRequests()
        {
            _searchRequests = new List<PropertySearchRequest>
            {
                // بحث بسيط
                new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 20
                },
                
                // بحث بنص
                new PropertySearchRequest
                {
                    SearchText = "شقة",
                    PageNumber = 1,
                    PageSize = 20
                },
                
                // بحث بفلاتر متعددة
                new PropertySearchRequest
                {
                    City = "صنعاء",
                    MinPrice = 100,
                    MaxPrice = 500,
                    PropertyTypeId = 1,
                    PageNumber = 1,
                    PageSize = 20
                },
                
                // بحث معقد
                new PropertySearchRequest
                {
                    SearchText = "فيلا",
                    City = "عدن",
                    MinPrice = 500,
                    MaxPrice = 2000,
                    PropertyTypeId = 2,
                    Amenities = new List<int> { 1, 2, 3 },
                    CheckInDate = DateTime.Now.AddDays(7),
                    CheckOutDate = DateTime.Now.AddDays(14),
                    PageNumber = 1,
                    PageSize = 50
                }
            };
        }

        #region Benchmarks

        [Benchmark(Baseline = true)]
        public async Task<PropertySearchResult> SimpleSearch()
        {
            return await _indexingService.SearchAsync(_searchRequests[0]);
        }

        [Benchmark]
        public async Task<PropertySearchResult> TextSearch()
        {
            return await _indexingService.SearchAsync(_searchRequests[1]);
        }

        [Benchmark]
        public async Task<PropertySearchResult> FilteredSearch()
        {
            return await _indexingService.SearchAsync(_searchRequests[2]);
        }

        [Benchmark]
        public async Task<PropertySearchResult> ComplexSearch()
        {
            return await _indexingService.SearchAsync(_searchRequests[3]);
        }

        [Benchmark]
        [Arguments(1)]
        [Arguments(10)]
        [Arguments(100)]
        public async Task ConcurrentSearches(int concurrentCount)
        {
            var tasks = new Task<PropertySearchResult>[concurrentCount];
            
            for (int i = 0; i < concurrentCount; i++)
            {
                var request = _searchRequests[i % _searchRequests.Count];
                tasks[i] = _indexingService.SearchAsync(request);
            }
            
            await Task.WhenAll(tasks);
        }

        [Benchmark]
        [Arguments(10)]
        [Arguments(20)]
        [Arguments(50)]
        [Arguments(100)]
        public async Task<PropertySearchResult> SearchWithVariablePageSize(int pageSize)
        {
            var request = new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = pageSize
            };
            
            return await _indexingService.SearchAsync(request);
        }

        #endregion

        /// <summary>
        /// تكوين BenchmarkDotNet
        /// </summary>
        private class BenchmarkConfig : ManualConfig
        {
            public BenchmarkConfig()
            {
                WithOptions(ConfigOptions.DisableOptimizationsValidator);
                AddJob(Job.Default
                    .WithWarmupCount(3)
                    .WithIterationCount(10)
                    .WithLaunchCount(1));
            }
        }
    }
}
