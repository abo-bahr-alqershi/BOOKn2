using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Core.ValueObjects;

namespace YemenBooking.IndexingTests.Tests.Indexing
{
    /// <summary>
    /// اختبارات فهرسة العقارات
    /// تغطي جميع سيناريوهات فهرسة العقارات والوحدات
    /// </summary>
    public class PropertyIndexingTests : TestBase
    {
        public PropertyIndexingTests(TestDatabaseFixture fixture, ITestOutputHelper output)
            : base(fixture, output)
        {
        }

        #region اختبارات الفهرسة الأساسية

        /// <summary>
        /// اختبار فهرسة عقار واحد بسيط
        /// </summary>
        [Fact]
        public async Task Test_IndexSingleProperty_Success()
        {
            _output.WriteLine("🔍 اختبار فهرسة عقار واحد...");

            // الإعداد
            var property = await CreateTestPropertyAsync(
                name: "فندق الاختبار",
                city: "صنعاء",
                minPrice: 150
            );

            // التنفيذ
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            // التحقق
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "فندق الاختبار",
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            Assert.NotNull(result);
            Assert.True(result.TotalCount >= 1);
            Assert.Contains(result.Properties, p => p.Name == "فندق الاختبار");

            _output.WriteLine($"✅ تم فهرسة العقار بنجاح - ID: {property.Id}");
        }

        /// <summary>
        /// اختبار فهرسة عقارات متعددة
        /// </summary>
        [Theory]
        [InlineData(5)]
        [InlineData(10)]
        [InlineData(20)]
        public async Task Test_IndexMultipleProperties_Success(int count)
        {
            _output.WriteLine($"🔍 اختبار فهرسة {count} عقار...");

            // الإعداد
            var properties = new List<Property>();
            for (int i = 0; i < count; i++)
            {
                var property = await CreateTestPropertyAsync(
                    name: $"عقار رقم {i + 1}",
                    city: i % 2 == 0 ? "صنعاء" : "عدن"
                );
                properties.Add(property);
            }

            // التنفيذ
            foreach (var property in properties)
            {
                await _indexingService.OnPropertyCreatedAsync(property.Id);
            }

            // التحقق
            var searchRequest = new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 50
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            Assert.NotNull(result);
            Assert.True(result.TotalCount >= count);

            _output.WriteLine($"✅ تم فهرسة {count} عقار بنجاح");
        }

        /// <summary>
        /// اختبار فهرسة عقار مع وحدات متعددة
        /// </summary>
        [Fact]
        public async Task Test_IndexPropertyWithUnits_Success()
        {
            _output.WriteLine("🔍 اختبار فهرسة عقار مع وحدات...");

            // الإعداد
            var property = await CreateTestPropertyAsync(name: "فندق مع وحدات");
            await CreateTestUnitsForPropertyAsync(property.Id, 5);

            // التنفيذ
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            // التحقق
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "فندق مع وحدات",
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            Assert.NotNull(result);
            var foundProperty = result.Properties.FirstOrDefault(p => p.Name == "فندق مع وحدات");
            Assert.NotNull(foundProperty);
            Assert.True(foundProperty.UnitsCount > 0);

            _output.WriteLine($"✅ تم فهرسة العقار مع {foundProperty.UnitsCount} وحدة");
        }

        /// <summary>
        /// اختبار فهرسة عقار غير نشط
        /// </summary>
        [Fact]
        public async Task Test_IndexInactiveProperty_NotInSearchResults()
        {
            _output.WriteLine("🔍 اختبار فهرسة عقار غير نشط...");

            // الإعداد
            var property = await CreateTestPropertyAsync(
                name: "عقار غير نشط",
                isActive: false
            );

            // التنفيذ
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            // التحقق
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "عقار غير نشط",
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            Assert.NotNull(result);
            Assert.DoesNotContain(result.Properties, p => p.Name == "عقار غير نشط");

            _output.WriteLine("✅ العقار غير النشط لا يظهر في نتائج البحث");
        }

        /// <summary>
        /// اختبار فهرسة عقار غير معتمد
        /// </summary>
        [Fact]
        public async Task Test_IndexUnapprovedProperty_NotInSearchResults()
        {
            _output.WriteLine("🔍 اختبار فهرسة عقار غير معتمد...");

            // الإعداد
            var property = await CreateTestPropertyAsync(
                name: "عقار غير معتمد",
                isApproved: false
            );

            // التنفيذ
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            // التحقق
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "عقار غير معتمد",
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            Assert.NotNull(result);
            Assert.DoesNotContain(result.Properties, p => p.Name == "عقار غير معتمد");

            _output.WriteLine("✅ العقار غير المعتمد لا يظهر في نتائج البحث");
        }

        #endregion

        #region اختبارات التحديث والحذف

        /// <summary>
        /// اختبار تحديث عقار مفهرس
        /// </summary>
        [Fact]
        public async Task Test_UpdateIndexedProperty_Success()
        {
            _output.WriteLine("🔍 اختبار تحديث عقار مفهرس...");

            // الإعداد
            var property = await CreateTestPropertyAsync(
                name: "عقار قبل التحديث",
                city: "صنعاء"
            );
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            // التحديث
            property.Name = "عقار بعد التحديث";
            property.City = "عدن";
            _dbContext.Properties.Update(property);
            await _dbContext.SaveChangesAsync();

            await _indexingService.OnPropertyUpdatedAsync(property.Id);

            // التحقق
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "عقار بعد التحديث",
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            Assert.NotNull(result);
            var updatedProperty = result.Properties.FirstOrDefault(p => p.Id == property.Id.ToString());
            Assert.NotNull(updatedProperty);
            Assert.Equal("عقار بعد التحديث", updatedProperty.Name);
            Assert.Equal("عدن", updatedProperty.City);

            _output.WriteLine("✅ تم تحديث العقار في الفهرس بنجاح");
        }

        /// <summary>
        /// اختبار حذف عقار مفهرس
        /// </summary>
        [Fact]
        public async Task Test_DeleteIndexedProperty_Success()
        {
            _output.WriteLine("🔍 اختبار حذف عقار مفهرس...");

            // الإعداد - استخدام اسم فريد للعقار
            var uniqueName = $"عقار_حذف_{Guid.NewGuid():N}";
            var property = await CreateTestPropertyAsync(name: uniqueName);
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            // التحقق من وجود العقار
            var searchBeforeDelete = new PropertySearchRequest
            {
                SearchText = uniqueName,
                PageNumber = 1,
                PageSize = 10
            };

            var resultBefore = await _indexingService.SearchAsync(searchBeforeDelete);
            Assert.Contains(resultBefore.Properties, p => p.Id == property.Id.ToString());

            // الحذف
            await _indexingService.OnPropertyDeletedAsync(property.Id);

            // التحقق من عدم وجود العقار
            var resultAfter = await _indexingService.SearchAsync(searchBeforeDelete);
            Assert.DoesNotContain(resultAfter.Properties, p => p.Id == property.Id.ToString());

            _output.WriteLine("✅ تم حذف العقار من الفهرس بنجاح");
        }

        /// <summary>
        /// اختبار تحديث عقار من نشط إلى غير نشط
        /// </summary>
        [Fact]
        public async Task Test_DeactivateProperty_RemovedFromSearch()
        {
            _output.WriteLine("🔍 اختبار إلغاء تنشيط عقار...");

            // الإعداد
            var property = await CreateTestPropertyAsync(
                name: "عقار نشط",
                isActive: true
            );
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            // التحقق من وجوده
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "عقار نشط",
                PageNumber = 1,
                PageSize = 10
            };

            var resultBefore = await _indexingService.SearchAsync(searchRequest);
            Assert.Contains(resultBefore.Properties, p => p.Name == "عقار نشط");

            // إلغاء التنشيط
            property.IsActive = false;
            _dbContext.Properties.Update(property);
            await _dbContext.SaveChangesAsync();
            await _indexingService.OnPropertyUpdatedAsync(property.Id);

            // التحقق من عدم وجوده
            var resultAfter = await _indexingService.SearchAsync(searchRequest);
            Assert.DoesNotContain(resultAfter.Properties, p => p.Name == "عقار نشط");

            _output.WriteLine("✅ تم إزالة العقار غير النشط من البحث");
        }

        #endregion

        #region اختبارات الوحدات

        /// <summary>
        /// اختبار إضافة وحدة لعقار مفهرس
        /// </summary>
        [Fact]
        public async Task Test_AddUnitToIndexedProperty_Success()
        {
            _output.WriteLine("🔍 اختبار إضافة وحدة لعقار مفهرس...");

            // الإعداد
            var property = await CreateTestPropertyAsync(name: "عقار بدون وحدات");
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            // إضافة وحدة
            var unit = new Unit
            {
                Id = Guid.NewGuid(),
                PropertyId = property.Id,
                Name = "وحدة جديدة",
                UnitTypeId = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                MaxCapacity = 4,
                IsAvailable = true,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                BasePrice = new Money(200, "YER")
            };

            _dbContext.Units.Add(unit);
            await _dbContext.SaveChangesAsync();

            await _indexingService.OnUnitCreatedAsync(unit.Id, property.Id);

            // التحقق
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "عقار بدون وحدات",
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);
            var updatedProperty = result.Properties.FirstOrDefault(p => p.Id == property.Id.ToString());

            Assert.NotNull(updatedProperty);
            Assert.True(updatedProperty.UnitsCount > 0);

            _output.WriteLine($"✅ تم تحديث عدد الوحدات: {updatedProperty.UnitsCount}");
        }

        /// <summary>
        /// اختبار تحديث وحدة في عقار مفهرس
        /// </summary>
        [Fact]
        public async Task Test_UpdateUnitInIndexedProperty_Success()
        {
            _output.WriteLine("🔍 اختبار تحديث وحدة في عقار مفهرس...");

            // الإعداد
            var property = await CreateTestPropertyAsync(name: "عقار مع وحدة");
            var unit = new Unit
            {
                Id = Guid.NewGuid(),
                PropertyId = property.Id,
                Name = "وحدة قبل التحديث",
                UnitTypeId = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                MaxCapacity = 2,
                IsAvailable = true,
                IsActive = true,
                BasePrice = new Money(100, "YER")
            };

            _dbContext.Units.Add(unit);
            await _dbContext.SaveChangesAsync();

            await _indexingService.OnPropertyCreatedAsync(property.Id);

            // التحديث
            unit.MaxCapacity = 4;
            unit.BasePrice = new Money(200, "YER");
            _dbContext.Units.Update(unit);
            await _dbContext.SaveChangesAsync();

            await _indexingService.OnUnitUpdatedAsync(unit.Id, property.Id);

            // التحقق
            var searchRequest = new PropertySearchRequest
            {
                GuestsCount = 4,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);
            var foundProperty = result.Properties.FirstOrDefault(p => p.Id == property.Id.ToString());

            Assert.NotNull(foundProperty);
            Assert.True(foundProperty.MaxCapacity >= 4);

            _output.WriteLine("✅ تم تحديث بيانات الوحدة في الفهرس");
        }

        /// <summary>
        /// اختبار حذف وحدة من عقار مفهرس
        /// </summary>
        [Fact]
        public async Task Test_DeleteUnitFromIndexedProperty_Success()
        {
            _output.WriteLine("🔍 اختبار حذف وحدة من عقار مفهرس...");

            // الإعداد
            var property = await CreateTestPropertyAsync(name: "عقار مع وحدتين");
            await CreateTestUnitsForPropertyAsync(property.Id, 2);
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            // الحصول على وحدة للحذف
            var unit = _dbContext.Units.First(u => u.PropertyId == property.Id);
            var unitId = unit.Id;

            // الحذف
            _dbContext.Units.Remove(unit);
            await _dbContext.SaveChangesAsync();

            await _indexingService.OnUnitDeletedAsync(unitId, property.Id);

            // التحقق
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "عقار مع وحدتين",
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);
            var updatedProperty = result.Properties.FirstOrDefault(p => p.Id == property.Id.ToString());

            Assert.NotNull(updatedProperty);
            Assert.Equal(1, updatedProperty.UnitsCount);

            _output.WriteLine($"✅ تم تحديث عدد الوحدات بعد الحذف: {updatedProperty.UnitsCount}");
        }

        #endregion

        #region اختبارات إعادة البناء

        /// <summary>
        /// اختبار إعادة بناء الفهرس بالكامل
        /// </summary>
        [Fact]
        public async Task Test_RebuildIndex_Success()
        {
            _output.WriteLine("🔍 اختبار إعادة بناء الفهرس بالكامل...");

            // الإعداد - إنشاء بيانات
            var properties = await CreateComprehensiveTestDataAsync();
            _output.WriteLine($"📊 تم إنشاء {properties.Count} عقار للاختبار");

            // التنفيذ - إعادة البناء
            var (_, elapsedMs) = await MeasureExecutionTimeAsync(
                async () =>
                {
                    await _indexingService.RebuildIndexAsync();
                    return true;
                },
                "إعادة بناء الفهرس"
            );

            // التحقق
            var searchRequest = new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 100
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            Assert.NotNull(result);
            Assert.True(result.TotalCount >= properties.Count(p => p.IsActive && p.IsApproved));
            Assert.True(elapsedMs < 10000, $"إعادة البناء استغرقت {elapsedMs}ms (يجب أن تكون أقل من 10 ثانية)");

            _output.WriteLine($"✅ تم إعادة بناء الفهرس بنجاح - {result.TotalCount} عقار مفهرس");
        }

        /// <summary>
        /// اختبار إعادة البناء مع بيانات تالفة
        /// </summary>
        [Fact]
        public async Task Test_RebuildIndexWithCorruptedData_HandlesGracefully()
        {
            _output.WriteLine("🔍 اختبار إعادة البناء مع بيانات تالفة...");

            // الإعداد - إنشاء عقار بدون owner
            // ✅ إنشاء عقار بجميع الحقول المطلوبة حتى لو كانت بيانات "تالفة"
            var property = new Property
            {
                Id = Guid.NewGuid(),
                Name = "عقار تالف",
                City = "صنعاء",
                Currency = "YER",  // ✅ حقل مطلوب
                Address = "عنوان غير صحيح",  // ✅ حقل مطلوب
                Description = "وصف تالف",  // ✅ حقل مطلوب
                TypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"),
                OwnerId = Guid.Empty, // معرف غير صحيح - هذا هو "التلف" المقصود
                IsActive = true,
                IsApproved = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _dbContext.Properties.Add(property);
            await _dbContext.SaveChangesAsync();

            // التنفيذ - يجب ألا يفشل
            var exception = await Record.ExceptionAsync(async () =>
            {
                await _indexingService.RebuildIndexAsync();
            });

            Assert.Null(exception);

            _output.WriteLine("✅ تم التعامل مع البيانات التالفة بنجاح");
        }

        #endregion

        #region اختبارات التزامن

        /// <summary>
        /// اختبار فهرسة متزامنة لعدة عقارات
        /// </summary>
        [Fact]
        public async Task Test_ConcurrentIndexing_Success()
        {
            _output.WriteLine("🔍 اختبار الفهرسة المتزامنة...");

            // الإعداد
            var properties = new List<Property>();
            for (int i = 0; i < 10; i++)
            {
                properties.Add(await CreateTestPropertyAsync(
                    name: $"عقار متزامن {i}",
                    city: "صنعاء"
                ));
            }

            // التنفيذ المتزامن
            var tasks = properties.Select(p => 
                Task.Run(async () => await _indexingService.OnPropertyCreatedAsync(p.Id))
            ).ToArray();

            await Task.WhenAll(tasks);

            // التحقق
            var searchRequest = new PropertySearchRequest
            {
                City = "صنعاء",
                PageNumber = 1,
                PageSize = 20
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            Assert.NotNull(result);
            Assert.True(result.TotalCount >= 10);

            _output.WriteLine($"✅ تمت الفهرسة المتزامنة لـ {properties.Count} عقار");
        }

        /// <summary>
        /// اختبار تحديثات متزامنة على نفس العقار
        /// </summary>
        [Fact]
        public async Task Test_ConcurrentUpdatesOnSameProperty_Success()
        {
            _output.WriteLine("🔍 اختبار التحديثات المتزامنة على نفس العقار...");

            // الإعداد
            var property = await CreateTestPropertyAsync(name: "عقار للتحديث المتزامن");
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            // التحديثات المتزامنة
            var updateTasks = new List<Task>();
            for (int i = 0; i < 5; i++)
            {
                var localI = i;
                updateTasks.Add(Task.Run(async () =>
                {
                    property.Description = $"وصف محدث {localI}";
                    await _indexingService.OnPropertyUpdatedAsync(property.Id);
                }));
            }

            await Task.WhenAll(updateTasks);

            // التحقق - يجب أن يبقى العقار موجوداً وصحيحاً
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "عقار للتحديث المتزامن",
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            Assert.NotNull(result);
            Assert.Single(result.Properties.Where(p => p.Name == "عقار للتحديث المتزامن"));

            _output.WriteLine("✅ تم التعامل مع التحديثات المتزامنة بنجاح");
        }

        #endregion
    }
}
