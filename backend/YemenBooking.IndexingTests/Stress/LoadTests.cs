using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using YemenBooking.IndexingTests.Infrastructure.Builders;

namespace YemenBooking.IndexingTests.Stress
{
    /// <summary>
    /// اختبارات الضغط والحمل
    /// تختبر النظام تحت ضغط عالٍ
    /// </summary>
    [Collection("TestContainers")]
    public class LoadTests : TestBase
    {
        private readonly TestContainerFixture _containers;
        private readonly SemaphoreSlim _rateLimiter;
        
        public LoadTests(TestContainerFixture containers, ITestOutputHelper output) 
            : base(output)
        {
            _containers = containers;
            // حد أقصى للعمليات المتزامنة
            _rateLimiter = new SemaphoreSlim(100, 100);
        }
        
        protected override async Task ConfigureServicesAsync(IServiceCollection services)
        {
            // تكوين مشابه لـ EndToEndSearchTests
            await base.ConfigureServicesAsync(services);
        }
        
        [Fact]
        public async Task LoadTest_ConcurrentIndexing_ShouldHandleHighLoad()
        {
            // Arrange
            const int totalProperties = 100;
            const int concurrentOperations = 20;
            
            Output.WriteLine($"🚀 Starting load test with {totalProperties} properties");
            Output.WriteLine($"   Concurrent operations: {concurrentOperations}");
            
            var properties = TestDataBuilder.BatchProperties(totalProperties, TestId);
            var metrics = new LoadTestMetrics();
            
            // Act
            var stopwatch = Stopwatch.StartNew();
            var tasks = new List<Task>();
            
            using (var semaphore = new SemaphoreSlim(concurrentOperations))
            {
                foreach (var property in properties)
                {
                    tasks.Add(Task.Run(async () =>
                    {
                        await semaphore.WaitAsync();
                        try
                        {
                            var operationStopwatch = Stopwatch.StartNew();
                            
                            using var scope = CreateIsolatedScope();
                            var service = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                            
                            var success = await service.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
                            
                            operationStopwatch.Stop();
                            
                            if (success)
                                metrics.RecordSuccess(operationStopwatch.ElapsedMilliseconds);
                            else
                                metrics.RecordFailure(operationStopwatch.ElapsedMilliseconds);
                        }
                        catch (Exception ex)
                        {
                            metrics.RecordError(ex);
                        }
                        finally
                        {
                            semaphore.Release();
                        }
                    }));
                }
                
                await Task.WhenAll(tasks);
            }
            
            stopwatch.Stop();
            
            // Assert & Report
            Output.WriteLine($"✅ Load test completed in {stopwatch.ElapsedMilliseconds}ms");
            Output.WriteLine($"📊 Metrics:");
            Output.WriteLine($"   - Total operations: {metrics.TotalOperations}");
            Output.WriteLine($"   - Successful: {metrics.SuccessfulOperations} ({metrics.SuccessRate:P})");
            Output.WriteLine($"   - Failed: {metrics.FailedOperations}");
            Output.WriteLine($"   - Errors: {metrics.Errors}");
            Output.WriteLine($"   - Average latency: {metrics.AverageLatency:F2}ms");
            Output.WriteLine($"   - Min latency: {metrics.MinLatency}ms");
            Output.WriteLine($"   - Max latency: {metrics.MaxLatency}ms");
            Output.WriteLine($"   - P95 latency: {metrics.P95Latency}ms");
            Output.WriteLine($"   - P99 latency: {metrics.P99Latency}ms");
            Output.WriteLine($"   - Throughput: {metrics.Throughput:F2} ops/sec");
            
            // التحقق من معايير النجاح
            metrics.SuccessRate.Should().BeGreaterThan(0.95, "Success rate should be > 95%");
            metrics.AverageLatency.Should().BeLessThan(1000, "Average latency should be < 1 second");
            metrics.P95Latency.Should().BeLessThan(2000, "P95 latency should be < 2 seconds");
        }
        
        [Fact]
        public async Task LoadTest_ConcurrentSearch_ShouldHandleHighQueryLoad()
        {
            // Arrange
            const int numberOfProperties = 50;
            const int numberOfSearches = 200;
            const int concurrentSearches = 50;
            
            Output.WriteLine($"🚀 Starting search load test");
            Output.WriteLine($"   Properties: {numberOfProperties}");
            Output.WriteLine($"   Total searches: {numberOfSearches}");
            Output.WriteLine($"   Concurrent searches: {concurrentSearches}");
            
            // إنشاء وفهرسة العقارات
            var properties = TestDataBuilder.BatchProperties(numberOfProperties, TestId);
            foreach (var property in properties)
            {
                await IndexingService.OnPropertyCreatedAsync(property.Id);
            }
            
            // إنشاء طلبات بحث متنوعة
            var searchRequests = GenerateVariedSearchRequests(numberOfSearches);
            var metrics = new LoadTestMetrics();
            
            // Act
            var stopwatch = Stopwatch.StartNew();
            var tasks = new List<Task>();
            
            using (var semaphore = new SemaphoreSlim(concurrentSearches))
            {
                foreach (var request in searchRequests)
                {
                    tasks.Add(Task.Run(async () =>
                    {
                        await semaphore.WaitAsync();
                        try
                        {
                            var operationStopwatch = Stopwatch.StartNew();
                            
                            using var scope = CreateIsolatedScope();
                            var service = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                            
                            var result = await service.SearchAsync(request, TestCancellation.Token);
                            
                            operationStopwatch.Stop();
                            
                            if (result != null)
                                metrics.RecordSuccess(operationStopwatch.ElapsedMilliseconds);
                            else
                                metrics.RecordFailure(operationStopwatch.ElapsedMilliseconds);
                        }
                        catch (Exception ex)
                        {
                            metrics.RecordError(ex);
                        }
                        finally
                        {
                            semaphore.Release();
                        }
                    }));
                }
                
                await Task.WhenAll(tasks);
            }
            
            stopwatch.Stop();
            
            // Report
            Output.WriteLine($"✅ Search load test completed in {stopwatch.ElapsedMilliseconds}ms");
            Output.WriteLine($"📊 Search Metrics:");
            Output.WriteLine($"   - Total searches: {metrics.TotalOperations}");
            Output.WriteLine($"   - Successful: {metrics.SuccessfulOperations} ({metrics.SuccessRate:P})");
            Output.WriteLine($"   - Average latency: {metrics.AverageLatency:F2}ms");
            Output.WriteLine($"   - P95 latency: {metrics.P95Latency}ms");
            Output.WriteLine($"   - Throughput: {metrics.Throughput:F2} searches/sec");
            
            // Assert
            metrics.SuccessRate.Should().BeGreaterThan(0.99, "Search success rate should be > 99%");
            metrics.AverageLatency.Should().BeLessThan(200, "Average search latency should be < 200ms");
        }
        
        [Fact]
        public async Task StressTest_MixedOperations_ShouldHandleChaos()
        {
            // Arrange
            Output.WriteLine($"🚀 Starting chaos/stress test");
            
            const int duration = 10; // seconds
            const int operationsPerSecond = 50;
            
            var metrics = new LoadTestMetrics();
            var cancellationTokenSource = new CancellationTokenSource(TimeSpan.FromSeconds(duration));
            
            // Act
            var tasks = new List<Task>
            {
                // مولد عمليات الإضافة
                GenerateContinuousOperations(
                    () => CreateAndIndexProperty(),
                    operationsPerSecond / 3,
                    cancellationTokenSource.Token,
                    metrics,
                    "Create"),
                
                // مولد عمليات التحديث
                GenerateContinuousOperations(
                    () => UpdateRandomProperty(),
                    operationsPerSecond / 3,
                    cancellationTokenSource.Token,
                    metrics,
                    "Update"),
                
                // مولد عمليات البحث
                GenerateContinuousOperations(
                    () => SearchProperties(),
                    operationsPerSecond / 3,
                    cancellationTokenSource.Token,
                    metrics,
                    "Search")
            };
            
            await Task.WhenAll(tasks);
            
            // Report
            Output.WriteLine($"✅ Stress test completed");
            Output.WriteLine($"📊 Stress Test Metrics:");
            Output.WriteLine($"   - Total operations: {metrics.TotalOperations}");
            Output.WriteLine($"   - Success rate: {metrics.SuccessRate:P}");
            Output.WriteLine($"   - Average latency: {metrics.AverageLatency:F2}ms");
            Output.WriteLine($"   - Errors: {metrics.Errors}");
            
            // Assert
            metrics.SuccessRate.Should().BeGreaterThan(0.90, "Success rate under stress should be > 90%");
        }
        
        [Fact]
        public async Task SpikeTest_SuddenLoadIncrease_ShouldRecover()
        {
            // Arrange
            Output.WriteLine($"🚀 Starting spike test");
            
            var metrics = new LoadTestMetrics();
            
            // Act
            // Phase 1: Normal load (10 ops/sec for 5 seconds)
            Output.WriteLine("Phase 1: Normal load");
            await GenerateLoadForDuration(10, 5, metrics);
            
            // Phase 2: Spike (100 ops/sec for 5 seconds)
            Output.WriteLine("Phase 2: Spike load");
            await GenerateLoadForDuration(100, 5, metrics);
            
            // Phase 3: Return to normal (10 ops/sec for 5 seconds)
            Output.WriteLine("Phase 3: Recovery");
            await GenerateLoadForDuration(10, 5, metrics);
            
            // Report
            Output.WriteLine($"✅ Spike test completed");
            Output.WriteLine($"📊 Spike Test Metrics:");
            Output.WriteLine($"   - Total operations: {metrics.TotalOperations}");
            Output.WriteLine($"   - Success rate: {metrics.SuccessRate:P}");
            Output.WriteLine($"   - Average latency: {metrics.AverageLatency:F2}ms");
            
            // Assert
            metrics.SuccessRate.Should().BeGreaterThan(0.85, "System should handle spikes with >85% success");
        }
        
        #region Helper Methods
        
        private List<PropertySearchRequest> GenerateVariedSearchRequests(int count)
        {
            var requests = new List<PropertySearchRequest>();
            
            for (int i = 0; i < count; i++)
            {
                // تنويع أنواع البحث
                var requestType = i % 5;
                
                var request = requestType switch
                {
                    0 => TestDataBuilder.SimpleSearchRequest(),
                    1 => TestDataBuilder.TextSearchRequest($"test_{i}"),
                    2 => TestDataBuilder.FilteredSearchRequest(city: "صنعاء"),
                    3 => TestDataBuilder.FilteredSearchRequest(minPrice: 100, maxPrice: 500),
                    _ => TestDataBuilder.ComplexSearchRequest()
                };
                
                requests.Add(request);
            }
            
            return requests;
        }
        
        private async Task GenerateContinuousOperations(
            Func<Task> operation,
            int operationsPerSecond,
            CancellationToken cancellationToken,
            LoadTestMetrics metrics,
            string operationType)
        {
            var delay = TimeSpan.FromMilliseconds(1000.0 / operationsPerSecond);
            
            while (!cancellationToken.IsCancellationRequested)
            {
                var task = Task.Run(async () =>
                {
                    var stopwatch = Stopwatch.StartNew();
                    try
                    {
                        await operation();
                        metrics.RecordSuccess(stopwatch.ElapsedMilliseconds);
                    }
                    catch (Exception ex)
                    {
                        metrics.RecordError(ex);
                    }
                });
                
                await Task.Delay(delay, cancellationToken);
            }
        }
        
        private async Task<bool> CreateAndIndexProperty()
        {
            var property = TestDataBuilder.SimpleProperty(TestId);
            return await IndexingService.OnPropertyCreatedAsync(property.Id);
        }
        
        private async Task<bool> UpdateRandomProperty()
        {
            var propertyId = Guid.NewGuid(); // في الواقع، يجب اختيار من قائمة موجودة
            return await IndexingService.OnPropertyUpdatedAsync(propertyId);
        }
        
        private async Task<PropertySearchResult> SearchProperties()
        {
            var request = TestDataBuilder.SimpleSearchRequest();
            return await IndexingService.SearchAsync(request);
        }
        
        private async Task GenerateLoadForDuration(
            int operationsPerSecond,
            int durationSeconds,
            LoadTestMetrics metrics)
        {
            var cancellationTokenSource = new CancellationTokenSource(TimeSpan.FromSeconds(durationSeconds));
            
            await GenerateContinuousOperations(
                () => CreateAndIndexProperty(),
                operationsPerSecond,
                cancellationTokenSource.Token,
                metrics,
                "Mixed");
        }
        
        #endregion
    }
    
    /// <summary>
    /// فئة لتتبع مقاييس الأداء
    /// </summary>
    public class LoadTestMetrics
    {
        private readonly object _lock = new object();
        private readonly List<long> _latencies = new();
        private readonly List<Exception> _exceptions = new();
        private int _successCount;
        private int _failureCount;
        private readonly Stopwatch _totalTime = Stopwatch.StartNew();
        
        public int TotalOperations => _successCount + _failureCount;
        public int SuccessfulOperations => _successCount;
        public int FailedOperations => _failureCount;
        public int Errors => _exceptions.Count;
        public double SuccessRate => TotalOperations > 0 ? (double)_successCount / TotalOperations : 0;
        
        public double AverageLatency
        {
            get
            {
                lock (_lock)
                {
                    return _latencies.Any() ? _latencies.Average() : 0;
                }
            }
        }
        
        public long MinLatency
        {
            get
            {
                lock (_lock)
                {
                    return _latencies.Any() ? _latencies.Min() : 0;
                }
            }
        }
        
        public long MaxLatency
        {
            get
            {
                lock (_lock)
                {
                    return _latencies.Any() ? _latencies.Max() : 0;
                }
            }
        }
        
        public long P95Latency => GetPercentile(95);
        public long P99Latency => GetPercentile(99);
        
        public double Throughput => TotalOperations / _totalTime.Elapsed.TotalSeconds;
        
        public void RecordSuccess(long latencyMs)
        {
            lock (_lock)
            {
                _successCount++;
                _latencies.Add(latencyMs);
            }
        }
        
        public void RecordFailure(long latencyMs)
        {
            lock (_lock)
            {
                _failureCount++;
                _latencies.Add(latencyMs);
            }
        }
        
        public void RecordError(Exception ex)
        {
            lock (_lock)
            {
                _failureCount++;
                _exceptions.Add(ex);
            }
        }
        
        private long GetPercentile(int percentile)
        {
            lock (_lock)
            {
                if (!_latencies.Any())
                    return 0;
                
                var sorted = _latencies.OrderBy(l => l).ToList();
                var index = (int)Math.Ceiling(sorted.Count * (percentile / 100.0)) - 1;
                return sorted[Math.Max(0, Math.Min(index, sorted.Count - 1))];
            }
        }
    }
}
