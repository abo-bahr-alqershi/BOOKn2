# 🚀 نظام الفهرسة والبحث المتقدم V2 - Redis Indexing System

## ✨ نظام محسن بالكامل يطبق جميع التوصيات الاحترافية

## 📋 نظرة عامة

نظام فهرسة وبحث متطور ومحسن للغاية مبني على Redis، يوفر أداءً عالياً وقابلية توسع كبيرة لنظام حجز العقارات. تم بناء النظام وفقاً لأحدث معايير البرمجة وأفضل الممارسات.

## 🏗️ البنية المعمارية

النظام مبني على 6 طبقات رئيسية:

### 1️⃣ طبقة الفهرسة الذكية (Smart Indexing Layer)
```
📁 Redis/Indexing/SmartIndexingLayer.cs
```
- **الوظيفة**: إدارة جميع عمليات الفهرسة
- **المميزات**:
  - فهرسة ذرية باستخدام Transactions
  - دعم MessagePack للسرعة
  - فهرسة متعددة الأنواع (Hash, Set, Sorted Set, Geo)
  - معالجة دفعية للأداء

### 2️⃣ محرك البحث المحسن (Optimized Search Engine)
```
📁 Redis/Search/OptimizedSearchEngine.cs
```
- **الاستراتيجيات**:
  - البحث النصي (RediSearch)
  - البحث الجغرافي (GeoSearch)
  - الفلترة المعقدة (Lua Scripts)
  - البحث البسيط (Set Operations)
- **التحسينات**:
  - اختيار الاستراتيجية التلقائي
  - دعم التقسيم والترتيب
  - معالجة متوازية

### 3️⃣ نظام الكاش متعدد المستويات (Multi-Level Cache)
```
📁 Redis/Cache/MultiLevelCache.cs
```
- **المستويات**:
  - **L1**: Memory Cache (30 ثانية)
  - **L2**: Redis Result Cache (2 دقيقة)
  - **L3**: Redis Data Cache (10 دقائق)
- **المميزات**:
  - ترقية تلقائية بين المستويات
  - إحصائيات مفصلة
  - إدارة ذكية للذاكرة

### 4️⃣ معالج الإتاحة المحسن (Availability Processor)
```
📁 Redis/Availability/AvailabilityProcessor.cs
```
- **الوظائف**:
  - فحص الإتاحة في الوقت الفعلي
  - حساب الأسعار الديناميكي
  - دعم القواعد المعقدة
  - معالجة الحجوزات

### 5️⃣ نظام معالجة الأخطاء والمراقبة (Error Handling & Monitoring)
```
📁 Redis/Monitoring/ErrorHandlingAndMonitoring.cs
```
- **المميزات**:
  - Retry Policy (3 محاولات)
  - Circuit Breaker
  - Fallback Strategies
  - Health Checks
  - Performance Metrics
  - Alerting System

### 6️⃣ Lua Scripts المحسنة
```
📁 Redis/Scripts/LuaScripts.cs
```
- **السكريبتات**:
  - البحث والفلترة المعقد
  - فحص الإتاحة
  - تحديث الإحصائيات
  - إعادة بناء الفهارس
  - تنظيف البيانات القديمة

## 📊 هيكلة البيانات في Redis

### المفاتيح الأساسية
```redis
property:{id}           → Hash (بيانات العقار)
property:{id}:bin       → String (MessagePack)
property:{id}:meta      → Hash (Metadata)
```

### الفهارس الجغرافية
```redis
geo:properties          → Geo (جميع العقارات)
geo:cities:{city}       → Geo (عقارات المدينة)
```

### فهارس الترتيب
```redis
idx:price              → Sorted Set (حسب السعر)
idx:rating             → Sorted Set (حسب التقييم)
idx:created            → Sorted Set (حسب التاريخ)
idx:bookings           → Sorted Set (حسب الحجوزات)
idx:popularity         → Sorted Set (حسب الشعبية)
```

### فهارس التصنيف
```redis
tag:type:{typeId}      → Set (نوع العقار)
tag:city:{city}        → Set (المدينة)
tag:amenity:{id}       → Set (المرافق)
tag:service:{id}       → Set (الخدمات)
tag:featured           → Set (المميزة)
```

### فهارس الإتاحة
```redis
avail:unit:{id}        → Sorted Set (فترات الإتاحة)
avail:date:{YYYYMMDD}  → Set (الوحدات المتاحة)
```

## 🔧 التكوين والإعداد

### 1. إضافة الخدمات في Program.cs
```csharp
// في Program.cs أو Startup.cs
builder.Services.AddRedisIndexingSystem(builder.Configuration);

// إضافة Memory Cache
builder.Services.AddMemoryCache();

// إضافة Health Checks (اختياري)
builder.Services.AddHealthChecks();
```

### 2. إعدادات appsettings.json
```json
{
  "Redis": {
    "Enabled": true,
    "EndPoint": "localhost:6379",
    "Password": "",
    "Database": 0,
    "EnableScheduledMaintenance": true,
    "MaintenanceIntervalHours": 24
  },
  "Search": {
    "MaxResults": 1000,
    "DefaultPageSize": 20,
    "EnableRediSearch": true
  },
  "Cache": {
    "L1TTLSeconds": 30,
    "L2TTLMinutes": 2,
    "L3TTLMinutes": 10,
    "EnableMultiLevel": true
  },
  "CircuitBreaker": {
    "FailureThreshold": 5,
    "BreakDurationSeconds": 30,
    "RetryCount": 3
  }
}
```

## 💻 استخدام النظام

### فهرسة عقار جديد
```csharp
@inject IIndexingService _indexingService

// عند إضافة عقار جديد
await _indexingService.OnPropertyCreatedAsync(propertyId);
```

### البحث في العقارات
```csharp
var searchRequest = new PropertySearchRequest
{
    SearchText = "شقة فاخرة",
    City = "صنعاء",
    MinPrice = 100,
    MaxPrice = 500,
    MinRating = 4,
    CheckIn = DateTime.Now.AddDays(7),
    CheckOut = DateTime.Now.AddDays(10),
    GuestsCount = 4,
    SortBy = "price_asc",
    PageNumber = 1,
    PageSize = 20
};

var results = await _indexingService.SearchAsync(searchRequest);
```

### فحص الإتاحة
```csharp
@inject AvailabilityProcessor _availabilityProcessor

var availability = await _availabilityProcessor.CheckPropertyAvailabilityAsync(
    propertyId,
    checkIn,
    checkOut,
    guestsCount
);

if (availability.IsAvailable)
{
    Console.WriteLine($"متاح! أقل سعر: {availability.LowestPricePerNight}");
}
```

### المراقبة والإحصائيات
```csharp
@inject RedisIndexingSystem _indexingSystem

// الحصول على إحصائيات النظام
var stats = await _indexingSystem.GetSystemStatisticsAsync();
Console.WriteLine($"معدل النجاح: {stats.SuccessRate}%");
Console.WriteLine($"معدل إصابة الكاش: {stats.CacheHitRate}%");
Console.WriteLine($"متوسط زمن الاستجابة: {stats.AverageLatencyMs}ms");
```

## 🎯 مؤشرات الأداء المستهدفة

| المؤشر | الهدف | الوصف |
|--------|-------|-------|
| **زمن الاستجابة** | < 100ms | للبحث البسيط |
| **زمن الاستجابة** | < 300ms | للبحث المعقد |
| **معدل الكاش** | > 80% | Hit Rate |
| **الإنتاجية** | > 1000 req/sec | طلب في الثانية |
| **التوفر** | > 99.9% | Uptime |

## 🛠️ العمليات الإدارية

### إعادة بناء الفهرس الكامل
```csharp
await _indexingService.RebuildIndexAsync();
```

### تحسين قاعدة البيانات
```csharp
await _indexingService.OptimizeDatabaseAsync();
```

### مسح الكاش
```csharp
@inject IMultiLevelCache _cacheManager
await _cacheManager.FlushAsync();
```

## 📈 المراقبة والتنبيهات

### Health Check Endpoint
```
GET /health/redis
```

### الإحصائيات
```
GET /api/admin/redis/stats
```

### التنبيهات
يتم حفظ التنبيهات في Redis:
```redis
alerts:critical  → قائمة التنبيهات الحرجة
alerts:error     → قائمة أخطاء النظام
alerts:warning   → قائمة التحذيرات
alerts:info      → قائمة المعلومات
```

## 🔐 الأمان

- **تشفير الاتصال**: دعم TLS/SSL
- **المصادقة**: كلمة مرور Redis
- **التحكم في الوصول**: ACL في Redis 6+
- **حماية من الحقن**: استخدام معاملات آمنة
- **Rate Limiting**: حد أقصى للطلبات

## 🚀 التحسينات المستقبلية

1. **دعم Redis Cluster** للتوسع الأفقي
2. **Machine Learning** للتنبؤ بالبحث
3. **GraphQL API** للاستعلامات المعقدة
4. **Real-time Updates** باستخدام Redis Streams
5. **Geospatial Clustering** للخرائط
6. **Full-text Search** محسن مع RediSearch 2.0

## 📝 ملاحظات مهمة

### متطلبات Redis
- **الإصدار**: Redis 6.0+ (موصى به)
- **الذاكرة**: 2GB+ حسب حجم البيانات
- **Modules**: RediSearch (اختياري لكن موصى به)

### الأداء
- استخدم **Redis Pipeline** للعمليات المتعددة
- فعّل **Connection Pooling**
- استخدم **MessagePack** للسرعة
- راقب **Memory Fragmentation**

### النسخ الاحتياطي
- فعّل **RDB Snapshots**
- استخدم **AOF** للمتانة
- قم بنسخ احتياطي دوري

## 🤝 المساهمة

للمساهمة في تطوير النظام:
1. Fork المشروع
2. أنشئ فرع جديد
3. قم بالتعديلات
4. أرسل Pull Request

## 📞 الدعم

للحصول على الدعم:
- 📧 البريد الإلكتروني: support@yemenbooking.com
- 📱 الهاتف: +967-XXX-XXXX
- 💬 Slack: #redis-support

## 📜 الترخيص

هذا النظام محمي بحقوق الطبع والنشر © 2024 YemenBooking. جميع الحقوق محفوظة.

---

**تم التطوير بـ ❤️ بواسطة فريق YemenBooking**
