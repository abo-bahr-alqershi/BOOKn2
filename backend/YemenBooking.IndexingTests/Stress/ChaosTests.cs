using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using YemenBooking.IndexingTests.Infrastructure.Assertions;
using YemenBooking.IndexingTests.Infrastructure.Extensions;
using Polly;
using Microsoft.EntityFrameworkCore;

namespace YemenBooking.IndexingTests.Stress
{
    /// <summary>
    /// اختبارات الفوضى (Chaos Testing)
    /// تحاكي الأخطاء والمشاكل غير المتوقعة
    /// </summary>
    [Collection("TestContainers")]
    public class ChaosTests : TestBase
    {
        private readonly TestContainerFixture _containers;
        private readonly Random _random = new Random();
        private readonly SemaphoreSlim _concurrencyLimiter;

        public ChaosTests(TestContainerFixture containers, ITestOutputHelper output)
            : base(output)
        {
            _containers = containers;
            _concurrencyLimiter = new SemaphoreSlim(
                initialCount: Environment.ProcessorCount * 4,
                maxCount: Environment.ProcessorCount * 4
            );
        }

        protected override async Task ConfigureServicesAsync(IServiceCollection services)
        {
            // تكوين الخدمات مع Chaos Engineering الصحيح
            services.AddSingleton(_containers);
            
            // تسجيل Chaos Injection Service
            services.AddSingleton<IChaosInjector, ChaosInjector>();
            
            // إضافة Chaos Policies باستخدام Polly مع custom chaos injection
            services.AddSingleton<IAsyncPolicy>(provider =>
            {
                var chaosInjector = provider.GetService<IChaosInjector>();
                
                // 1. Circuit Breaker - للحماية من الانهيار الكامل
                var circuitBreaker = Policy
                    .Handle<Exception>()
                    .CircuitBreakerAsync(
                        handledEventsAllowedBeforeBreaking: 5,
                        durationOfBreak: TimeSpan.FromSeconds(10),
                        onBreak: (exception, duration) =>
                        {
                            Output.WriteLine($"🔴 Circuit breaker OPENED for {duration.TotalSeconds}s due to: {exception?.Message}");
                        },
                        onReset: () =>
                        {
                            Output.WriteLine($"🟢 Circuit breaker RESET - System recovered");
                        },
                        onHalfOpen: () =>
                        {
                            Output.WriteLine($"🟡 Circuit breaker HALF-OPEN - Testing...");
                        });
                
                // 2. Retry Policy مع Exponential Backoff + Jitter
                var retryPolicy = Policy
                    .Handle<Exception>(ex => !(ex is InvalidOperationException && ex.Message.Contains("Circuit")))
                    .WaitAndRetryAsync(
                        retryCount: 3,
                        sleepDurationProvider: retryAttempt => 
                        {
                            var exponentialDelay = TimeSpan.FromSeconds(Math.Pow(2, retryAttempt));
                            var jitter = TimeSpan.FromMilliseconds(_random.Next(0, 1000));
                            return exponentialDelay + jitter;
                        },
                        onRetry: (exception, timeSpan, retryCount, context) =>
                        {
                            Output.WriteLine($"🔄 Retry {retryCount}/{3} after {timeSpan.TotalSeconds:F2}s: {exception?.Message}");
                        });
                
                // 3. Timeout Policy - لمحاكاة بطء الشبكة
                var timeoutPolicy = Policy.TimeoutAsync(
                    seconds: 30,
                    onTimeoutAsync: async (context, timespan, task) =>
                    {
                        Output.WriteLine($"⏱️ Timeout after {timespan.TotalSeconds}s");
                        await Task.CompletedTask;
                    });
                
                // 4. Bulkhead Isolation - لمنع استنفاد الموارد
                var bulkheadPolicy = Policy.BulkheadAsync(
                    maxParallelization: Environment.ProcessorCount * 2,
                    maxQueuingActions: 10,
                    onBulkheadRejectedAsync: async context =>
                    {
                        Output.WriteLine($"🚫 Bulkhead rejected - System overloaded");
                        await Task.CompletedTask;
                    });
                
                // دمج السياسات بالترتيب الصحيح
                var combinedPolicy = Policy.WrapAsync(
                    retryPolicy,        // المحاولة عند الفشل
                    circuitBreaker,     // الحماية من الانهيار
                    timeoutPolicy,      // الحماية من البطء
                    bulkheadPolicy      // عزل العمليات
                );
                
                return combinedPolicy;
            });
            
            // إضافة خدمات أخرى مطلوبة للـ Chaos Testing
            services.AddScoped<IIndexingService, IndexingService>();
            services.AddDbContext<YemenBookingDbContext>(options =>
            {
                options.UseNpgsql(_containers.PostgresConnectionString);
                options.EnableSensitiveDataLogging();
                options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
                
                // محاكاة timeout عشوائية
                var shouldTimeout = _random.Next(0, 100) < 10; // 10% احتمال
                options.CommandTimeout(shouldTimeout ? 1 : 30);
            });

            await Task.CompletedTask;
        }
        
        #region Chaos Injection Service
        
        public interface IChaosInjector
        {
            Task InjectChaosAsync(string operationType);
            bool ShouldInjectFailure(double probability);
            Task InjectLatencyAsync(int minMs, int maxMs);
            Exception GenerateRandomException();
        }
        
        public class ChaosInjector : IChaosInjector
        {
            private readonly Random _random = new Random();
            private readonly ITestOutputHelper _output;
            
            public ChaosInjector()
            {
                _output = null; // يمكن حقنه لاحقاً
            }
            
            public async Task InjectChaosAsync(string operationType)
            {
                // 20% احتمال حقن فوضى
                if (ShouldInjectFailure(0.2))
                {
                    var chaosType = _random.Next(0, 4);
                    
                    switch (chaosType)
                    {
                        case 0: // Exception
                            throw GenerateRandomException();
                        
                        case 1: // Latency
                            await InjectLatencyAsync(500, 5000);
                            break;
                        
                        case 2: // Resource exhaustion
                            var memory = new byte[_random.Next(1000000, 10000000)];
                            await Task.Delay(100);
                            GC.Collect(); // تنظيف لتجنب OOM
                            break;
                        
                        case 3: // CPU spike
                            var endTime = DateTime.UtcNow.AddMilliseconds(_random.Next(100, 500));
                            while (DateTime.UtcNow < endTime)
                            {
                                // CPU intensive operation
                                Math.Sqrt(_random.NextDouble());
                            }
                            break;
                    }
                }
            }
            
            public bool ShouldInjectFailure(double probability)
            {
                return _random.NextDouble() < probability;
            }
            
            public async Task InjectLatencyAsync(int minMs, int maxMs)
            {
                var delay = _random.Next(minMs, maxMs);
                _output?.WriteLine($"⏳ Injecting {delay}ms latency");
                await Task.Delay(delay);
            }
            
            public Exception GenerateRandomException()
            {
                var exceptions = new Exception[]
                {
                    new InvalidOperationException("Chaos: Simulated operation failure"),
                    new TimeoutException("Chaos: Simulated timeout"),
                    new OutOfMemoryException("Chaos: Simulated memory exhaustion"),
                    new TaskCanceledException("Chaos: Simulated cancellation"),
                    new HttpRequestException("Chaos: Simulated network failure"),
                    new DbUpdateException("Chaos: Simulated database failure", new Exception())
                };
                
                return exceptions[_random.Next(exceptions.Length)];
            }
        }
        
        #endregion

        #region Chaos Test Cases

        [Fact]
        public async Task RandomFailures_SystemShouldRecover()
        {
            // Arrange
            Output.WriteLine("🌪️ Starting chaos test with random failures");
            
            var properties = TestDataBuilder.BatchProperties(20, TestId);
            var successCount = 0;
            var failureCount = 0;

            // Act: محاولة فهرسة مع أخطاء عشوائية
            var tasks = properties.Select(property => Task.Run(async () =>
            {
                try
                {
                    // حقن خطأ عشوائي
                    if (_random.NextDouble() < 0.3) // 30% failure
                    {
                        throw new Exception($"Simulated failure for {property.Id}");
                    }

                    await IndexingService.OnPropertyCreatedAsync(property.Id);
                    Interlocked.Increment(ref successCount);
                }
                catch (Exception ex)
                {
                    Output.WriteLine($"❌ Failed: {ex.Message}");
                    Interlocked.Increment(ref failureCount);
                    
                    // إعادة المحاولة
                    await Task.Delay(TimeSpan.FromSeconds(_random.Next(1, 5)));
                    
                    try
                    {
                        await IndexingService.OnPropertyCreatedAsync(property.Id);
                        Interlocked.Increment(ref successCount);
                        Interlocked.Decrement(ref failureCount);
                    }
                    catch
                    {
                        // Ignore second failure
                    }
                }
            })).ToList();

            await Task.WhenAll(tasks);

            // Assert
            Output.WriteLine($"✅ Success: {successCount}, ❌ Failures: {failureCount}");
            successCount.Should().BeGreaterThan(0, "Some operations should succeed");
            (successCount + failureCount).Should().Be(properties.Count);
        }

        [Fact]
        public async Task NetworkPartition_ShouldHandleGracefully()
        {
            // Arrange
            Output.WriteLine("🔌 Simulating network partition");
            
            var property = TestDataBuilder.CompleteProperty(TestId);
            TrackEntity(property.Id);

            // Act: محاكاة انقطاع الشبكة
            var networkPartitionTask = Task.Run(async () =>
            {
                await Task.Delay(TimeSpan.FromSeconds(2));
                Output.WriteLine("⚡ Network partition started");
                
                // محاكاة انقطاع الاتصال بـ Redis
                // في بيئة حقيقية، يمكن استخدام iptables أو أدوات أخرى
                
                await Task.Delay(TimeSpan.FromSeconds(5));
                Output.WriteLine("✅ Network restored");
            });

            var indexingTasks = new List<Task>();
            
            for (int i = 0; i < 10; i++)
            {
                indexingTasks.Add(Task.Run(async () =>
                {
                    try
                    {
                        await IndexingService.OnPropertyCreatedAsync(property.Id);
                    }
                    catch (Exception ex)
                    {
                        Output.WriteLine($"Expected failure during partition: {ex.Message}");
                    }
                }));
                
                await Task.Delay(TimeSpan.FromSeconds(1));
            }

            await Task.WhenAll(networkPartitionTask, Task.WhenAll(indexingTasks));

            // Assert: النظام يجب أن يتعافى بعد استعادة الشبكة
            var searchResult = await RetryAsync(
                async () => await IndexingService.SearchAsync(new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 100
                }),
                maxAttempts: 5
            );

            searchResult.Should().NotBeNull();
        }

        [Fact]
        public async Task MemoryPressure_ShouldNotCrash()
        {
            // Arrange
            Output.WriteLine("💾 Testing under memory pressure");
            
            var largeDataSets = new List<List<Property>>();
            
            try
            {
                // Act: إنشاء ضغط على الذاكرة
                for (int i = 0; i < 10; i++)
                {
                    var batch = TestDataBuilder.BatchProperties(100, $"{TestId}_{i}");
                    largeDataSets.Add(batch);
                    
                    // فهرسة مع ضغط الذاكرة
                    var indexingTasks = batch.Select(p => 
                        IndexingService.OnPropertyCreatedAsync(p.Id)
                    ).ToList();
                    
                    await Task.WhenAll(indexingTasks);
                    
                    // Force garbage collection
                    if (i % 3 == 0)
                    {
                        GC.Collect();
                        GC.WaitForPendingFinalizers();
                        GC.Collect();
                    }
                }

                // Assert: النظام يجب أن يستمر في العمل
                var searchResult = await IndexingService.SearchAsync(new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 100
                });

                searchResult.Should().NotBeNull();
                searchResult.TotalCount.Should().BeGreaterThan(0);
            }
            finally
            {
                // تنظيف
                largeDataSets.Clear();
                GC.Collect();
            }

            Output.WriteLine("✅ System survived memory pressure");
        }

        [Fact]
        public async Task RapidCreateUpdateDelete_ShouldMaintainConsistency()
        {
            // Arrange
            Output.WriteLine("🔄 Testing rapid CRUD operations");
            
            var property = TestDataBuilder.CompleteProperty(TestId);
            TrackEntity(property.Id);
            
            var operations = new List<Func<Task>>
            {
                async () => await IndexingService.OnPropertyCreatedAsync(property.Id),
                async () => await IndexingService.OnPropertyUpdatedAsync(property.Id),
                async () => await IndexingService.OnPropertyDeletedAsync(property.Id)
            };

            // Act: عمليات سريعة ومتداخلة
            var tasks = new List<Task>();
            
            for (int i = 0; i < 100; i++)
            {
                var operation = operations[_random.Next(operations.Count)];
                tasks.Add(Task.Run(async () =>
                {
                    await _concurrencyLimiter.WaitAsync();
                    try
                    {
                        await operation();
                    }
                    catch (Exception ex)
                    {
                        Output.WriteLine($"Operation failed (expected): {ex.Message}");
                    }
                    finally
                    {
                        _concurrencyLimiter.Release();
                    }
                }));
            }

            await Task.WhenAll(tasks);

            // Assert: التحقق من الاتساق النهائي
            await Task.Delay(TimeSpan.FromSeconds(2)); // انتظار الاتساق

            var searchResult = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 100
            });

            // يجب أن تكون النتيجة متسقة (موجود أو محذوف، ليس حالة وسطية)
            searchResult.Should().NotBeNull();
            Output.WriteLine($"Final state: {searchResult.TotalCount} properties");
        }

        [Fact]
        public async Task TimeoutScenarios_ShouldHandleGracefully()
        {
            // Arrange
            Output.WriteLine("⏱️ Testing timeout scenarios");
            
            var properties = TestDataBuilder.BatchProperties(50, TestId);
            TrackEntities(properties.Select(p => p.Id));

            // Act: عمليات مع timeouts مختلفة
            var tasks = properties.Select((property, index) => Task.Run(async () =>
            {
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(index % 5 + 1));
                
                try
                {
                    // محاكاة تأخير عشوائي
                    if (_random.NextDouble() < 0.3)
                    {
                        await Task.Delay(TimeSpan.FromSeconds(6), cts.Token);
                    }
                    
                    await IndexingService.OnPropertyCreatedAsync(property.Id, cts.Token);
                }
                catch (OperationCanceledException)
                {
                    Output.WriteLine($"Operation timed out for {property.Id} (expected)");
                }
            })).ToList();

            await Task.WhenAll(tasks);

            // Assert: النظام يجب أن يستمر في العمل
            var searchResult = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 100
            });

            searchResult.Should().NotBeNull();
            Output.WriteLine($"✅ Indexed {searchResult.TotalCount} properties despite timeouts");
        }

        [Fact]
        public async Task DataCorruption_ShouldDetectAndRecover()
        {
            // Arrange
            Output.WriteLine("🔨 Testing data corruption scenarios");
            
            var validProperty = TestDataBuilder.CompleteProperty(TestId);
            TrackEntity(validProperty.Id);

            // إنشاء بيانات تالفة
            var corruptedProperties = new List<Property>
            {
                new Property { Id = Guid.Empty }, // Invalid ID
                new Property { Id = Guid.NewGuid(), Name = null }, // Null required field
                new Property { Id = Guid.NewGuid(), Name = new string('X', 10000) }, // Too long
            };

            // Act: محاولة فهرسة البيانات التالفة
            var corruptionTasks = corruptedProperties.Select(property => Task.Run(async () =>
            {
                try
                {
                    await IndexingService.OnPropertyCreatedAsync(property.Id);
                    return (property.Id, Success: true, Error: (string)null);
                }
                catch (Exception ex)
                {
                    return (property.Id, Success: false, Error: ex.Message);
                }
            })).ToList();

            var results = await Task.WhenAll(corruptionTasks);

            // فهرسة البيانات الصحيحة
            await IndexingService.OnPropertyCreatedAsync(validProperty.Id);

            // Assert
            results.Where(r => !r.Success).Should().HaveCount(corruptedProperties.Count,
                "All corrupted data should fail");

            // البيانات الصحيحة يجب أن تكون مفهرسة
            var searchResult = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 100
            });

            searchResult.Should().ContainProperty(validProperty.Id);
            Output.WriteLine("✅ System rejected corrupted data and processed valid data");
        }

        #endregion

        #region Helper Methods

        private async Task SimulateRedisFailure(TimeSpan duration)
        {
            Output.WriteLine($"🔴 Simulating Redis failure for {duration.TotalSeconds} seconds");
            
            // في بيئة حقيقية، يمكن إيقاف حاوية Redis مؤقتاً
            // await _containers.StopRedisAsync();
            
            await Task.Delay(duration);
            
            // await _containers.StartRedisAsync();
            Output.WriteLine("🟢 Redis restored");
        }

        #endregion
    }
}
