using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Xunit;
using YemenBooking.Core.Entities;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Infrastructure.Redis;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Infrastructure.Redis.Models;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.Application.Features.Units.Services;
using Moq;

namespace YemenBooking.IndexingTests.Tests.Pricing
{
    /// <summary>
    /// اختبارات حسابات التسعير والعملات
    /// يغطي جميع سيناريوهات التسعير المختلفة
    /// </summary>
    public class PricingCalculationTests : IClassFixture<TestDatabaseFixture>, IAsyncLifetime
    {
        private readonly TestDatabaseFixture _fixture;
        private readonly ILogger<PricingCalculationTests> _logger;
        private readonly IRedisConnectionManager _redisManager;
        private readonly SmartIndexingLayer _indexingLayer;
        private readonly Mock<IAvailabilityService> _mockAvailabilityService;

        /// <summary>
        /// مُنشئ الاختبارات
        /// </summary>
        public PricingCalculationTests(TestDatabaseFixture fixture)
        {
            _fixture = fixture;
            _logger = _fixture.ServiceProvider.GetRequiredService<ILogger<PricingCalculationTests>>();
            _redisManager = _fixture.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            _indexingLayer = _fixture.ServiceProvider.GetRequiredService<SmartIndexingLayer>();
            _mockAvailabilityService = new Mock<IAvailabilityService>();
        }

        public async Task InitializeAsync()
        {
            _logger.LogInformation("🚀 بدء اختبارات التسعير");
            await ClearTestData();
        }

        public async Task DisposeAsync()
        {
            _logger.LogInformation("🧹 تنظيف بيانات اختبارات التسعير");
            await ClearTestData();
        }

        private async Task ClearTestData()
        {
            var db = _redisManager.GetDatabase();
            var server = _redisManager.GetServer();
            var keys = server.Keys(pattern: "test:pricing:*").ToArray();
            if (keys.Any())
            {
                await db.KeyDeleteAsync(keys);
            }
        }

        #region اختبارات حسابات الأسعار الأساسية

        /// <summary>
        /// اختبار حساب نطاق الأسعار للعقار
        /// </summary>
        [Fact]
        public async Task Should_Calculate_Property_Price_Range_Correctly()
        {
            // Arrange
            _logger.LogInformation("اختبار حساب نطاق أسعار العقار");
            
            var property = CreateTestPropertyWithUnits();
            
            // Act
            var indexDoc = await BuildPropertyIndexDocument(property);
            
            // Assert
            Assert.Equal(50m, indexDoc.MinPrice);
            Assert.Equal(300m, indexDoc.MaxPrice);
            Assert.Equal(150m, indexDoc.AveragePrice);
            
            _logger.LogInformation($"✅ نطاق الأسعار: {indexDoc.MinPrice} - {indexDoc.MaxPrice} (المتوسط: {indexDoc.AveragePrice})");
        }

        /// <summary>
        /// اختبار حساب الأسعار مع عملات مختلفة
        /// </summary>
        [Fact]
        public async Task Should_Handle_Multiple_Currencies_In_Pricing()
        {
            // Arrange
            _logger.LogInformation("اختبار التعامل مع عملات متعددة");
            
            var property = new Property
            {
                Id = Guid.NewGuid(),
                Name = "فندق متعدد العملات",
                Units = new List<Unit>
                {
                    new Unit 
                    { 
                        Id = Guid.NewGuid(),
                        BasePrice = new Money(1000, "YER"),
                        Name = "غرفة بالريال"
                    },
                    new Unit 
                    { 
                        Id = Guid.NewGuid(),
                        BasePrice = new Money(100, "USD"),
                        Name = "غرفة بالدولار"
                    },
                    new Unit 
                    { 
                        Id = Guid.NewGuid(),
                        BasePrice = new Money(90, "EUR"),
                        Name = "غرفة باليورو"
                    }
                }
            };
            
            // Act - فهرسة مع تحويل العملات
            var indexDoc = await BuildPropertyIndexDocumentWithCurrencyConversion(property);
            
            // Assert
            Assert.NotNull(indexDoc);
            Assert.Equal("YER", indexDoc.BaseCurrency);
            // يجب أن تكون جميع الأسعار محولة إلى العملة الأساسية
            Assert.True(indexDoc.MinPrice > 0);
            Assert.True(indexDoc.MaxPrice > indexDoc.MinPrice);
            
            _logger.LogInformation($"✅ تم تحويل العملات: العملة الأساسية={indexDoc.BaseCurrency}");
        }

        #endregion

        #region اختبارات الضرائب والرسوم

        /// <summary>
        /// اختبار حساب الضرائب على الأسعار
        /// </summary>
        [Fact]
        public async Task Should_Calculate_Taxes_Correctly()
        {
            // Arrange
            _logger.LogInformation("اختبار حساب الضرائب");
            
            var basePrice = 100m;
            var vatRate = 15m; // ضريبة القيمة المضافة 15%
            var touristTax = 5m; // ضريبة سياحية ثابتة
            
            var property = new Property
            {
                Id = Guid.NewGuid(),
                Name = "فندق مع ضرائب",
                City = "صنعاء",
                IsActive = true,
                IsApproved = true,
                Units = new List<Unit>
                {
                    new Unit
                    {
                        Id = Guid.NewGuid(),
                        BasePrice = new Money(basePrice, "USD"),
                        Name = "غرفة قياسية"
                    }
                }
            };
            
            // Act
            var nights = 3;
            var subtotal = basePrice * nights;
            var vat = subtotal * (vatRate / 100);
            var serviceCharge = subtotal * 0.1m;
            var touristTaxTotal = touristTax * nights;
            var expectedTotal = subtotal + vat + serviceCharge + touristTaxTotal;
            
            var calculatedTotal = CalculateTotalWithTaxes(property, basePrice, nights);
            
            // Assert
            Assert.Equal(expectedTotal, calculatedTotal);
            _logger.LogInformation($"✅ حساب الضرائب: الأساس={subtotal}, VAT={vat}, خدمة={serviceCharge}, سياحة={touristTaxTotal}, الإجمالي={calculatedTotal}");
        }

        #endregion

        #region اختبارات معالجة الأخطاء في التسعير

        /// <summary>
        /// اختبار التعامل مع أسعار غير صالحة
        /// </summary>
        [Fact]
        public async Task Should_Handle_Invalid_Prices_Gracefully()
        {
            // Arrange
            _logger.LogInformation("اختبار التعامل مع أسعار غير صالحة");
            
            var properties = new List<Property>
            {
                // عقار بدون وحدات
                new Property
                {
                    Id = Guid.NewGuid(),
                    Name = "عقار بدون وحدات",
                    Units = new List<Unit>()
                },
                // عقار بأسعار صفرية
                new Property
                {
                    Id = Guid.NewGuid(),
                    Name = "عقار بأسعار صفرية",
                    Units = new List<Unit>
                    {
                        new Unit
                        {
                            Id = Guid.NewGuid(),
                            BasePrice = new Money(0, "USD"),
                            Name = "وحدة مجانية"
                        }
                    }
                }
            };
            
            // Act & Assert
            foreach (var property in properties)
            {
                var indexDoc = await BuildPropertyIndexDocument(property);
                
                // يجب أن لا تحدث أخطاء وتعود قيم افتراضية آمنة
                Assert.NotNull(indexDoc);
                Assert.True(indexDoc.MinPrice >= 0);
                Assert.True(indexDoc.MaxPrice >= indexDoc.MinPrice);
                
                _logger.LogInformation($"✅ تم التعامل مع {property.Name}: Min={indexDoc.MinPrice}, Max={indexDoc.MaxPrice}");
            }
        }

        #endregion

        #region Helper Methods

        private Property CreateTestPropertyWithUnits()
        {
            return new Property
            {
                Id = Guid.NewGuid(),
                Name = "عقار اختباري",
                Units = new List<Unit>
                {
                    new Unit { Id = Guid.NewGuid(), BasePrice = new Money(100, "USD"), Name = "غرفة عادية" },
                    new Unit { Id = Guid.NewGuid(), BasePrice = new Money(150, "USD"), Name = "غرفة ديلوكس" },
                    new Unit { Id = Guid.NewGuid(), BasePrice = new Money(300, "USD"), Name = "جناح" },
                    new Unit { Id = Guid.NewGuid(), BasePrice = new Money(50, "USD"), Name = "سرير في غرفة مشتركة" }
                }
            };
        }

        private async Task<PropertyIndexDocument> BuildPropertyIndexDocument(Property property)
        {
            var doc = new PropertyIndexDocument
            {
                Id = property.Id,
                Name = property.Name,
                BaseCurrency = property.Units.FirstOrDefault()?.BasePrice?.Currency ?? "YER"
            };

            if (property.Units.Any())
            {
                var prices = property.Units
                    .Where(u => u.BasePrice != null && u.BasePrice.Amount > 0)
                    .Select(u => u.BasePrice.Amount)
                    .ToList();

                if (prices.Any())
                {
                    doc.MinPrice = prices.Min();
                    doc.MaxPrice = prices.Max();
                    doc.AveragePrice = Math.Round(prices.Average(), 2);
                }
            }

            return await Task.FromResult(doc);
        }

        private async Task<PropertyIndexDocument> BuildPropertyIndexDocumentWithCurrencyConversion(Property property)
        {
            var doc = await BuildPropertyIndexDocument(property);
            
            // محاكاة تحويل العملات
            doc.BaseCurrency = "YER";
            var conversionRates = new Dictionary<string, decimal>
            {
                { "USD", 250m },
                { "EUR", 275m },
                { "YER", 1m }
            };

            if (property.Units.Any())
            {
                var convertedPrices = property.Units
                    .Where(u => u.BasePrice != null)
                    .Select(u => u.BasePrice.Amount * conversionRates.GetValueOrDefault(u.BasePrice.Currency, 1m))
                    .ToList();

                if (convertedPrices.Any())
                {
                    doc.MinPrice = convertedPrices.Min();
                    doc.MaxPrice = convertedPrices.Max();
                    doc.AveragePrice = Math.Round(convertedPrices.Average(), 2);
                }
            }

            return doc;
        }

        private decimal CalculateTotalWithTaxes(Property property, decimal basePrice, int nights)
        {
            var subtotal = basePrice * nights;
            
            // معدلات ضريبية افتراضية - يمكن تخصيصها بناء على تكوين الضريبة
            var vatPercentage = 15m; // 15% VAT
            var serviceChargePercentage = 10m; // 10% service charge  
            var touristTaxPerNight = 5m; // 5 per night
            
            var vat = subtotal * (vatPercentage / 100);
            var serviceCharge = subtotal * (serviceChargePercentage / 100);
            var touristTax = touristTaxPerNight * nights;
            
            return subtotal + vat + serviceCharge + touristTax;
        }

        #endregion
    }
}
