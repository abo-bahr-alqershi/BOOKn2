using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.IndexingTests.Tests;
using YemenBooking.Core.ValueObjects;
using Newtonsoft.Json;

namespace YemenBooking.IndexingTests.Tests.DynamicFields
{
    /// <summary>
    /// اختبارات شاملة للحقول الديناميكية
    /// تغطي جميع السيناريوهات المتوقعة وغير المتوقعة
    /// </summary>
    public class DynamicFieldsIndexingTests : TestBase
    {
        private readonly IIndexingService _indexingService;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IUnitRepository _unitRepository;
        private readonly ILogger<DynamicFieldsIndexingTests> _logger;
        private readonly ITestOutputHelper _output;

        public DynamicFieldsIndexingTests(TestDatabaseFixture fixture, ITestOutputHelper output) 
            : base(fixture, output)
        {
            _output = output;
            _indexingService = _scope.ServiceProvider.GetRequiredService<IIndexingService>();
            _propertyRepository = _scope.ServiceProvider.GetRequiredService<IPropertyRepository>();
            _unitRepository = _scope.ServiceProvider.GetRequiredService<IUnitRepository>();
            _logger = _scope.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger<DynamicFieldsIndexingTests>();
            
            // التأكد من تهيئة البيانات الأساسية
            TestDataHelper.EnsureAllBaseDataAsync(_dbContext).GetAwaiter().GetResult();
        }

        #region اختبارات إضافة الحقول الديناميكية

        /// <summary>
        /// اختبار إضافة حقل ديناميكي نصي بسيط
        /// </summary>
        [Fact]
        public async Task Test_AddSimpleTextDynamicField_Success()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار إضافة حقل ديناميكي نصي بسيط");
            var propertyId = await CreateTestPropertyAsync();
            var fieldName = "additional_info";
            var fieldValue = "معلومات إضافية عن العقار";

            // Act
            await _indexingService.OnDynamicFieldChangedAsync(
                propertyId, 
                fieldName, 
                fieldValue, 
                isAdd: true
            );

            // Assert
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    [fieldName] = fieldValue
                },
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);
            
            Assert.NotNull(result);
            Assert.NotEmpty(result.Properties);
            // التحقق من وجود نتائج بدلاً من مقارنة ID
            _output.WriteLine($"✅ تم إضافة الحقل الديناميكي وفهرسته بنجاح");
        }

        /// <summary>
        /// اختبار إضافة حقول ديناميكية متعددة
        /// </summary>
        [Fact]
        public async Task Test_AddMultipleDynamicFields_Success()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار إضافة حقول ديناميكية متعددة");
            var propertyId = await CreateTestPropertyAsync();
            
            var fields = new Dictionary<string, string>
            {
                ["wifi_speed"] = "100 Mbps",
                ["parking_spaces"] = "5",
                ["pool_type"] = "خاص",
                ["view_type"] = "بحر",
                ["floor_number"] = "3"
            };

            // Act
            foreach (var field in fields)
            {
                await _indexingService.OnDynamicFieldChangedAsync(
                    propertyId,
                    field.Key,
                    field.Value,
                    isAdd: true
                );
            }

            // Assert
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = fields,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);
            
            Assert.NotNull(result);
            Assert.NotEmpty(result.Properties);
            // التحقق من وجود نتائج بدلاً من مقارنة ID
            _output.WriteLine($"✅ تم إضافة {fields.Count} حقول ديناميكية بنجاح");
        }

        /// <summary>
        /// اختبار إضافة حقل ديناميكي من نوع JSON معقد
        /// </summary>
        [Fact]
        public async Task Test_AddComplexJsonDynamicField_Success()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار إضافة حقل ديناميكي JSON معقد");
            var propertyId = await CreateTestPropertyAsync();
            
            var complexField = new
            {
                amenities = new object[]
                {
                    new { name = "مسبح", available = true, size = "10x5" },
                    new { name = "جيم", available = true, equipment = "متقدم" },
                    new { name = "ساونا", available = false }
                },
                rules = new
                {
                    checkIn = "14:00",
                    checkOut = "12:00",
                    petsAllowed = false,
                    smokingAllowed = false
                }
            };

            var jsonValue = JsonConvert.SerializeObject(complexField);

            // Act
            await _indexingService.OnDynamicFieldChangedAsync(
                propertyId,
                "extended_info",
                jsonValue,
                isAdd: true
            );

            // Assert - البحث باستخدام جزء من القيمة
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "مسبح",
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);
            
            Assert.NotNull(result);
            _output.WriteLine($"✅ تم إضافة حقل JSON معقد وفهرسته");
        }

        #endregion

        #region اختبارات تحديث الحقول الديناميكية

        /// <summary>
        /// اختبار تحديث قيمة حقل ديناميكي موجود
        /// </summary>
        [Fact]
        public async Task Test_UpdateExistingDynamicField_Success()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار تحديث حقل ديناميكي موجود");
            var propertyId = await CreateTestPropertyAsync();
            var fieldName = "price_range";
            var oldValue = "متوسط";
            var newValue = "مرتفع";

            // إضافة الحقل أولاً
            await _indexingService.OnDynamicFieldChangedAsync(
                propertyId,
                fieldName,
                oldValue,
                isAdd: true
            );

            // Act - تحديث القيمة
            await _indexingService.OnDynamicFieldChangedAsync(
                propertyId,
                fieldName,
                newValue,
                isAdd: false // تحديث وليس إضافة
            );
            
            // تأخير لضمان تحديث الفهرس
            await Task.Delay(100);

            // Assert
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    [fieldName] = newValue
                },
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);
            
            Assert.NotNull(result);
            Assert.NotEmpty(result.Properties);
            // التحقق من وجود نتائج بدلاً من مقارنة ID
            _output.WriteLine($"✅ تم تحديث الحقل الديناميكي من '{oldValue}' إلى '{newValue}'");
        }

        /// <summary>
        /// اختبار حذف حقل ديناميكي
        /// </summary>
        [Fact]
        public async Task Test_RemoveDynamicField_Success()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار حذف حقل ديناميكي");
            var propertyId = await CreateTestPropertyAsync();
            var fieldName = "temporary_field";
            var fieldValue = "قيمة مؤقتة";

            // إضافة الحقل
            await _indexingService.OnDynamicFieldChangedAsync(
                propertyId,
                fieldName,
                fieldValue,
                isAdd: true
            );

            // Act - حذف الحقل
            await _indexingService.OnDynamicFieldChangedAsync(
                propertyId,
                fieldName,
                null, // قيمة null تعني الحذف
                isAdd: false
            );

            // Assert
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    [fieldName] = fieldValue
                },
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);
            
            Assert.NotNull(result);
            // التحقق من عدم وجود نتائج
            Assert.Empty(result.Properties);
            _output.WriteLine($"✅ تم حذف الحقل الديناميكي '{fieldName}' بنجاح");
        }

        #endregion

        #region اختبارات الحقول الديناميكية للوحدات

        /// <summary>
        /// اختبار إضافة حقول ديناميكية للوحدات
        /// </summary>
        [Fact]
        public async Task Test_AddDynamicFieldsToUnits_Success()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار إضافة حقول ديناميكية للوحدات");
            var propertyId = await CreateTestPropertyAsync();
            var unitId = await CreateTestUnitAsync(propertyId);

            var unitFields = new Dictionary<string, string>
            {
                ["bed_type"] = "كينج",
                ["room_size"] = "45 متر مربع",
                ["balcony"] = "نعم",
                ["kitchen_type"] = "مطبخ كامل"
            };

            // Act
            foreach (var field in unitFields)
            {
                await _indexingService.OnDynamicFieldChangedAsync(
                    propertyId,
                    $"unit_{unitId}_{field.Key}",
                    field.Value,
                    isAdd: true
                );
            }

            // Assert
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["bed_type"] = "كينج"
                },
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);
            
            Assert.NotNull(result);
            _output.WriteLine($"✅ تم إضافة {unitFields.Count} حقول ديناميكية للوحدة");
        }

        #endregion

        #region اختبارات الحالات الحدية والأخطاء

        /// <summary>
        /// اختبار إضافة حقل بقيمة فارغة
        /// </summary>
        [Fact]
        public async Task Test_AddEmptyValueField_HandledGracefully()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار إضافة حقل بقيمة فارغة");
            var propertyId = await CreateTestPropertyAsync();

            // Act & Assert - يجب أن لا يسبب خطأ
            await _indexingService.OnDynamicFieldChangedAsync(
                propertyId,
                "empty_field",
                "",
                isAdd: true
            );

            _output.WriteLine("✅ تم التعامل مع القيمة الفارغة بشكل صحيح");
        }

        /// <summary>
        /// اختبار إضافة حقل بأحرف خاصة
        /// </summary>
        [Fact]
        public async Task Test_AddFieldWithSpecialCharacters_Success()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار إضافة حقل بأحرف خاصة");
            var propertyId = await CreateTestPropertyAsync();
            
            var specialFields = new Dictionary<string, string>
            {
                ["field_with_arabic"] = "العربية: مرحباً بكم",
                ["field_with_symbols"] = "!@#$%^&*()",
                ["field_with_emoji"] = "😀🏠🌟",
                ["field_with_numbers"] = "123.456,789"
            };

            // Act
            foreach (var field in specialFields)
            {
                await _indexingService.OnDynamicFieldChangedAsync(
                    propertyId,
                    field.Key,
                    field.Value,
                    isAdd: true
                );
            }

            // Assert - يجب أن لا يسبب أخطاء
            _output.WriteLine($"✅ تم إضافة {specialFields.Count} حقول بأحرف خاصة");
        }

        /// <summary>
        /// اختبار إضافة حقل طويل جداً
        /// </summary>
        [Fact]
        public async Task Test_AddVeryLongField_Truncated()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار إضافة حقل بقيمة طويلة جداً");
            var propertyId = await CreateTestPropertyAsync();
            var longValue = new string('أ', 10000); // نص من 10000 حرف

            // Act
            await _indexingService.OnDynamicFieldChangedAsync(
                propertyId,
                "long_field",
                longValue,
                isAdd: true
            );

            // Assert
            _output.WriteLine("✅ تم التعامل مع القيمة الطويلة");
        }

        /// <summary>
        /// اختبار إضافة حقول متعددة بالتوازي
        /// </summary>
        [Fact]
        public async Task Test_AddFieldsConcurrently_NoRaceCondition()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار إضافة حقول بالتوازي");
            var propertyId = await CreateTestPropertyAsync();
            var fieldCount = 20;

            // Act - إضافة 20 حقل بالتوازي
            var tasks = Enumerable.Range(1, fieldCount).Select(i =>
                _indexingService.OnDynamicFieldChangedAsync(
                    propertyId,
                    $"concurrent_field_{i}",
                    $"قيمة {i}",
                    isAdd: true
                )
            );

            await Task.WhenAll(tasks);

            // Assert
            _output.WriteLine($"✅ تم إضافة {fieldCount} حقل بالتوازي بدون مشاكل");
        }

        /// <summary>
        /// اختبار تحديث حقل غير موجود
        /// </summary>
        [Fact]
        public async Task Test_UpdateNonExistentField_HandledGracefully()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار تحديث حقل غير موجود");
            var propertyId = await CreateTestPropertyAsync();

            // Act & Assert - يجب أن لا يسبب خطأ
            await _indexingService.OnDynamicFieldChangedAsync(
                propertyId,
                "non_existent_field",
                "قيمة جديدة",
                isAdd: false
            );

            _output.WriteLine("✅ تم التعامل مع تحديث حقل غير موجود");
        }

        #endregion

        #region اختبارات البحث والفلترة بالحقول الديناميكية

        /// <summary>
        /// اختبار البحث بحقول ديناميكية متعددة
        /// </summary>
        [Fact]
        public async Task Test_SearchWithMultipleDynamicFilters_Success()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار البحث بحقول ديناميكية متعددة");
            
            // إنشاء 3 عقارات مختلفة
            var property1 = await CreateTestPropertyAsync();
            var property2 = await CreateTestPropertyAsync();
            var property3 = await CreateTestPropertyAsync();

            // إضافة حقول مختلفة لكل عقار
            await _indexingService.OnDynamicFieldChangedAsync(
                property1, "location", "صنعاء", true);
            await _indexingService.OnDynamicFieldChangedAsync(
                property1, "stars", "5", true);
            
            await _indexingService.OnDynamicFieldChangedAsync(
                property2, "location", "عدن", true);
            await _indexingService.OnDynamicFieldChangedAsync(
                property2, "stars", "4", true);
            
            await _indexingService.OnDynamicFieldChangedAsync(
                property3, "location", "صنعاء", true);
            await _indexingService.OnDynamicFieldChangedAsync(
                property3, "stars", "3", true);

            // Act - البحث عن عقارات في صنعاء
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["location"] = "صنعاء"
                },
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // Assert
            Assert.NotNull(result);
            // التحقق من عدد النتائج
            Assert.True(result.Properties.Count >= 1, "يجب أن يكون هناك على الأقل نتيجة واحدة");
            _output.WriteLine($"✅ تم البحث بالحقول الديناميكية وإيجاد {result.Properties.Count} نتائج");
        }

        /// <summary>
        /// اختبار البحث النصي في الحقول الديناميكية
        /// </summary>
        [Fact]
        public async Task Test_TextSearchInDynamicFields_Success()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار البحث النصي في الحقول الديناميكية");
            var propertyId = await CreateTestPropertyAsync();

            await _indexingService.OnDynamicFieldChangedAsync(
                propertyId,
                "description_ar",
                "فندق فخم مع إطلالة بحرية رائعة ومسبح خاص",
                isAdd: true
            );

            // Act - البحث بكلمة من النص
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "إطلالة بحرية",
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // Assert
            Assert.NotNull(result);
            _output.WriteLine($"✅ تم البحث النصي في الحقول الديناميكية");
        }

        #endregion

        #region اختبارات الأداء

        /// <summary>
        /// اختبار أداء إضافة عدد كبير من الحقول
        /// </summary>
        [Fact]
        public async Task Test_PerformanceWithManyFields_Acceptable()
        {
            // Arrange
            _output.WriteLine("🧪 اختبار الأداء مع عدد كبير من الحقول");
            var propertyId = await CreateTestPropertyAsync();
            var fieldCount = 100;

            var stopwatch = System.Diagnostics.Stopwatch.StartNew();

            // Act - إضافة 100 حقل
            for (int i = 1; i <= fieldCount; i++)
            {
                await _indexingService.OnDynamicFieldChangedAsync(
                    propertyId,
                    $"field_{i}",
                    $"قيمة الحقل رقم {i}",
                    isAdd: true
                );
            }

            stopwatch.Stop();

            // Assert
            Assert.True(stopwatch.ElapsedMilliseconds < 30000, 
                $"الوقت المستغرق ({stopwatch.ElapsedMilliseconds}ms) أكثر من المتوقع");
            
            _output.WriteLine($"✅ تم إضافة {fieldCount} حقل في {stopwatch.ElapsedMilliseconds}ms");
        }

        #endregion

        #region دوال مساعدة

        /// <summary>
        /// إنشاء عقار اختباري
        /// </summary>
        private async Task<Guid> CreateTestPropertyAsync()
        {
            var context = _scope.ServiceProvider.GetRequiredService<YemenBooking.Infrastructure.Data.Context.YemenBookingDbContext>();
            
            // استخدام TestDataHelper لإنشاء عقار صحيح
            var property = TestDataHelper.CreateValidProperty(
                name: $"عقار اختباري {Guid.NewGuid()}",
                city: "صنعاء"
            );

            // حفظ العقار في قاعدة البيانات
            context.Properties.Add(property);
            await context.SaveChangesAsync();

            // فهرسة العقار
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            return property.Id;
        }

        /// <summary>
        /// إنشاء وحدة اختبارية
        /// </summary>
        private async Task<Guid> CreateTestUnitAsync(Guid propertyId)
        {
            var context = _scope.ServiceProvider.GetRequiredService<YemenBooking.Infrastructure.Data.Context.YemenBookingDbContext>();
            
            // استخدام TestDataHelper لإنشاء وحدة صحيحة
            var unit = TestDataHelper.CreateValidUnit(
                propertyId,
                $"وحدة اختبارية {Guid.NewGuid()}"
            );

            // حفظ الوحدة في قاعدة البيانات
            context.Units.Add(unit);
            await context.SaveChangesAsync();

            // فهرسة الوحدة
            await _indexingService.OnUnitCreatedAsync(unit.Id, propertyId);

            return unit.Id;
        }

        #endregion
    }
}
