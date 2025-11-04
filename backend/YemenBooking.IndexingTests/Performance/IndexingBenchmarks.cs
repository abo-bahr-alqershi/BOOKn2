using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Diagnostics;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Jobs;
using BenchmarkDotNet.Columns;
using BenchmarkDotNet.Reports;
using BenchmarkDotNet.Running;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using StackExchange.Redis;
using Testcontainers.PostgreSql;
using Testcontainers.Redis;
using Microsoft.AspNetCore.Http;

namespace YemenBooking.IndexingTests.Performance
{
    /// <summary>
    /// قياس أداء عمليات الفهرسة الحقيقية
    /// يستخدم Redis و PostgreSQL الحقيقيين عبر TestContainers
    /// يطبق جميع مبادئ العزل والحتمية
    /// </summary>
    [MemoryDiagnoser]
    [ThreadingDiagnoser]
    [SimpleJob(RuntimeMoniker.Net80, warmupCount: 3, iterationCount: 10)]
    [MinColumn, MaxColumn, MeanColumn, MedianColumn]
    [RankColumn]
    public class IndexingBenchmarks : IDisposable
    {
        // TestContainers
        private PostgreSqlContainer _postgresContainer;
        private RedisContainer _redisContainer;
        
        // Services  
        private IServiceProvider _serviceProvider;
        private IServiceScope _benchmarkScope;
        private YemenBookingDbContext _dbContext;
        private IIndexingService _indexingService;
        private IRedisConnectionManager _redisManager;
        private IDatabase _redisDatabase;
        
        // Test data
        private readonly List<Guid> _propertyIds = new();
        private readonly List<Guid> _unitIds = new();
        private readonly string _benchmarkId = Guid.NewGuid().ToString("N");
        private readonly SemaphoreSlim _concurrencyLimiter;
        
        // Performance metrics
        private readonly List<double> _operationDurations = new();
        private readonly List<long> _memoryUsages = new();
        
        [Params(1, 10, 50, 100)]
        public int PropertyCount { get; set; }
        
        [Params(1, 5)]
        public int UnitsPerProperty { get; set; }
        
        [Params(1, 4, 8)]
        public int ConcurrencyLevel { get; set; }
        
        public IndexingBenchmarks()
        {
            _concurrencyLimiter = new SemaphoreSlim(
                initialCount: Environment.ProcessorCount * 2,
                maxCount: Environment.ProcessorCount * 2);
        }
        
        [GlobalSetup]
        public async Task GlobalSetup()
        {
            // Start TestContainers
            await StartContainersAsync();
            
            // Configure services with real implementations
            var services = new ServiceCollection();
            await ConfigureRealServicesAsync(services);
            
            _serviceProvider = services.BuildServiceProvider();
            _benchmarkScope = _serviceProvider.CreateScope();
            
            // Get services
            _dbContext = _benchmarkScope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            _indexingService = _benchmarkScope.ServiceProvider.GetRequiredService<IIndexingService>();
            _redisManager = _benchmarkScope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            _redisDatabase = _redisManager.GetDatabase();
            
            // Initialize database
            await InitializeDatabaseAsync();
            
            // Prepare test data
            await PrepareTestDataAsync();
        }
        
        private async Task StartContainersAsync()
        {
            // PostgreSQL Container
            _postgresContainer = new PostgreSqlBuilder()
                .WithImage("postgres:15-alpine")
                .WithDatabase("benchmarkdb")
                .WithUsername("benchmark")
                .WithPassword("benchmark123")
                .WithPortBinding(5432, true)
                .WithCleanUp(true)
                .Build();
            
            // Redis Container
            _redisContainer = new RedisBuilder()
                .WithImage("redis:7-alpine")
                .WithPortBinding(6379, true)
                .WithCleanUp(true)
                .Build();
            
            // Start both containers in parallel
            await Task.WhenAll(
                _postgresContainer.StartAsync(),
                _redisContainer.StartAsync()
            );
            
            // Wait for containers to be ready
            await WaitForContainersReadyAsync();
        }
        
        private async Task WaitForContainersReadyAsync()
        {
            var maxAttempts = 30;
            for (int i = 0; i < maxAttempts; i++)
            {
                try
                {
                    // Test PostgreSQL
                    await _postgresContainer.ExecAsync(new[] { "pg_isready", "-U", "benchmark" });
                    
                    // Test Redis
                    var redisResult = await _redisContainer.ExecAsync(new[] { "redis-cli", "ping" });
                    if (redisResult.Stdout.Contains("PONG"))
                    {
                        return; // Both ready
                    }
                }
                catch
                {
                    await Task.Delay(1000);
                }
            }
            throw new TimeoutException("Containers failed to become ready");
        }
        
        private async Task ConfigureRealServicesAsync(IServiceCollection services)
        {
            // Configuration
            var config = new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string>
                {
                    ["ConnectionStrings:DefaultConnection"] = _postgresContainer.GetConnectionString(),
                    ["ConnectionStrings:Redis"] = _redisContainer.GetConnectionString(),
                    ["Redis:DefaultDatabase"] = "0",
                    ["Redis:ConnectTimeout"] = "5000",
                    ["Redis:AbortOnConnectFail"] = "false"
                })
                .Build();
            
            services.AddSingleton<IConfiguration>(config);
            
            // Database
            services.AddDbContext<YemenBookingDbContext>(options =>
            {
                options.UseNpgsql(_postgresContainer.GetConnectionString());
                options.EnableSensitiveDataLogging();
                options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
            });
            
            // Redis - Real implementation
            services.AddSingleton<IRedisConnectionManager, RedisConnectionManager>();
            
            // Indexing Service - Real implementation
            services.AddScoped<IIndexingService, IndexingService>();
            
            // Required dependencies
            services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();
            services.AddLogging(builder =>
            {
                builder.SetMinimumLevel(LogLevel.Warning); // Reduce noise in benchmarks
            });
            
            await Task.CompletedTask;
        }
        
        private async Task InitializeDatabaseAsync()
        {
            // Create database schema
            await _dbContext.Database.EnsureDeletedAsync();
            await _dbContext.Database.EnsureCreatedAsync();
            
            // Add base data
            await AddBaseDataAsync();
        }
        
        private async Task AddBaseDataAsync()
        {
            // PropertyTypes
            var propertyTypes = new[]
            {
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000001"), 
                    Name = "Hotel", 
                    Description = "Hotel",
                    DefaultAmenities = "[]",
                    Icon = "hotel"
                },
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000002"), 
                    Name = "Apartment", 
                    Description = "Apartment",
                    DefaultAmenities = "[]",
                    Icon = "apartment"
                }
            };
            
            // Cities
            var cities = new[]
            {
                new City { Name = "Sanaa", Country = "Yemen", ImagesJson = "[]" },
                new City { Name = "Aden", Country = "Yemen", ImagesJson = "[]" }
            };
            
            // Users
            var user = new User
            {
                Id = Guid.Parse("50000000-0000-0000-0000-000000000001"),
                Name = "Benchmark User",
                Email = "benchmark@test.com",
                Password = "BenchmarkPass123!",
                Phone = "+967777777777",
                EmailConfirmed = true,
                PhoneNumberConfirmed = true,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };
            
            await _dbContext.PropertyTypes.AddRangeAsync(propertyTypes);
            await _dbContext.Cities.AddRangeAsync(cities);
            await _dbContext.Users.AddAsync(user);
            await _dbContext.SaveChangesAsync();
            _dbContext.ChangeTracker.Clear();
        }
        
        private async Task PrepareTestDataAsync()
        {
            _propertyIds.Clear();
            _unitIds.Clear();
            
            // Create properties with unique names
            var properties = new List<Property>();
            for (int i = 0; i < PropertyCount; i++)
            {
                var property = TestDataBuilder.CompleteProperty($"benchmark_{_benchmarkId}_{i}");
                properties.Add(property);
                _propertyIds.Add(property.Id);
                
                // Add units for each property
                for (int j = 0; j < UnitsPerProperty; j++)
                {
                    var unit = TestDataBuilder.UnitForProperty(property.Id, $"unit_{_benchmarkId}_{i}_{j}");
                    property.Units.Add(unit);
                    _unitIds.Add(unit.Id);
                }
            }
            
            // Save all properties and units
            await _dbContext.Properties.AddRangeAsync(properties);
            await _dbContext.SaveChangesAsync();
            _dbContext.ChangeTracker.Clear();
        }
        
        [GlobalCleanup]
        public async Task GlobalCleanup()
        {
            // Clean up test data from Redis
            await CleanupRedisDataAsync();
            
            // Clean up database
            await CleanupDatabaseAsync();
            
            // Dispose services
            _benchmarkScope?.Dispose();
            (_serviceProvider as IDisposable)?.Dispose();
            
            // Stop containers
            if (_postgresContainer != null)
            {
                await _postgresContainer.DisposeAsync();
            }
            if (_redisContainer != null)
            {
                await _redisContainer.DisposeAsync();
            }
            
            _concurrencyLimiter?.Dispose();
        }
        
        private async Task CleanupRedisDataAsync()
        {
            if (_redisDatabase != null && _propertyIds.Any())
            {
                var tasks = new List<Task>();
                
                // Clean property data
                foreach (var propertyId in _propertyIds)
                {
                    tasks.Add(_redisDatabase.KeyDeleteAsync($"property:{propertyId}"));
                }
                
                // Clean unit data
                foreach (var unitId in _unitIds)
                {
                    tasks.Add(_redisDatabase.KeyDeleteAsync($"unit:{unitId}"));
                }
                
                await Task.WhenAll(tasks);
            }
        }
        
        private async Task CleanupDatabaseAsync()
        {
            if (_dbContext != null && _propertyIds.Any())
            {
                // Delete units first (FK constraint)
                var units = await _dbContext.Units
                    .Where(u => _unitIds.Contains(u.Id))
                    .ToListAsync();
                _dbContext.Units.RemoveRange(units);
                
                // Delete properties
                var properties = await _dbContext.Properties
                    .Where(p => _propertyIds.Contains(p.Id))
                    .ToListAsync();
                _dbContext.Properties.RemoveRange(properties);
                
                await _dbContext.SaveChangesAsync();
            }
        }
        
        /// <summary>
        /// Benchmark: Index single property
        /// </summary>
        [Benchmark(Baseline = true)]
        public async Task IndexSingleProperty()
        {
            if (_propertyIds.Any())
            {
                using var scope = CreateIsolatedScope();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                
                var stopwatch = Stopwatch.StartNew();
                await indexingService.OnPropertyCreatedAsync(_propertyIds.First());
                stopwatch.Stop();
                
                RecordMetrics(stopwatch.Elapsed.TotalMilliseconds);
            }
        }
        
        /// <summary>
        /// Benchmark: Index properties sequentially
        /// </summary>
        [Benchmark]
        public async Task IndexPropertiesSequential()
        {
            using var scope = CreateIsolatedScope();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            foreach (var propertyId in _propertyIds)
            {
                await indexingService.OnPropertyCreatedAsync(propertyId);
            }
        }
        
        /// <summary>
        /// Benchmark: Index properties in parallel with isolation
        /// </summary>
        [Benchmark]
        public async Task IndexPropertiesParallelWithIsolation()
        {
            var tasks = _propertyIds.Select(async propertyId =>
            {
                // Each task gets its own scope - CRITICAL for isolation
                using var scope = CreateIsolatedScope();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                await indexingService.OnPropertyCreatedAsync(propertyId);
            });
            
            await Task.WhenAll(tasks);
        }
        
        /// <summary>
        /// Benchmark: Index properties with concurrency control
        /// </summary>
        [Benchmark]
        public async Task IndexPropertiesWithConcurrencyControl()
        {
            var semaphore = new SemaphoreSlim(ConcurrencyLevel, ConcurrencyLevel);
            
            var tasks = _propertyIds.Select(async propertyId =>
            {
                await semaphore.WaitAsync();
                try
                {
                    using var scope = CreateIsolatedScope();
                    var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    await indexingService.OnPropertyCreatedAsync(propertyId);
                }
                finally
                {
                    semaphore.Release();
                }
            });
            
            await Task.WhenAll(tasks);
            semaphore.Dispose();
        }
        
        /// <summary>
        /// Benchmark: Index properties in batches
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
                var tasks = batch.Select(async propertyId =>
                {
                    using var scope = CreateIsolatedScope();
                    var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    await indexingService.OnPropertyCreatedAsync(propertyId);
                });
                
                await Task.WhenAll(tasks);
            }
        }
        
        /// <summary>
        /// Benchmark: Index units
        /// </summary>
        [Benchmark]
        public async Task IndexUnits()
        {
            if (_propertyIds.Any() && _unitIds.Any())
            {
                using var scope = CreateIsolatedScope();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                
                var propertyId = _propertyIds.First();
                var unitId = _unitIds.First();
                
                await indexingService.OnUnitCreatedAsync(unitId, propertyId);
            }
        }
        
        /// <summary>
        /// Benchmark: Update property index
        /// </summary>
        [Benchmark]
        public async Task UpdatePropertyIndex()
        {
            if (_propertyIds.Any())
            {
                using var scope = CreateIsolatedScope();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                
                await indexingService.OnPropertyUpdatedAsync(_propertyIds.First());
            }
        }
        
        /// <summary>
        /// Benchmark: Delete from index
        /// </summary>
        [Benchmark]
        public async Task DeleteFromIndex()
        {
            if (_propertyIds.Any())
            {
                using var scope = CreateIsolatedScope();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                
                await indexingService.OnPropertyDeletedAsync(_propertyIds.First());
            }
        }
        
        /// <summary>
        /// Benchmark: Search operations
        /// </summary>
        [Benchmark]
        public async Task SearchProperties()
        {
            using var scope = CreateIsolatedScope();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            var searchRequest = new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 20,
                SortBy = "CreatedAt",
            };
            
            await indexingService.SearchAsync(searchRequest);
        }
        
        /// <summary>
        /// Benchmark: Full indexing flow (Create, Update, Search, Delete)
        /// </summary>
        [Benchmark]
        public async Task FullIndexingFlow()
        {
            if (_propertyIds.Any())
            {
                using var scope = CreateIsolatedScope();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                var propertyId = _propertyIds.First();
                
                // Create
                await indexingService.OnPropertyCreatedAsync(propertyId);
                
                // Update
                await indexingService.OnPropertyUpdatedAsync(propertyId);
                
                // Search
                await indexingService.SearchAsync(new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 10
                });
                
                // Delete
                await indexingService.OnPropertyDeletedAsync(propertyId);
            }
        }
        
        /// <summary>
        /// Benchmark: Rebuild entire index
        /// </summary>
        [Benchmark]
        public async Task RebuildIndex()
        {
            using var scope = CreateIsolatedScope();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            await indexingService.RebuildIndexAsync();
        }
        
        private IServiceScope CreateIsolatedScope()
        {
            return _serviceProvider.CreateScope();
        }
        
        private void RecordMetrics(double durationMs)
        {
            _operationDurations.Add(durationMs);
            
            var currentMemory = GC.GetTotalMemory(false);
            _memoryUsages.Add(currentMemory);
        }
        
        public void Dispose()
        {
            GlobalCleanup().GetAwaiter().GetResult();
        }
    }
    
    /// <summary>
    /// Custom benchmark runner with detailed reporting
    /// </summary>
    public class BenchmarkRunner
    {
        public static void RunBenchmarks()
        {
            var summary = BenchmarkDotNet.Running.BenchmarkRunner.Run<IndexingBenchmarks>();
            
            // Print custom statistics
            Console.WriteLine("\n=== Custom Performance Metrics ===");
            Console.WriteLine($"Total benchmarks run: {summary.BenchmarksCases.Length}");
            Console.WriteLine($"Total time: {summary.TotalTime}");
            
            // Find best and worst performing
            var results = summary.BenchmarksCases
                .OrderBy(b => b.Parameters["PropertyCount"])
                .ThenBy(b => b.Descriptor.WorkloadMethodDisplayInfo);
            
            foreach (var benchmark in results)
            {
                Console.WriteLine($"\n{benchmark.Descriptor.WorkloadMethodDisplayInfo}:");
                Console.WriteLine($"  PropertyCount: {benchmark.Parameters["PropertyCount"]}");
                Console.WriteLine($"  UnitsPerProperty: {benchmark.Parameters["UnitsPerProperty"]}");
                Console.WriteLine($"  ConcurrencyLevel: {benchmark.Parameters["ConcurrencyLevel"]}");
            }
        }
    }
}
