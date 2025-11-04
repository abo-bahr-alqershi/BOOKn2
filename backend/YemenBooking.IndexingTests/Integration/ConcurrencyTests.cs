using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using FluentAssertions;
using FluentAssertions.Extensions;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using Npgsql;

namespace YemenBooking.IndexingTests.Integration
{
    /// <summary>
    /// اختبارات التزامن المحسّنة وفقاً للمعايير الاحترافية
    /// تطبيق مبادئ العزل الكامل والحتمية
    /// </summary>
    [Collection("TestContainers")]
    public class ConcurrencyTests : TestBase
    {
        private readonly TestContainerFixture _containers;
        private readonly SemaphoreSlim _concurrencyLimiter;
        
        public ConcurrencyTests(TestContainerFixture containers, ITestOutputHelper output) 
            : base(output)
        {
            _containers = containers;
            // تحديد عدد العمليات المتزامنة بناءً على عدد المعالجات
            _concurrencyLimiter = new SemaphoreSlim(
                initialCount: Environment.ProcessorCount * 2,
                maxCount: Environment.ProcessorCount * 2
            );
        }
        
        protected override async Task ConfigureServicesAsync(IServiceCollection services)
        {
            // تكوين قاعدة البيانات من الحاوية
            services.AddDbContext<YemenBookingDbContext>(options =>
            {
                options.UseNpgsql(_containers.PostgresConnectionString);
                options.EnableSensitiveDataLogging();
                options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking); // مهم للتزامن
            });
            
            // تسجيل خدمات Redis
            services.AddSingleton<IRedisConnectionManager>(provider => 
            {
                var redisManager = new RedisConnectionManager(_containers.RedisConnectionString);
                redisManager.InitializeAsync().GetAwaiter().GetResult();
                return redisManager;
            });
            
            // تسجيل الخدمات
            services.AddScoped<IIndexingService, IndexingService>();
            services.AddLogging(builder => 
            {
                builder.AddConsole();
                builder.SetMinimumLevel(LogLevel.Debug);
            });
            
            await Task.CompletedTask;
        }
        
        #region Pattern 1: Safe Concurrent Operations with Isolated Scopes
        
        [Fact]
        public async Task ConcurrentIndexing_WithIsolatedScopes_ShouldHandleCorrectly()
        {
            // Arrange
            Output.WriteLine("🚀 Testing concurrent indexing with isolated scopes");
            var propertyCount = 20;
            var properties = TestDataBuilder.BatchProperties(propertyCount, TestId);
            TrackEntities(properties.Select(p => p.Id));
            
            // حفظ في قاعدة البيانات
            await DbContext.Properties.AddRangeAsync(properties);
            await DbContext.SaveChangesAsync();
            
            // Act: فهرسة متزامنة مع scopes منفصلة
            var indexingTasks = new List<Task>();
            
            foreach (var property in properties)
            {
                indexingTasks.Add(Task.Run(async () =>
                {
                    await _concurrencyLimiter.WaitAsync();
                    try
                    {
                        // استخدام scope منفصل لكل task - مهم جداً للتزامن
                        using var scope = CreateIsolatedScope();
                        var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                        var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                        
                        // العمليات هنا آمنة للتزامن
                        var entity = await dbContext.Properties
                            .AsNoTracking()
                            .FirstOrDefaultAsync(p => p.Id == property.Id);
                            
                        if (entity != null)
                        {
                            await indexingService.OnPropertyCreatedAsync(entity.Id, TestCancellation.Token);
                        }
                    }
                    finally
                    {
                        _concurrencyLimiter.Release();
                    }
                }));
            }
            
            await Task.WhenAll(indexingTasks);
            
            // Assert: التحقق من فهرسة جميع العقارات
            var searchResult = await WaitForConditionAsync(
                async () => 
                {
                    using var scope = CreateIsolatedScope();
                    var searchService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    return await searchService.SearchAsync(new PropertySearchRequest
                    {
                        PageNumber = 1,
                        PageSize = 100
                    });
                },
                result => result?.TotalCount >= propertyCount,
                TimeSpan.FromSeconds(10),
                TimeSpan.FromMilliseconds(200)
            );
            
            searchResult.Should().NotBeNull();
            searchResult.TotalCount.Should().BeGreaterThanOrEqualTo(propertyCount);
            Output.WriteLine($"✅ Successfully indexed {propertyCount} properties concurrently with isolated scopes");
        }
        
        #endregion
        
        #region Pattern 2: Race Condition Prevention with Polling
        
        [Fact]
        public async Task ConcurrentUpdates_WithPollingVerification_ShouldMaintainConsistency()
        {
            // Arrange
            var property = TestDataBuilder.CompleteProperty(TestId);
            TrackEntity(property.Id);
            
            await DbContext.Properties.AddAsync(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            
            // Act: عمليات تحديث متزامنة
            var updateTasks = new List<Task>();
            var cities = new[] { "صنعاء", "عدن", "تعز", "الحديدة", "إب" };
            
            foreach (var city in cities)
            {
                updateTasks.Add(Task.Run(async () =>
                {
                    using var scope = CreateIsolatedScope();
                    var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                    var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    
                    // تحديث باستخدام transaction منفصل
                    using var transaction = await dbContext.Database.BeginTransactionAsync();
                    try
                    {
                        var entity = await dbContext.Properties
                            .FirstOrDefaultAsync(p => p.Id == property.Id);
                            
                        if (entity != null)
                        {
                            entity.City = city;
                            await dbContext.SaveChangesAsync();
                            await indexingService.OnPropertyUpdatedAsync(entity.Id, TestCancellation.Token);
                        }
                        
                        await transaction.CommitAsync();
                    }
                    catch
                    {
                        await transaction.RollbackAsync();
                        throw;
                    }
                }));
            }
            
            await Task.WhenAll(updateTasks);
            
            // Assert: استخدام Polling للتحقق من النتيجة النهائية
            var finalResult = await WaitForConditionAsync(
                async () =>
                {
                    using var scope = CreateIsolatedScope();
                    var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                    return await dbContext.Properties
                        .AsNoTracking()
                        .FirstOrDefaultAsync(p => p.Id == property.Id);
                },
                result => result != null && cities.Contains(result.City),
                TimeSpan.FromSeconds(5),
                TimeSpan.FromMilliseconds(100)
            );
            
            finalResult.Should().NotBeNull();
            cities.Should().Contain(finalResult.City);
            
            Output.WriteLine($"✅ Concurrent updates handled correctly - Final city: {finalResult.City}");
        }
        
        #endregion
        
        #region Pattern 3: Batch Operations with Controlled Concurrency
        
        [Fact]
        public async Task BatchIndexing_WithControlledConcurrency_ShouldOptimizePerformance()
        {
            // Arrange
            var totalProperties = 100;
            var batchSize = 10;
            var properties = TestDataBuilder.BatchProperties(totalProperties, TestId);
            TrackEntities(properties.Select(p => p.Id));
            
            await DbContext.Properties.AddRangeAsync(properties);
            await DbContext.SaveChangesAsync();
            
            // Act: معالجة دفعات بتزامن محكوم
            var processedCount = 0;
            var batches = properties.Chunk(batchSize);
            
            var batchTasks = batches.Select(batch => Task.Run(async () =>
            {
                await _concurrencyLimiter.WaitAsync();
                try
                {
                    using var scope = CreateIsolatedScope();
                    var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    
                    // فهرسة الدفعة
                    var indexTasks = batch.Select(p => 
                        indexingService.OnPropertyCreatedAsync(p.Id, TestCancellation.Token));
                    
                    await Task.WhenAll(indexTasks);
                    
                    Interlocked.Add(ref processedCount, batch.Length);
                    Output.WriteLine($"📦 Processed batch: {batch.Length} items, Total: {processedCount}/{totalProperties}");
                }
                finally
                {
                    _concurrencyLimiter.Release();
                }
            }));
            
            await Task.WhenAll(batchTasks);
            
            // Assert
            processedCount.Should().Be(totalProperties);
            
            using (var scope = CreateIsolatedScope())
            {
                var searchService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                var searchResult = await searchService.SearchAsync(new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 200
                });
                
                searchResult.Should().NotBeNull();
                searchResult.TotalCount.Should().BeGreaterThanOrEqualTo(totalProperties);
            }
            Output.WriteLine($"✅ Batch processing completed: {totalProperties} properties indexed");
        }
        
        #endregion
        
        #region Pattern 4: Deadlock Prevention with Timeout
        
        [Fact]
        public async Task ConcurrentOperations_WithTimeout_ShouldPreventDeadlock()
        {
            // Arrange
            var properties = TestDataBuilder.BatchProperties(5, TestId);
            TrackEntities(properties.Select(p => p.Id));
            
            await DbContext.Properties.AddRangeAsync(properties);
            await DbContext.SaveChangesAsync();
            
            // Act: عمليات مع timeout لمنع الdeadlock
            var tasks = properties.Select(property => Task.Run(async () =>
            {
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10));
                
                try
                {
                    using var scope = CreateIsolatedScope();
                    var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    
                    // عملية مع timeout
                    await indexingService.OnPropertyCreatedAsync(
                        property.Id, 
                        cts.Token);
                    
                    // محاكاة عملية معقدة
                    await Task.Delay(Random.Shared.Next(10, 100), cts.Token);
                    
                    await indexingService.OnPropertyUpdatedAsync(
                        property.Id,
                        cts.Token);
                }
                catch (OperationCanceledException)
                {
                    Output.WriteLine($"⚠️ Operation timed out for property {property.Id}");
                    throw;
                }
            }));
            
            // Assert
            var allTasks = Task.WhenAll(tasks);
            var completed = await Task.Run(async () =>
            {
                var timeout = Task.Delay(TimeSpan.FromSeconds(15));
                var completedTask = await Task.WhenAny(allTasks, timeout);
                return completedTask == allTasks;
            });
            
            completed.Should().BeTrue("all operations should complete within timeout");
            Output.WriteLine($"✅ All operations completed within timeout - No deadlock");
        }
        
        #endregion
        
        #region Pattern 5: Eventually Consistent Verification
        
        [Fact]
        public async Task EventuallyConsistentOperations_ShouldConvergeCorrectly()
        {
            // Arrange
            var propertyCount = 10;
            var properties = TestDataBuilder.BatchProperties(propertyCount, TestId);
            TrackEntities(properties.Select(p => p.Id));
            
            // Act: عمليات غير متزامنة قد تكون eventually consistent
            var createTasks = properties.Select((property, index) => Task.Run(async () =>
            {
                await Task.Delay(index * 50); // تأخير متدرج
                
                using var scope = CreateIsolatedScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                
                await dbContext.Properties.AddAsync(property);
                await dbContext.SaveChangesAsync();
                
                // قد لا تكتمل الفهرسة فوراً
                _ = Task.Run(async () =>
                {
                    await Task.Delay(Random.Shared.Next(100, 500));
                    await indexingService.OnPropertyCreatedAsync(property.Id, CancellationToken.None);
                });
            }));
            
            await Task.WhenAll(createTasks);
            
            // Assert: التحقق من Eventually Consistent State
            var finalResult = await WaitForConditionAsync(
                async () =>
                {
                    using var scope = CreateIsolatedScope();
                    var searchService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    return await searchService.SearchAsync(new PropertySearchRequest
                    {
                        PageNumber = 1,
                        PageSize = 100
                    });
                },
                result => result?.TotalCount >= propertyCount,
                TimeSpan.FromSeconds(10),
                TimeSpan.FromMilliseconds(200)
            );
            
            finalResult.Should().NotBeNull();
            finalResult.TotalCount.Should().BeGreaterThanOrEqualTo(propertyCount);
            Output.WriteLine($"✅ Eventually consistent operations converged: {finalResult.TotalCount} properties indexed");
        }
        
        #endregion
        
        #region Helper Methods
        
        protected override async Task InitializeDatabaseAsync()
        {
            await DbContext.Database.EnsureCreatedAsync();
            
            // إضافة البيانات الأساسية المطلوبة
            var propertyTypes = new[]
            {
                new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000001"), Name = "منتجع" },
                new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000002"), Name = "شقق مفروشة" },
                new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000003"), Name = "فندق" }
            };
            
            await DbContext.PropertyTypes.AddRangeAsync(propertyTypes);
            await DbContext.SaveChangesAsync();
        }
        
        protected override async Task PerformEntityCleanupAsync(List<Guid> entityIds)
        {
            if (!entityIds.Any())
                return;
            
            // حذف من قاعدة البيانات
            var sql = @"
                DELETE FROM units WHERE property_id = ANY(@ids);
                DELETE FROM properties WHERE id = ANY(@ids);
            ";
            
            await DbContext.Database.ExecuteSqlRawAsync(sql, new NpgsqlParameter("@ids", entityIds.ToArray()));
            
            // مسح Redis
            await _containers.FlushRedisAsync();
        }
        
        #endregion
    }
}
