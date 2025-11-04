---
trigger: manual
---

📚 دليل شامل لبناء نظام اختبارات احترافي لنظام الفهرسة والبحث
🎯 المبادئ الأساسية الحاكمة
1. مبدأ العزل الكامل (Complete Isolation)

✅ كل اختبار يجب أن يكون:
- مستقل تماماً عن الاختبارات الأخرى
- يستخدم بيانات فريدة (GUIDs في الأسماء)
- ينظف بياناته بعد الانتهاء
- لا يعتمد على ترتيب التنفيذ

❌ تجنب تماماً:
- المتغيرات الـ static المشتركة
- الاعتماد على بيانات من اختبار آخر
- افتراض حالة معينة للبيانات

2. مبدأ الحتمية (Determinism)
✅ النتائج يجب أن تكون:
- متوقعة ومحددة
- قابلة للتكرار 100%
- غير معتمدة على التوقيت
- غير معتمدة على البيئة

❌ تجنب تماماً:
- Task.Delay() الثابت
- Thread.Sleep()
- الاعتماد على الوقت الحقيقي
- الافتراضات حول سرعة التنفيذ

📋 البنية الأساسية للاختبارات
1. هيكل المشروع المثالي
YemenBooking.IndexingTests/
├── Infrastructure/
│   ├── TestBase.cs                 # الفئة الأساسية - بدون static state
│   ├── TestDataBuilder.cs          # بناء البيانات الاختبارية
│   ├── TestContainerFixture.cs     # Docker containers للخدمات
│   ├── TestUtilities.cs            # أدوات مساعدة
│   └── Assertions/
│       ├── CustomAssertions.cs     # Assertions مخصصة
│       └── RetryAssertions.cs      # Assertions مع إعادة المحاولة
├── Unit/
│   ├── Indexing/
│   │   ├── PropertyIndexerTests.cs
│   │   └── UnitIndexerTests.cs
│   ├── Search/
│   │   ├── TextSearchTests.cs
│   │   └── FilterTests.cs
│   └── Redis/
│       ├── ConnectionTests.cs
│       └── OperationsTests.cs
├── Integration/
│   ├── EndToEndSearchTests.cs
│   ├── IndexingFlowTests.cs
│   └── ConcurrencyTests.cs
├── Performance/
│   ├── IndexingBenchmarks.cs
│   └── SearchBenchmarks.cs
└── Stress/
    ├── LoadTests.cs
    └── ChaosTests.cs



🔧 التعامل مع التزامن (Concurrency)
1. القواعد الذهبية للتزامن في الاختبارات
// ✅ الطريقة الصحيحة - استخدام Scopes منفصلة
public class ConcurrencyTestPattern
{
    // 1. لكل thread/task يجب استخدام scope منفصل
    private async Task SafeConcurrentOperation(IServiceProvider serviceProvider, Guid entityId)
    {
        using var scope = serviceProvider.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
        var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
        
        // العمليات هنا آمنة للتزامن
        var entity = await dbContext.Properties.FindAsync(entityId);
        await indexingService.OnPropertyCreatedAsync(entityId);
    }
    
    // 2. استخدام SemaphoreSlim للتحكم في التزامن
    private readonly SemaphoreSlim _concurrencyLimiter = new(
        initialCount: Environment.ProcessorCount * 2,
        maxCount: Environment.ProcessorCount * 2
    );
    
    // 3. تجنب DbContext المشترك تماماً
    [Fact]
    public async Task Test_Concurrent_Operations()
    {
        var tasks = new List<Task>();
        
        for (int i = 0; i < 100; i++)
        {
            tasks.Add(Task.Run(async () =>
            {
                await _concurrencyLimiter.WaitAsync();
                try
                {
                    // استخدام scope منفصل لكل task
                    using var scope = _serviceProvider.CreateScope();
                    // العمليات هنا
                }
                finally
                {
                    _concurrencyLimiter.Release();
                }
            }));
        }
        
        await Task.WhenAll(tasks);
    }
}

2. حل مشاكل Race Conditions
// ✅ استخدام Polling بدلاً من Delay
public class PollingPattern
{
    public async Task<T> WaitForConditionAsync<T>(
        Func<Task<T>> checkCondition,
        Func<T, bool> isConditionMet,
        TimeSpan timeout,
        TimeSpan pollInterval = default)
    {
        pollInterval = pollInterval == default ? TimeSpan.FromMilliseconds(100) : pollInterval;
        var deadline = DateTime.UtcNow.Add(timeout);
        
        while (DateTime.UtcNow < deadline)
        {
            var result = await checkCondition();
            if (isConditionMet(result))
            {
                return result;
            }
            
            var remainingTime = deadline - DateTime.UtcNow;
            if (remainingTime <= TimeSpan.Zero)
                break;
                
            var delay = remainingTime < pollInterval ? remainingTime : pollInterval;
            await Task.Delay(delay);
        }
        
        throw new TimeoutException($"Condition not met within {timeout}");
    }
}

// ❌ تجنب تماماً
public async Task BadPattern()
{
    await DoSomething();
    await Task.Delay(1000); // ❌ افتراض أن 1 ثانية كافية
    var result = await GetResult(); // قد يفشل
}

🗄️ التعامل مع قاعدة البيانات
1. استراتيجية قواعد البيانات في الاختبارات
public class DatabaseStrategy
{
    // Option 1: استخدام Testcontainers (الأفضل للاختبارات الشاملة)
    public class PostgresTestContainer : IAsyncLifetime
    {
        private PostgreSqlContainer _container;
        
        public async Task InitializeAsync()
        {
            _container = new PostgreSqlBuilder()
                .WithImage("postgres:15-alpine")
                .WithDatabase("testdb")
                .WithUsername("test")
                .WithPassword("test")
                .Build();
                
            await _container.StartAsync();
        }
        
        public string ConnectionString => _container.GetConnectionString();
    }
    
    // Option 2: In-Memory Database (للاختبارات السريعة فقط)
    public class InMemoryDatabaseFixture
    {
        public DbContextOptions<YemenBookingDbContext> CreateOptions()
        {
            var dbName = $"TestDb_{Guid.NewGuid():N}";
            return new DbContextOptionsBuilder<YemenBookingDbContext>()
                .UseInMemoryDatabase(dbName)
                .EnableSensitiveDataLogging()
                .UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking) // مهم جداً
                .Options;
        }
    }
    
    // Option 3: SQLite In-Memory (وسط بين الاثنين)
    public class SqliteInMemoryFixture
    {
        private SqliteConnection _connection;
        
        public DbContextOptions<YemenBookingDbContext> CreateOptions()
        {
            _connection = new SqliteConnection("DataSource=:memory:");
            _connection.Open();
            
            return new DbContextOptionsBuilder<YemenBookingDbContext>()
                .UseSqlite(_connection)
                .Options;
        }
    }
}


2. إدارة البيانات الاختبارية
public class TestDataManagement
{
    // استخدام Object Mother Pattern
    public class PropertyMother
    {
        private static int _counter = 0;
        
        public static Property Simple()
        {
            var uniqueId = Interlocked.Increment(ref _counter);
            return new Property
            {
                Id = Guid.NewGuid(),
                Name = $"TEST_PROP_{uniqueId}_{Guid.NewGuid():N}",
                // باقي الخصائص
            };
        }
        
        public static Property WithUnits(int unitCount = 3)
        {
            var property = Simple();
            property.Units = Enumerable.Range(0, unitCount)
                .Select(_ => UnitMother.ForProperty(property.Id))
                .ToList();
            return property;
        }
    }
    
    // تنظيف البيانات الذكي
    public class SmartCleanup
    {
        private readonly List<Guid> _createdEntities = new();
        
        public void TrackEntity(Guid id) => _createdEntities.Add(id);
        
        public async Task CleanupAsync(DbContext context)
        {
            if (!_createdEntities.Any()) return;
            
            // حذف بالترتيب العكسي لتجنب مشاكل FK
            var sql = @"
                DELETE FROM units WHERE property_id = ANY(@ids);
                DELETE FROM properties WHERE id = ANY(@ids);
            ";
            
            await context.Database.ExecuteSqlRawAsync(sql, 
                new NpgsqlParameter("@ids", _createdEntities.ToArray()));
                
            _createdEntities.Clear();
            context.ChangeTracker.Clear();
        }
    }
}


🔄 التعامل مع Redis
1. استراتيجية Redis في الاختبارات
public class RedisTestStrategy
{
    // استخدام Redis Container
    public class RedisTestContainer : IAsyncLifetime
    {
        private RedisContainer _container;
        
        public async Task InitializeAsync()
        {
            _container = new RedisBuilder()
                .WithImage("redis:7-alpine")
                .WithPortBinding(6379, true)
                .Build();
                
            await _container.StartAsync();
            
            // انتظار حتى يصبح Redis جاهز
            await WaitForRedisReady();
        }
        
        private async Task WaitForRedisReady()
        {
            var maxAttempts = 30;
            for (int i = 0; i < maxAttempts; i++)
            {
                try
                {
                    using var connection = await ConnectionMultiplexer.ConnectAsync(ConnectionString);
                    var db = connection.GetDatabase();
                    await db.PingAsync();
                    return;
                }
                catch
                {
                    await Task.Delay(1000);
                }
            }
            throw new Exception("Redis failed to start");
        }
    }
    
    // عزل البيانات بين الاختبارات
    public class RedisIsolation
    {
        private readonly string _testPrefix;
        
        public RedisIsolation()
        {
            _testPrefix = $"test:{Guid.NewGuid():N}:";
        }
        
        public string GetKey(string key) => $"{_testPrefix}{key}";
        
        public async Task CleanupAsync(IDatabase db)
        {
            var server = db.Multiplexer.GetServer(db.Multiplexer.GetEndPoints().First());
            var keys = server.Keys(pattern: $"{_testPrefix}*");
            await db.KeyDeleteAsync(keys.ToArray());
        }
    }
}

2. اختبار العمليات غير المتزامنة
public class AsyncRedisOperations
{
    // Pattern للتعامل مع Eventually Consistent Operations
    public class EventuallyConsistentAssertion
    {
        public static async Task AssertEventuallyAsync(
            Func<Task<bool>> assertion,
            TimeSpan timeout,
            string message = null)
        {
            var deadline = DateTime.UtcNow.Add(timeout);
            Exception lastException = null;
            
            while (DateTime.UtcNow < deadline)
            {
                try
                {
                    if (await assertion())
                        return;
                }
                catch (Exception ex)
                {
                    lastException = ex;
                }
                
                await Task.Delay(50);
            }
            
            throw new AssertionException(
                message ?? "Assertion did not become true within timeout",
                lastException);
        }
    }
    
    // استخدام Circuit Breaker في الاختبارات
    public class TestCircuitBreaker
    {
        private readonly ICircuitBreaker _breaker = new CircuitBreaker(
            handledEventsAllowedBeforeBreaking: 3,
            durationOfBreak: TimeSpan.FromSeconds(1));
            
        public async Task<T> ExecuteAsync<T>(Func<Task<T>> operation)
        {
            return await _breaker.ExecuteAsync(operation);
        }
    }
}


🎭 اختبارات الأداء
1. قياس وتحليل الأداء
public class PerformanceTesting
{
    // استخدام BenchmarkDotNet
    [MemoryDiagnoser]
    [SimpleJob(RuntimeMoniker.Net70)]
    public class IndexingBenchmarks
    {
        private IIndexingService _indexingService;
        private List<Guid> _propertyIds;
        
        [GlobalSetup]
        public void Setup()
        {
            // إعداد البيانات
        }
        
        [Benchmark]
        public async Task IndexSingleProperty()
        {
            await _indexingService.OnPropertyCreatedAsync(_propertyIds[0]);
        }
        
        [Benchmark]
        [Arguments(10)]
        [Arguments(100)]
        [Arguments