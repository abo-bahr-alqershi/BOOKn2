# YemenBooking Indexing Tests 🧪

نظام اختبارات احترافي وشامل لنظام الفهرسة والبحث في YemenBooking، مبني وفقاً لأفضل الممارسات العالمية.

## 📋 المحتويات

- [المبادئ الأساسية](#المبادئ-الأساسية)
- [البنية والتنظيم](#البنية-والتنظيم)
- [أنواع الاختبارات](#أنواع-الاختبارات)
- [التشغيل](#التشغيل)
- [أفضل الممارسات](#أفضل-الممارسات)

## 🎯 المبادئ الأساسية

### 1. العزل الكامل (Complete Isolation)
- ✅ كل اختبار مستقل تماماً
- ✅ استخدام GUIDs فريدة للبيانات
- ✅ تنظيف تلقائي بعد كل اختبار
- ❌ لا توجد متغيرات static مشتركة

### 2. الحتمية (Determinism)
- ✅ نتائج قابلة للتكرار 100%
- ✅ استخدام Polling بدلاً من Delays الثابتة
- ❌ لا Task.Delay() أو Thread.Sleep()

### 3. التزامن الآمن (Concurrency Safety)
- ✅ Scope منفصل لكل عملية متزامنة
- ✅ استخدام SemaphoreSlim للتحكم
- ❌ لا DbContext مشترك بين threads

## 📁 البنية والتنظيم

```
YemenBooking.IndexingTests/
├── Infrastructure/           # البنية التحتية
│   ├── TestBase.cs          # الفئة الأساسية (بدون static)
│   ├── Fixtures/
│   │   └── TestContainerFixture.cs  # Docker containers
│   ├── Builders/
│   │   └── TestDataBuilder.cs       # Object Mother Pattern
│   ├── Assertions/
│   │   └── CustomAssertions.cs      # FluentAssertions مخصصة
│   └── Utilities/
│       └── TestHelpers.cs           # أدوات مساعدة
├── Unit/                    # اختبارات الوحدة
│   ├── Indexing/
│   │   └── PropertyIndexerTests.cs
│   ├── Search/
│   │   └── TextSearchTests.cs
│   └── Redis/
│       └── RedisOperationsTests.cs
├── Integration/             # اختبارات التكامل
│   └── EndToEndSearchTests.cs
├── Performance/             # اختبارات الأداء
│   └── IndexingBenchmarks.cs
└── Stress/                  # اختبارات الضغط
    └── LoadTests.cs
```

## 🧪 أنواع الاختبارات

### Unit Tests
- معزولة بالكامل باستخدام Mocks
- سريعة التنفيذ
- تركز على وحدة واحدة

### Integration Tests
- تستخدم Docker containers (PostgreSQL + Redis)
- تختبر التكامل الكامل
- كل اختبار في transaction منفصلة

### Performance Tests
- استخدام BenchmarkDotNet
- قياس الذاكرة والوقت
- مقارنة استراتيجيات مختلفة

### Stress Tests
- اختبار تحت ضغط عالٍ
- محاكاة سيناريوهات واقعية
- قياس معدلات النجاح والأداء

## 🚀 التشغيل

### المتطلبات
- .NET 8.0
- Docker Desktop
- Redis (اختياري للاختبارات المحلية)
- PostgreSQL (اختياري للاختبارات المحلية)

### تشغيل جميع الاختبارات
```bash
dotnet test
```

### تشغيل فئة معينة
```bash
# Unit Tests فقط
dotnet test --filter Category=Unit

# Integration Tests فقط
dotnet test --filter Category=Integration

# Performance Tests
dotnet test --filter Category=Performance
```

### تشغيل مع التغطية
```bash
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover
```

### تشغيل Benchmarks
```bash
dotnet run -c Release --project YemenBooking.IndexingTests -- --filter *IndexingBenchmarks*
```

## 🛠️ التكوين

### appsettings.test.json
```json
{
  "Testing": {
    "UseInMemoryDatabase": false,
    "UseTestContainers": true,
    "EnableDetailedLogging": true,
    "TestTimeout": 30000,
    "RetryAttempts": 3
  }
}
```

## ✅ أفضل الممارسات

### 1. استخدام TestDataBuilder
```csharp
// ✅ صحيح
var property = TestDataBuilder.CompleteProperty(testId);

// ❌ خطأ
var property = new Property { Name = "test" };
```

### 2. استخدام Scopes منفصلة للتزامن
```csharp
// ✅ صحيح
using var scope = CreateIsolatedScope();
var service = scope.ServiceProvider.GetRequiredService<IIndexingService>();

// ❌ خطأ
await _indexingService.OnPropertyCreatedAsync(id);
```

### 3. استخدام Polling بدلاً من Delay
```csharp
// ✅ صحيح
var result = await WaitForConditionAsync(
    async () => await SearchAsync(request),
    result => result.TotalCount > 0,
    TimeSpan.FromSeconds(5)
);

// ❌ خطأ
await Task.Delay(1000);
var result = await SearchAsync(request);
```

### 4. تتبع الكيانات للتنظيف
```csharp
// ✅ صحيح
var property = CreateProperty();
TrackEntity(property.Id);

// ❌ خطأ
var property = CreateProperty();
// نسيان التتبع يؤدي لتسريب البيانات
```

### 5. استخدام Custom Assertions
```csharp
// ✅ صحيح
searchResult.Should().HaveAtLeast(5);
searchResult.Should().AllBeInCity("صنعاء");

// ❌ خطأ
Assert.True(searchResult.TotalCount >= 5);
```

## 📊 المقاييس المستهدفة

- **Success Rate**: > 95%
- **Average Latency**: < 200ms للبحث
- **P95 Latency**: < 500ms
- **Concurrent Operations**: 100+ متزامنة
- **Memory Usage**: < 100MB لكل اختبار

## 🐛 حل المشاكل الشائعة

### مشكلة: DbContext is already being used
**الحل**: استخدم CreateIsolatedScope() لكل عملية متزامنة

### مشكلة: Test timeout
**الحل**: زيادة timeout أو تحسين polling interval

### مشكلة: Redis connection failed
**الحل**: تأكد من تشغيل Docker وأن المنافذ غير مستخدمة

### مشكلة: Flaky tests
**الحل**: استخدم WaitForConditionAsync بدلاً من delays ثابتة

## 📝 المساهمة

عند إضافة اختبارات جديدة:
1. اتبع نفس البنية والتنظيم
2. استخدم TestDataBuilder للبيانات
3. تأكد من العزل الكامل
4. أضف assertions مخصصة إذا لزم
5. وثق الاختبارات المعقدة

## 📚 المراجع

- [xUnit Documentation](https://xunit.net/)
- [FluentAssertions](https://fluentassertions.com/)
- [Testcontainers](https://www.testcontainers.org/)
- [BenchmarkDotNet](https://benchmarkdotnet.org/)

---

تم البناء بـ ❤️ وفقاً لأفضل الممارسات العالمية
