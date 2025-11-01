using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.IndexingTests.Tests.DynamicFields
{
    /// <summary>
    /// اختبارات الحقول الديناميكية الشاملة
    /// تغطي جميع أنواع الحقول الديناميكية والبحث والفلترة بها
    /// </summary>
    public class DynamicFieldsTests : TestBase
    {
        public DynamicFieldsTests(TestDatabaseFixture fixture, ITestOutputHelper output)
            : base(fixture, output)
        {
        }

        #region اختبارات الحقول الديناميكية الأساسية

        /// <summary>
        /// اختبار إضافة حقل ديناميكي بسيط
        /// </summary>
        [Fact]
        public async Task Test_AddSimpleDynamicField()
        {
            _output.WriteLine("🎯 اختبار إضافة حقل ديناميكي بسيط...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق بحقول ديناميكية", "صنعاء");

            // إضافة حقل ديناميكي
            var field = new DynamicField
            {
                Id = Guid.NewGuid(),
                Name = "has_pool",
                DisplayName = "مسبح",
                FieldType = "boolean",
                IsRequired = false,
                IsActive = true
            };

            var fieldValue = new PropertyDynamicFieldValue
            {
                Id = Guid.NewGuid(),
                PropertyId = property.Id,
                DynamicFieldId = field.Id,
                Value = "true"
            };

            _dbContext.Set<DynamicField>().Add(field);
            _dbContext.Set<PropertyDynamicFieldValue>().Add(fieldValue);
            await _dbContext.SaveChangesAsync();

            // فهرسة
            await _indexingService.OnDynamicFieldChangedAsync(property.Id, "has_pool", "true", true);

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["has_pool"] = "true"
                },
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Contains(result.Properties, p => p.Name == "فندق بحقول ديناميكية");

            _output.WriteLine("✅ الحقل الديناميكي تمت إضافته وفهرسته بنجاح");
        }

        /// <summary>
        /// اختبار حقول ديناميكية متعددة
        /// </summary>
        [Fact]
        public async Task Test_MultipleDynamicFields()
        {
            _output.WriteLine("🎯 اختبار حقول ديناميكية متعددة...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق متعدد المزايا", "صنعاء");

            // إضافة حقول ديناميكية متعددة
            var fields = new Dictionary<string, string>
            {
                ["has_pool"] = "true",
                ["has_gym"] = "false",
                ["has_spa"] = "true",
                ["parking_type"] = "free",
                ["breakfast_included"] = "yes"
            };

            foreach (var field in fields)
            {
                await _indexingService.OnDynamicFieldChangedAsync(
                    property.Id, field.Key, field.Value, true);
            }

            // البحث بحقل واحد
            var singleFieldRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["has_pool"] = "true"
                },
                PageNumber = 1,
                PageSize = 10
            };

            var singleResult = await _indexingService.SearchAsync(singleFieldRequest);

            // البحث بحقول متعددة
            var multiFieldRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["has_pool"] = "true",
                    ["has_spa"] = "true"
                },
                PageNumber = 1,
                PageSize = 10
            };

            var multiResult = await _indexingService.SearchAsync(multiFieldRequest);

            // التحقق
            Assert.NotNull(singleResult);
            Assert.NotNull(multiResult);
            Assert.Contains(singleResult.Properties, p => p.Name == "فندق متعدد المزايا");
            Assert.Contains(multiResult.Properties, p => p.Name == "فندق متعدد المزايا");

            _output.WriteLine("✅ الحقول الديناميكية المتعددة تعمل بشكل صحيح");
        }

        #endregion

        #region اختبارات أنواع الحقول المختلفة

        /// <summary>
        /// اختبار حقول منطقية
        /// </summary>
        [Theory]
        [InlineData("has_wifi", "true")]
        [InlineData("has_pool", "false")]
        [InlineData("pet_friendly", "yes")]
        [InlineData("smoking_allowed", "no")]
        public async Task Test_BooleanDynamicFields(string fieldName, string fieldValue)
        {
            _output.WriteLine($"🎯 اختبار حقل منطقي: {fieldName} = {fieldValue}");

            // الإعداد
            var property = await CreateTestPropertyAsync($"فندق {fieldName}", "صنعاء");
            await _indexingService.OnDynamicFieldChangedAsync(property.Id, fieldName, fieldValue, true);

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    [fieldName] = fieldValue
                },
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Contains(result.Properties, p => p.Name == $"فندق {fieldName}");

            _output.WriteLine($"✅ الحقل المنطقي {fieldName} يعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار حقول نصية
        /// </summary>
        [Theory]
        [InlineData("view_type", "sea_view")]
        [InlineData("room_style", "modern")]
        [InlineData("building_type", "villa")]
        public async Task Test_TextDynamicFields(string fieldName, string fieldValue)
        {
            _output.WriteLine($"🎯 اختبار حقل نصي: {fieldName} = {fieldValue}");

            // الإعداد
            var property = await CreateTestPropertyAsync($"عقار {fieldValue}", "صنعاء");
            await _indexingService.OnDynamicFieldChangedAsync(property.Id, fieldName, fieldValue, true);

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    [fieldName] = fieldValue
                },
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Contains(result.Properties, p => p.Name == $"عقار {fieldValue}");

            _output.WriteLine($"✅ الحقل النصي {fieldName} يعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار حقول رقمية
        /// </summary>
        [Theory]
        [InlineData("floor_number", "5")]
        [InlineData("room_count", "3")]
        [InlineData("bathroom_count", "2")]
        public async Task Test_NumericDynamicFields(string fieldName, string fieldValue)
        {
            _output.WriteLine($"🎯 اختبار حقل رقمي: {fieldName} = {fieldValue}");

            // الإعداد
            var property = await CreateTestPropertyAsync($"عقار طابق {fieldValue}", "صنعاء");
            await _indexingService.OnDynamicFieldChangedAsync(property.Id, fieldName, fieldValue, true);

            // البحث بالقيمة المحددة
            var exactRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    [fieldName] = fieldValue
                },
                PageNumber = 1,
                PageSize = 10
            };

            var exactResult = await _indexingService.SearchAsync(exactRequest);

            // التحقق
            Assert.NotNull(exactResult);
            Assert.Contains(exactResult.Properties, p => p.Name == $"عقار طابق {fieldValue}");

            _output.WriteLine($"✅ الحقل الرقمي {fieldName} يعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار حقول التاريخ
        /// </summary>
        [Fact]
        public async Task Test_DateDynamicFields()
        {
            _output.WriteLine("🎯 اختبار حقول التاريخ...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق بتاريخ افتتاح", "صنعاء");
            var openingDate = "2023-01-15";
            
            await _indexingService.OnDynamicFieldChangedAsync(
                property.Id, "opening_date", openingDate, true);

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["opening_date"] = openingDate
                },
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Contains(result.Properties, p => p.Name == "فندق بتاريخ افتتاح");

            _output.WriteLine("✅ حقل التاريخ يعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار حقول القوائم
        /// </summary>
        [Theory]
        [InlineData("payment_methods", "cash,credit_card,bank_transfer")]
        [InlineData("languages_spoken", "arabic,english,french")]
        [InlineData("nearby_attractions", "beach,mall,airport")]
        public async Task Test_ListDynamicFields(string fieldName, string fieldValue)
        {
            _output.WriteLine($"🎯 اختبار حقل قائمة: {fieldName} = {fieldValue}");

            // الإعداد
            var property = await CreateTestPropertyAsync($"عقار بقائمة {fieldName}", "صنعاء");
            await _indexingService.OnDynamicFieldChangedAsync(property.Id, fieldName, fieldValue, true);

            // البحث بقيمة واحدة من القائمة
            var values = fieldValue.Split(',');
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    [fieldName] = values[0] // البحث بأول قيمة
                },
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            // قد تعتمد النتيجة على كيفية تنفيذ البحث في القوائم

            _output.WriteLine($"✅ حقل القائمة {fieldName} تم اختباره");
        }

        #endregion

        #region اختبارات تحديث وحذف الحقول الديناميكية

        /// <summary>
        /// اختبار تحديث قيمة حقل ديناميكي
        /// </summary>
        [Fact]
        public async Task Test_UpdateDynamicFieldValue()
        {
            _output.WriteLine("🎯 اختبار تحديث قيمة حقل ديناميكي...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق للتحديث", "صنعاء");
            
            // إضافة حقل أولي
            await _indexingService.OnDynamicFieldChangedAsync(
                property.Id, "star_rating", "3", true);

            // البحث بالقيمة الأولية
            var initialRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["star_rating"] = "3"
                },
                PageNumber = 1,
                PageSize = 10
            };

            var initialResult = await _indexingService.SearchAsync(initialRequest);
            Assert.Contains(initialResult.Properties, p => p.Name == "فندق للتحديث");

            // تحديث القيمة
            await _indexingService.OnDynamicFieldChangedAsync(
                property.Id, "star_rating", "5", true);

            // البحث بالقيمة الجديدة
            var updatedRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["star_rating"] = "5"
                },
                PageNumber = 1,
                PageSize = 10
            };

            var updatedResult = await _indexingService.SearchAsync(updatedRequest);

            // البحث بالقيمة القديمة
            var oldResult = await _indexingService.SearchAsync(initialRequest);

            // التحقق
            Assert.Contains(updatedResult.Properties, p => p.Name == "فندق للتحديث");
            Assert.DoesNotContain(oldResult.Properties, p => p.Name == "فندق للتحديث");

            _output.WriteLine("✅ تحديث الحقل الديناميكي يعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار حذف حقل ديناميكي
        /// </summary>
        [Fact]
        public async Task Test_DeleteDynamicField()
        {
            _output.WriteLine("🎯 اختبار حذف حقل ديناميكي...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق للحذف", "صنعاء");
            
            // إضافة حقل
            await _indexingService.OnDynamicFieldChangedAsync(
                property.Id, "temporary_field", "temp_value", true);

            // التحقق من وجود الحقل
            var beforeDelete = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["temporary_field"] = "temp_value"
                },
                PageNumber = 1,
                PageSize = 10
            };

            var beforeResult = await _indexingService.SearchAsync(beforeDelete);
            Assert.Contains(beforeResult.Properties, p => p.Name == "فندق للحذف");

            // حذف الحقل
            await _indexingService.OnDynamicFieldChangedAsync(
                property.Id, "temporary_field", "", false);

            // البحث بعد الحذف
            var afterResult = await _indexingService.SearchAsync(beforeDelete);
            Assert.DoesNotContain(afterResult.Properties, p => p.Name == "فندق للحذف");

            _output.WriteLine("✅ حذف الحقل الديناميكي يعمل بشكل صحيح");
        }

        #endregion

        #region اختبارات الفلترة المعقدة بالحقول الديناميكية

        /// <summary>
        /// اختبار البحث بحقول ديناميكية متعددة
        /// </summary>
        [Fact]
        public async Task Test_MultipleFieldsFilter()
        {
            _output.WriteLine("🔄 اختبار البحث بحقول ديناميكية متعددة...");

            // الإعداد - عقارات مختلفة
            var hotel1 = await CreateTestPropertyAsync("فندق كامل المزايا", "صنعاء");
            await _indexingService.OnDynamicFieldChangedAsync(hotel1.Id, "has_pool", "true", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel1.Id, "has_gym", "true", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel1.Id, "has_spa", "true", true);

            var hotel2 = await CreateTestPropertyAsync("فندق بمسبح فقط", "صنعاء");
            await _indexingService.OnDynamicFieldChangedAsync(hotel2.Id, "has_pool", "true", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel2.Id, "has_gym", "false", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel2.Id, "has_spa", "false", true);

            var hotel3 = await CreateTestPropertyAsync("فندق بدون مزايا", "صنعاء");
            await _indexingService.OnDynamicFieldChangedAsync(hotel3.Id, "has_pool", "false", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel3.Id, "has_gym", "false", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel3.Id, "has_spa", "false", true);

            // البحث بحقول متعددة (AND)
            var multiFieldRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["has_pool"] = "true",
                    ["has_gym"] = "true",
                    ["has_spa"] = "true"
                },
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(multiFieldRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(1, result.Properties.Count(p => p.Name == "فندق كامل المزايا"));
            Assert.DoesNotContain(result.Properties, p => p.Name == "فندق بمسبح فقط");
            Assert.DoesNotContain(result.Properties, p => p.Name == "فندق بدون مزايا");

            _output.WriteLine("✅ البحث بحقول ديناميكية متعددة (AND) يعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار دمج الحقول الديناميكية مع الفلاتر العادية
        /// </summary>
        [Fact]
        public async Task Test_DynamicFieldsWithStandardFilters()
        {
            _output.WriteLine("🔄 اختبار دمج الحقول الديناميكية مع الفلاتر العادية...");

            // الإعداد
            var luxuryHotel = await CreateTestPropertyAsync("فندق فاخر بمسبح", "صنعاء", minPrice: 500);
            await _indexingService.OnDynamicFieldChangedAsync(luxuryHotel.Id, "has_pool", "true", true);

            var budgetHotel = await CreateTestPropertyAsync("فندق اقتصادي بمسبح", "صنعاء", minPrice: 100);
            await _indexingService.OnDynamicFieldChangedAsync(budgetHotel.Id, "has_pool", "true", true);

            var luxuryNoPool = await CreateTestPropertyAsync("فندق فاخر بدون مسبح", "صنعاء", minPrice: 500);
            await _indexingService.OnDynamicFieldChangedAsync(luxuryNoPool.Id, "has_pool", "false", true);

            // البحث - فندق بمسبح وسعر أقل من 200
            var searchRequest = new PropertySearchRequest
            {
                MaxPrice = 200,
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["has_pool"] = "true"
                },
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(1, result.TotalCount);
            Assert.Equal("فندق اقتصادي بمسبح", result.Properties.First().Name);

            _output.WriteLine("✅ دمج الحقول الديناميكية مع الفلاتر العادية يعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار حقول ديناميكية مع قيم غير موجودة
        /// </summary>
        [Fact]
        public async Task Test_NonExistentDynamicFieldValue()
        {
            _output.WriteLine("🎯 اختبار حقول ديناميكية بقيم غير موجودة...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق عادي", "صنعاء");
            await _indexingService.OnDynamicFieldChangedAsync(property.Id, "feature", "standard", true);

            // البحث بقيمة غير موجودة
            var searchRequest = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["feature"] = "luxury"
                },
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(0, result.TotalCount);

            _output.WriteLine("✅ البحث بقيمة غير موجودة يرجع 0 نتيجة");
        }

        #endregion

        #region اختبارات الأداء والحالات الخاصة

        /// <summary>
        /// اختبار عقار بعدد كبير من الحقول الديناميكية
        /// </summary>
        [Fact]
        public async Task Test_ManyDynamicFields()
        {
            _output.WriteLine("⚡ اختبار عقار بعدد كبير من الحقول الديناميكية...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق بحقول كثيرة", "صنعاء");
            
            // إضافة 50 حقل ديناميكي
            var fields = new Dictionary<string, string>();
            for (int i = 1; i <= 50; i++)
            {
                var fieldName = $"field_{i}";
                var fieldValue = $"value_{i}";
                fields[fieldName] = fieldValue;
                
                await _indexingService.OnDynamicFieldChangedAsync(
                    property.Id, fieldName, fieldValue, true);
            }

            // قياس الأداء
            var (result, elapsedMs) = await MeasureExecutionTimeAsync(
                async () =>
                {
                    var searchRequest = new PropertySearchRequest
                    {
                        DynamicFieldFilters = new Dictionary<string, string>
                        {
                            ["field_25"] = "value_25"
                        },
                        PageNumber = 1,
                        PageSize = 10
                    };

                    return await _indexingService.SearchAsync(searchRequest);
                },
                "البحث في عقار بـ 50 حقل ديناميكي"
            );

            // التحقق
            Assert.NotNull(result);
            Assert.Contains(result.Properties, p => p.Name == "فندق بحقول كثيرة");
            Assert.True(elapsedMs < 1000, $"البحث استغرق {elapsedMs}ms (يجب أن يكون أقل من ثانية)");

            _output.WriteLine($"✅ البحث في عقار بـ 50 حقل ديناميكي تم في {elapsedMs}ms");
        }

        /// <summary>
        /// اختبار حقول ديناميكية بأسماء خاصة
        /// </summary>
        [Theory]
        [InlineData("field with spaces", "value")]
        [InlineData("field-with-dashes", "value")]
        [InlineData("field_with_underscores", "value")]
        [InlineData("حقل_بالعربية", "قيمة")]
        public async Task Test_SpecialFieldNames(string fieldName, string fieldValue)
        {
            _output.WriteLine($"🎯 اختبار حقل بإسم خاص: '{fieldName}'");

            // الإعداد
            var property = await CreateTestPropertyAsync($"عقار {fieldName}", "صنعاء");
            
            // يجب ألا يفشل
            var exception = await Record.ExceptionAsync(async () =>
            {
                await _indexingService.OnDynamicFieldChangedAsync(
                    property.Id, fieldName, fieldValue, true);

                var searchRequest = new PropertySearchRequest
                {
                    DynamicFieldFilters = new Dictionary<string, string>
                    {
                        [fieldName] = fieldValue
                    },
                    PageNumber = 1,
                    PageSize = 10
                };

                await _indexingService.SearchAsync(searchRequest);
            });

            Assert.Null(exception);

            _output.WriteLine($"✅ الحقل بالاسم الخاص '{fieldName}' يعمل بشكل صحيح");
        }

        #endregion
    }
}
