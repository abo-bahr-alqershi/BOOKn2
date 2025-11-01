using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Infrastructure.Redis.Core;

namespace YemenBooking.IndexingTests.Tests.DynamicFields
{
    /// <summary>
    /// اختبارات بسيطة للحقول الديناميكية بدون الاعتماد على قاعدة البيانات
    /// </summary>
    public class SimpleDynamicFieldTests : IClassFixture<SimpleTestFixture>
    {
        private readonly SimpleTestFixture _fixture;
        private readonly ITestOutputHelper _output;
        private readonly ILogger<SimpleDynamicFieldTests> _logger;
        private IDatabase _redisDb;
        private IRedisConnectionManager _redisManager;

        public SimpleDynamicFieldTests(SimpleTestFixture fixture, ITestOutputHelper output)
        {
            _fixture = fixture;
            _output = output;
            _logger = _fixture.ServiceProvider.GetRequiredService<ILogger<SimpleDynamicFieldTests>>();
            
            // محاولة الاتصال بـ Redis مباشرة
            try
            {
                var configuration = _fixture.Configuration;
                var redisConnection = configuration["Redis:Connection"] ?? "localhost:6379";
                var redis = ConnectionMultiplexer.Connect(redisConnection);
                _redisDb = redis.GetDatabase();
                _output.WriteLine($"✅ تم الاتصال بـ Redis: {redisConnection}");
            }
            catch (Exception ex)
            {
                _output.WriteLine($"⚠️ فشل الاتصال بـ Redis: {ex.Message}");
                _redisDb = null;
            }
        }

        /// <summary>
        /// اختبار الاتصال بـ Redis
        /// </summary>
        [Fact]
        public async Task Test_RedisConnection()
        {
            if (_redisDb == null)
            {
                _output.WriteLine("⚠️ تخطي الاختبار - Redis غير متصل");
                return;
            }

            // اختبار بسيط للكتابة والقراءة
            var testKey = $"test:connection:{Guid.NewGuid()}";
            var testValue = "اختبار الاتصال";

            await _redisDb.StringSetAsync(testKey, testValue, TimeSpan.FromSeconds(10));
            var result = await _redisDb.StringGetAsync(testKey);

            Assert.Equal(testValue, result.ToString());
            _output.WriteLine("✅ Redis يعمل بشكل صحيح");
            
            // تنظيف
            await _redisDb.KeyDeleteAsync(testKey);
        }

        /// <summary>
        /// اختبار إضافة حقل ديناميكي مباشرة في Redis
        /// </summary>
        [Fact]
        public async Task Test_AddDynamicField_Direct()
        {
            if (_redisDb == null)
            {
                _output.WriteLine("⚠️ تخطي الاختبار - Redis غير متصل");
                return;
            }

            // Arrange
            var propertyId = Guid.NewGuid();
            var fieldName = "test_field";
            var fieldValue = "قيمة اختبارية";
            var dynamicFieldsKey = $"property:{propertyId}:dynamic_fields";

            // Act - إضافة الحقل مباشرة
            await _redisDb.HashSetAsync(dynamicFieldsKey, fieldName, fieldValue);
            
            // إضافة إلى فهرس القيم
            var valueIndexKey = $"dynamic_value:{fieldName}:{fieldValue.ToLower()}";
            await _redisDb.SetAddAsync(valueIndexKey, propertyId.ToString());

            // Assert
            var storedValue = await _redisDb.HashGetAsync(dynamicFieldsKey, fieldName);
            Assert.Equal(fieldValue, storedValue.ToString());
            
            var properties = await _redisDb.SetMembersAsync(valueIndexKey);
            Assert.Contains(propertyId.ToString(), properties.Select(p => p.ToString()));
            
            _output.WriteLine($"✅ تم إضافة الحقل الديناميكي '{fieldName}' بنجاح");

            // تنظيف
            await _redisDb.KeyDeleteAsync(dynamicFieldsKey);
            await _redisDb.KeyDeleteAsync(valueIndexKey);
        }

        /// <summary>
        /// اختبار البحث بالحقول الديناميكية
        /// </summary>
        [Fact]
        public async Task Test_SearchByDynamicField()
        {
            if (_redisDb == null)
            {
                _output.WriteLine("⚠️ تخطي الاختبار - Redis غير متصل");
                return;
            }

            // Arrange - إنشاء 3 عقارات مع حقول مختلفة
            var property1 = Guid.NewGuid();
            var property2 = Guid.NewGuid();
            var property3 = Guid.NewGuid();
            
            var fieldName = "city_area";
            
            // إضافة حقول لكل عقار
            await AddDynamicFieldAsync(property1, fieldName, "الشمال");
            await AddDynamicFieldAsync(property2, fieldName, "الجنوب");
            await AddDynamicFieldAsync(property3, fieldName, "الشمال");

            // Act - البحث عن العقارات في الشمال
            var searchValue = "الشمال";
            var valueIndexKey = $"dynamic_value:{fieldName}:{searchValue.ToLower()}";
            var results = await _redisDb.SetMembersAsync(valueIndexKey);

            // Assert
            var propertyIds = results.Select(r => r.ToString()).ToList();
            Assert.Equal(2, propertyIds.Count);
            Assert.Contains(property1.ToString(), propertyIds);
            Assert.Contains(property3.ToString(), propertyIds);
            Assert.DoesNotContain(property2.ToString(), propertyIds);
            
            _output.WriteLine($"✅ تم العثور على {propertyIds.Count} عقارات في '{searchValue}'");

            // تنظيف
            await CleanupDynamicFieldAsync(property1, fieldName, "الشمال");
            await CleanupDynamicFieldAsync(property2, fieldName, "الجنوب");
            await CleanupDynamicFieldAsync(property3, fieldName, "الشمال");
        }

        /// <summary>
        /// اختبار تحديث حقل ديناميكي
        /// </summary>
        [Fact]
        public async Task Test_UpdateDynamicField()
        {
            if (_redisDb == null)
            {
                _output.WriteLine("⚠️ تخطي الاختبار - Redis غير متصل");
                return;
            }

            // Arrange
            var propertyId = Guid.NewGuid();
            var fieldName = "status";
            var oldValue = "متاح";
            var newValue = "محجوز";

            // إضافة الحقل الأول
            await AddDynamicFieldAsync(propertyId, fieldName, oldValue);

            // Act - تحديث القيمة
            var dynamicFieldsKey = $"property:{propertyId}:dynamic_fields";
            
            // حذف من الفهرس القديم
            var oldIndexKey = $"dynamic_value:{fieldName}:{oldValue.ToLower()}";
            await _redisDb.SetRemoveAsync(oldIndexKey, propertyId.ToString());
            
            // تحديث القيمة
            await _redisDb.HashSetAsync(dynamicFieldsKey, fieldName, newValue);
            
            // إضافة للفهرس الجديد
            var newIndexKey = $"dynamic_value:{fieldName}:{newValue.ToLower()}";
            await _redisDb.SetAddAsync(newIndexKey, propertyId.ToString());

            // Assert
            var currentValue = await _redisDb.HashGetAsync(dynamicFieldsKey, fieldName);
            Assert.Equal(newValue, currentValue.ToString());
            
            var oldIndexMembers = await _redisDb.SetMembersAsync(oldIndexKey);
            Assert.DoesNotContain(propertyId.ToString(), oldIndexMembers.Select(m => m.ToString()));
            
            var newIndexMembers = await _redisDb.SetMembersAsync(newIndexKey);
            Assert.Contains(propertyId.ToString(), newIndexMembers.Select(m => m.ToString()));
            
            _output.WriteLine($"✅ تم تحديث الحقل من '{oldValue}' إلى '{newValue}'");

            // تنظيف
            await CleanupDynamicFieldAsync(propertyId, fieldName, newValue);
        }

        /// <summary>
        /// اختبار حذف حقل ديناميكي
        /// </summary>
        [Fact]
        public async Task Test_RemoveDynamicField()
        {
            if (_redisDb == null)
            {
                _output.WriteLine("⚠️ تخطي الاختبار - Redis غير متصل");
                return;
            }

            // Arrange
            var propertyId = Guid.NewGuid();
            var fieldName = "temporary";
            var fieldValue = "مؤقت";

            await AddDynamicFieldAsync(propertyId, fieldName, fieldValue);

            // Act - حذف الحقل
            var dynamicFieldsKey = $"property:{propertyId}:dynamic_fields";
            var valueIndexKey = $"dynamic_value:{fieldName}:{fieldValue.ToLower()}";
            
            await _redisDb.HashDeleteAsync(dynamicFieldsKey, fieldName);
            await _redisDb.SetRemoveAsync(valueIndexKey, propertyId.ToString());

            // Assert
            var exists = await _redisDb.HashExistsAsync(dynamicFieldsKey, fieldName);
            Assert.False(exists);
            
            var indexMembers = await _redisDb.SetMembersAsync(valueIndexKey);
            Assert.DoesNotContain(propertyId.ToString(), indexMembers.Select(m => m.ToString()));
            
            _output.WriteLine($"✅ تم حذف الحقل '{fieldName}' بنجاح");

            // تنظيف إضافي
            await _redisDb.KeyDeleteAsync(dynamicFieldsKey);
            await _redisDb.KeyDeleteAsync(valueIndexKey);
        }

        /// <summary>
        /// اختبار الأداء مع عدد كبير من الحقول
        /// </summary>
        [Fact]
        public async Task Test_PerformanceWithManyFields()
        {
            if (_redisDb == null)
            {
                _output.WriteLine("⚠️ تخطي الاختبار - Redis غير متصل");
                return;
            }

            // Arrange
            var propertyId = Guid.NewGuid();
            var fieldCount = 50; // عدد أقل للاختبار السريع
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();

            // Act - إضافة الحقول
            var tasks = new List<Task>();
            for (int i = 0; i < fieldCount; i++)
            {
                tasks.Add(AddDynamicFieldAsync(propertyId, $"field_{i}", $"value_{i}"));
            }
            
            await Task.WhenAll(tasks);
            stopwatch.Stop();

            // Assert
            var dynamicFieldsKey = $"property:{propertyId}:dynamic_fields";
            var fieldsCount = await _redisDb.HashLengthAsync(dynamicFieldsKey);
            Assert.Equal(fieldCount, fieldsCount);
            
            Assert.True(stopwatch.ElapsedMilliseconds < 5000, 
                $"الوقت المستغرق ({stopwatch.ElapsedMilliseconds}ms) أكثر من المتوقع");
            
            _output.WriteLine($"✅ تم إضافة {fieldCount} حقل في {stopwatch.ElapsedMilliseconds}ms");

            // تنظيف
            for (int i = 0; i < fieldCount; i++)
            {
                await CleanupDynamicFieldAsync(propertyId, $"field_{i}", $"value_{i}");
            }
        }

        #region دوال مساعدة

        /// <summary>
        /// إضافة حقل ديناميكي
        /// </summary>
        private async Task AddDynamicFieldAsync(Guid propertyId, string fieldName, string fieldValue)
        {
            var dynamicFieldsKey = $"property:{propertyId}:dynamic_fields";
            await _redisDb.HashSetAsync(dynamicFieldsKey, fieldName, fieldValue);
            
            var valueIndexKey = $"dynamic_value:{fieldName}:{fieldValue.ToLower()}";
            await _redisDb.SetAddAsync(valueIndexKey, propertyId.ToString());
        }

        /// <summary>
        /// تنظيف حقل ديناميكي
        /// </summary>
        private async Task CleanupDynamicFieldAsync(Guid propertyId, string fieldName, string fieldValue)
        {
            var dynamicFieldsKey = $"property:{propertyId}:dynamic_fields";
            await _redisDb.KeyDeleteAsync(dynamicFieldsKey);
            
            var valueIndexKey = $"dynamic_value:{fieldName}:{fieldValue.ToLower()}";
            await _redisDb.KeyDeleteAsync(valueIndexKey);
        }

        #endregion
    }
}
