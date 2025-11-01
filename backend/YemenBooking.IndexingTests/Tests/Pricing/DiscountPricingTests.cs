using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Xunit;
using YemenBooking.Core.Entities;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Infrastructure.Redis.Models;

namespace YemenBooking.IndexingTests.Tests.Pricing
{
    /// <summary>
    /// اختبارات الخصومات والتسعير الديناميكي
    /// يغطي جميع أنواع الخصومات والتسعير الموسمي
    /// </summary>
    public class DiscountPricingTests : IClassFixture<TestDatabaseFixture>, IAsyncLifetime
    {
        private readonly TestDatabaseFixture _fixture;
        private readonly ILogger<DiscountPricingTests> _logger;
        private readonly IRedisConnectionManager _redisManager;

        /// <summary>
        /// مُنشئ الاختبارات
        /// </summary>
        public DiscountPricingTests(TestDatabaseFixture fixture)
        {
            _fixture = fixture;
            _logger = _fixture.ServiceProvider.GetRequiredService<ILogger<DiscountPricingTests>>();
            _redisManager = _fixture.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
        }

        public async Task InitializeAsync()
        {
            _logger.LogInformation("🚀 بدء اختبارات الخصومات والتسعير الديناميكي");
            await Task.CompletedTask;
        }

        public async Task DisposeAsync()
        {
            _logger.LogInformation("🧹 تنظيف بيانات اختبارات الخصومات");
            await Task.CompletedTask;
        }

        #region اختبارات الخصومات الأساسية

        /// <summary>
        /// اختبار تطبيق خصم واحد بسيط
        /// </summary>
        [Fact]
        public async Task Should_Apply_Single_Discount_Correctly()
        {
            // Arrange
            _logger.LogInformation("اختبار تطبيق خصم واحد");
            var originalPrice = 100m;
            var discountPercentage = 20m;
            var expectedPrice = 80m;

            var discount = new Discount
            {
                Id = Guid.NewGuid(),
                Name = "خصم الصيف",
                Percentage = discountPercentage,
                StartDate = DateTime.UtcNow.AddDays(-1),
                EndDate = DateTime.UtcNow.AddDays(30),
                IsActive = true
            };

            // Act
            var discountedPrice = ApplyDiscount(originalPrice, discount);

            // Assert
            Assert.Equal(expectedPrice, discountedPrice);
            _logger.LogInformation($"✅ تم تطبيق الخصم: {originalPrice} - {discountPercentage}% = {discountedPrice}");
        }

        /// <summary>
        /// اختبار تطبيق خصومات متعددة (اختيار الأفضل)
        /// </summary>
        [Fact]
        public async Task Should_Choose_Best_Discount_From_Multiple()
        {
            // Arrange
            _logger.LogInformation("اختبار اختيار أفضل خصم من عدة خصومات");
            var originalPrice = 1000m;
            
            var discounts = new List<Discount>
            {
                new Discount
                {
                    Id = Guid.NewGuid(),
                    Name = "خصم عادي",
                    Percentage = 10,
                    StartDate = DateTime.UtcNow.AddDays(-5),
                    EndDate = DateTime.UtcNow.AddDays(5),
                    IsActive = true
                },
                new Discount
                {
                    Id = Guid.NewGuid(),
                    Name = "خصم VIP",
                    Percentage = 25, // أفضل خصم
                    StartDate = DateTime.UtcNow.AddDays(-2),
                    EndDate = DateTime.UtcNow.AddDays(3),
                    IsActive = true
                },
                new Discount
                {
                    Id = Guid.NewGuid(),
                    Name = "خصم محدود",
                    Percentage = 15,
                    StartDate = DateTime.UtcNow.AddDays(-1),
                    EndDate = DateTime.UtcNow.AddDays(1),
                    IsActive = true
                }
            };

            // Act
            var bestDiscount = GetBestActiveDiscount(discounts);
            var finalPrice = ApplyDiscount(originalPrice, bestDiscount);

            // Assert
            Assert.Equal(25m, bestDiscount.Percentage);
            Assert.Equal(750m, finalPrice);
            _logger.LogInformation($"✅ تم اختيار الخصم الأفضل: {bestDiscount.Name} ({bestDiscount.Percentage}%)");
        }

        /// <summary>
        /// اختبار خصومات منتهية الصلاحية
        /// </summary>
        [Fact]
        public async Task Should_Not_Apply_Expired_Discounts()
        {
            // Arrange
            _logger.LogInformation("اختبار عدم تطبيق خصومات منتهية");
            var originalPrice = 100m;
            
            var expiredDiscounts = new List<Discount>
            {
                new Discount
                {
                    Id = Guid.NewGuid(),
                    Name = "خصم منتهي",
                    Percentage = 50,
                    StartDate = DateTime.UtcNow.AddDays(-30),
                    EndDate = DateTime.UtcNow.AddDays(-1), // انتهى أمس
                    IsActive = false
                },
                new Discount
                {
                    Id = Guid.NewGuid(),
                    Name = "خصم مستقبلي",
                    Percentage = 30,
                    StartDate = DateTime.UtcNow.AddDays(1), // يبدأ غداً
                    EndDate = DateTime.UtcNow.AddDays(10),
                    IsActive = true
                }
            };

            // Act
            var activeDiscounts = GetActiveDiscounts(expiredDiscounts, DateTime.UtcNow);

            // Assert
            Assert.Empty(activeDiscounts);
            _logger.LogInformation("✅ لم يتم تطبيق أي خصومات منتهية أو مستقبلية");
        }

        #endregion

        #region اختبارات التسعير الموسمي

        /// <summary>
        /// اختبار التسعير في موسم الذروة
        /// </summary>
        [Fact]
        public async Task Should_Apply_Peak_Season_Pricing()
        {
            // Arrange
            _logger.LogInformation("اختبار تسعير موسم الذروة");
            var basePrice = 100m;
            var peakMultiplier = 1.5m;
            
            var seasonalPrice = new SeasonalPrice
            {
                Id = Guid.NewGuid(),
                SeasonName = "موسم الذروة",
                PriceMultiplier = peakMultiplier,
                StartDate = DateTime.UtcNow.AddDays(-10),
                EndDate = DateTime.UtcNow.AddDays(20)
            };

            // Act
            var peakPrice = ApplySeasonalPricing(basePrice, seasonalPrice, DateTime.UtcNow);

            // Assert
            Assert.Equal(150m, peakPrice);
            _logger.LogInformation($"✅ سعر موسم الذروة: {basePrice} × {peakMultiplier} = {peakPrice}");
        }

        /// <summary>
        /// اختبار التسعير في الموسم المنخفض
        /// </summary>
        [Fact]
        public async Task Should_Apply_Low_Season_Pricing()
        {
            // Arrange
            _logger.LogInformation("اختبار تسعير الموسم المنخفض");
            var basePrice = 100m;
            var lowMultiplier = 0.7m;
            
            var seasonalPrice = new SeasonalPrice
            {
                Id = Guid.NewGuid(),
                SeasonName = "موسم منخفض",
                PriceMultiplier = lowMultiplier,
                StartDate = DateTime.UtcNow.AddDays(-5),
                EndDate = DateTime.UtcNow.AddDays(25)
            };

            // Act
            var lowPrice = ApplySeasonalPricing(basePrice, seasonalPrice, DateTime.UtcNow);

            // Assert
            Assert.Equal(70m, lowPrice);
            _logger.LogInformation($"✅ سعر الموسم المنخفض: {basePrice} × {lowMultiplier} = {lowPrice}");
        }

        /// <summary>
        /// اختبار التداخل بين المواسم
        /// </summary>
        [Fact]
        public async Task Should_Handle_Overlapping_Seasons()
        {
            // Arrange
            _logger.LogInformation("اختبار التداخل بين المواسم");
            var basePrice = 100m;
            
            var seasons = new List<SeasonalPrice>
            {
                new SeasonalPrice
                {
                    Id = Guid.NewGuid(),
                    SeasonName = "موسم عادي",
                    PriceMultiplier = 1.2m,
                    StartDate = DateTime.UtcNow.AddDays(-20),
                    EndDate = DateTime.UtcNow.AddDays(10),
                    Priority = 1
                },
                new SeasonalPrice
                {
                    Id = Guid.NewGuid(),
                    SeasonName = "عطلة خاصة",
                    PriceMultiplier = 2.0m,
                    StartDate = DateTime.UtcNow.AddDays(-2),
                    EndDate = DateTime.UtcNow.AddDays(2),
                    Priority = 10 // أولوية أعلى
                }
            };

            // Act
            var applicableSeason = GetApplicableSeason(seasons, DateTime.UtcNow);
            var finalPrice = ApplySeasonalPricing(basePrice, applicableSeason, DateTime.UtcNow);

            // Assert
            Assert.Equal("عطلة خاصة", applicableSeason.SeasonName);
            Assert.Equal(200m, finalPrice);
            _logger.LogInformation($"✅ تم اختيار الموسم ذو الأولوية الأعلى: {applicableSeason.SeasonName}");
        }

        #endregion

        #region اختبارات خصومات مدة الإقامة

        /// <summary>
        /// اختبار خصم الإقامة الطويلة
        /// </summary>
        [Fact]
        public async Task Should_Apply_Long_Stay_Discount()
        {
            // Arrange
            _logger.LogInformation("اختبار خصم الإقامة الطويلة");
            var pricePerNight = 100m;
            
            var stayDiscounts = new List<LengthOfStayPrice>
            {
                new LengthOfStayPrice { MinNights = 3, MaxNights = 6, DiscountPercentage = 5 },
                new LengthOfStayPrice { MinNights = 7, MaxNights = 13, DiscountPercentage = 10 },
                new LengthOfStayPrice { MinNights = 14, MaxNights = 29, DiscountPercentage = 15 },
                new LengthOfStayPrice { MinNights = 30, MaxNights = null, DiscountPercentage = 20 }
            };

            // Act & Assert
            // إقامة ليلتين - بدون خصم
            var twoNights = CalculateLongStayPrice(pricePerNight, 2, stayDiscounts);
            Assert.Equal(200m, twoNights);

            // إقامة 5 ليالي - خصم 5%
            var fiveNights = CalculateLongStayPrice(pricePerNight, 5, stayDiscounts);
            Assert.Equal(475m, fiveNights); // 500 - 5%

            // إقامة 10 ليالي - خصم 10%
            var tenNights = CalculateLongStayPrice(pricePerNight, 10, stayDiscounts);
            Assert.Equal(900m, tenNights); // 1000 - 10%

            // إقامة 30 ليلة - خصم 20%
            var monthStay = CalculateLongStayPrice(pricePerNight, 30, stayDiscounts);
            Assert.Equal(2400m, monthStay); // 3000 - 20%

            _logger.LogInformation("✅ خصومات مدة الإقامة تعمل بشكل صحيح");
        }

        #endregion

        #region اختبارات خصومات المجموعات

        /// <summary>
        /// اختبار خصومات الحجز الجماعي
        /// </summary>
        [Fact]
        public async Task Should_Apply_Group_Booking_Discounts()
        {
            // Arrange
            _logger.LogInformation("اختبار خصومات الحجز الجماعي");
            var pricePerRoom = 100m;
            
            var groupDiscounts = new List<GroupDiscount>
            {
                new GroupDiscount { MinRooms = 3, MaxRooms = 5, DiscountPercentage = 5 },
                new GroupDiscount { MinRooms = 6, MaxRooms = 10, DiscountPercentage = 10 },
                new GroupDiscount { MinRooms = 11, MaxRooms = 20, DiscountPercentage = 15 },
                new GroupDiscount { MinRooms = 21, MaxRooms = null, DiscountPercentage = 20 }
            };

            // Act & Assert
            // غرفة واحدة - بدون خصم
            var singleRoom = CalculateGroupPrice(pricePerRoom, 1, groupDiscounts);
            Assert.Equal(100m, singleRoom);

            // 4 غرف - خصم 5%
            var fourRooms = CalculateGroupPrice(pricePerRoom, 4, groupDiscounts);
            Assert.Equal(380m, fourRooms); // 400 - 5%

            // 8 غرف - خصم 10%
            var eightRooms = CalculateGroupPrice(pricePerRoom, 8, groupDiscounts);
            Assert.Equal(720m, eightRooms); // 800 - 10%

            // 25 غرفة - خصم 20%
            var largeGroup = CalculateGroupPrice(pricePerRoom, 25, groupDiscounts);
            Assert.Equal(2000m, largeGroup); // 2500 - 20%

            _logger.LogInformation("✅ خصومات المجموعات تعمل بشكل صحيح");
        }

        #endregion

        #region اختبارات الكوبونات والعروض الخاصة

        /// <summary>
        /// اختبار تطبيق كوبون الخصم
        /// </summary>
        [Fact]
        public async Task Should_Apply_Coupon_Code_Discount()
        {
            // Arrange
            _logger.LogInformation("اختبار تطبيق كوبون الخصم");
            var originalPrice = 100m;
            
            var coupon = new CouponCode
            {
                Code = "SUMMER2024",
                DiscountPercentage = 15,
                MaxUsage = 100,
                CurrentUsage = 45,
                ValidFrom = DateTime.UtcNow.AddDays(-10),
                ValidTo = DateTime.UtcNow.AddDays(10),
                IsActive = true
            };

            // Act
            var isValid = ValidateCoupon(coupon);
            var discountedPrice = isValid ? ApplyCoupon(originalPrice, coupon) : originalPrice;

            // Assert
            Assert.True(isValid);
            Assert.Equal(85m, discountedPrice);
            _logger.LogInformation($"✅ تم تطبيق الكوبون {coupon.Code}: خصم {coupon.DiscountPercentage}%");
        }

        /// <summary>
        /// اختبار رفض كوبون منتهي أو مستنفذ
        /// </summary>
        [Fact]
        public async Task Should_Reject_Invalid_Coupons()
        {
            // Arrange
            _logger.LogInformation("اختبار رفض الكوبونات غير الصالحة");
            
            var invalidCoupons = new List<CouponCode>
            {
                // كوبون منتهي
                new CouponCode
                {
                    Code = "EXPIRED",
                    DiscountPercentage = 20,
                    ValidFrom = DateTime.UtcNow.AddDays(-30),
                    ValidTo = DateTime.UtcNow.AddDays(-1),
                    IsActive = true
                },
                // كوبون مستنفذ
                new CouponCode
                {
                    Code = "EXHAUSTED",
                    DiscountPercentage = 25,
                    MaxUsage = 10,
                    CurrentUsage = 10,
                    ValidFrom = DateTime.UtcNow.AddDays(-5),
                    ValidTo = DateTime.UtcNow.AddDays(5),
                    IsActive = true
                },
                // كوبون غير نشط
                new CouponCode
                {
                    Code = "INACTIVE",
                    DiscountPercentage = 30,
                    ValidFrom = DateTime.UtcNow.AddDays(-5),
                    ValidTo = DateTime.UtcNow.AddDays(5),
                    IsActive = false
                }
            };

            // Act & Assert
            foreach (var coupon in invalidCoupons)
            {
                var isValid = ValidateCoupon(coupon);
                Assert.False(isValid);
                _logger.LogInformation($"✅ تم رفض الكوبون غير الصالح: {coupon.Code}");
            }
        }

        #endregion

        #region Helper Methods

        private decimal ApplyDiscount(decimal originalPrice, Discount discount)
        {
            if (discount == null || !discount.IsActive) return originalPrice;
            
            var now = DateTime.UtcNow;
            if (now >= discount.StartDate && now <= discount.EndDate)
            {
                return originalPrice * (1 - discount.Percentage / 100);
            }
            
            return originalPrice;
        }

        private Discount GetBestActiveDiscount(List<Discount> discounts)
        {
            var now = DateTime.UtcNow;
            return discounts
                .Where(d => d.IsActive && now >= d.StartDate && now <= d.EndDate)
                .OrderByDescending(d => d.Percentage)
                .FirstOrDefault();
        }

        private List<Discount> GetActiveDiscounts(List<Discount> discounts, DateTime date)
        {
            return discounts
                .Where(d => d.IsActive && date >= d.StartDate && date <= d.EndDate)
                .ToList();
        }

        private decimal ApplySeasonalPricing(decimal basePrice, SeasonalPrice season, DateTime date)
        {
            if (season == null) return basePrice;
            
            if (date >= season.StartDate && date <= season.EndDate)
            {
                return basePrice * season.PriceMultiplier;
            }
            
            return basePrice;
        }

        private SeasonalPrice GetApplicableSeason(List<SeasonalPrice> seasons, DateTime date)
        {
            return seasons
                .Where(s => date >= s.StartDate && date <= s.EndDate)
                .OrderByDescending(s => s.Priority ?? 0)
                .FirstOrDefault();
        }

        private decimal CalculateLongStayPrice(decimal pricePerNight, int nights, List<LengthOfStayPrice> discounts)
        {
            var totalPrice = pricePerNight * nights;
            
            var applicable = discounts
                .Where(d => nights >= d.MinNights && (!d.MaxNights.HasValue || nights <= d.MaxNights))
                .OrderByDescending(d => d.DiscountPercentage)
                .FirstOrDefault();
            
            if (applicable != null)
            {
                totalPrice = totalPrice * (1 - applicable.DiscountPercentage / 100);
            }
            
            return totalPrice;
        }

        private decimal CalculateGroupPrice(decimal pricePerRoom, int rooms, List<GroupDiscount> discounts)
        {
            var totalPrice = pricePerRoom * rooms;
            
            var applicable = discounts
                .Where(d => rooms >= d.MinRooms && (!d.MaxRooms.HasValue || rooms <= d.MaxRooms))
                .OrderByDescending(d => d.DiscountPercentage)
                .FirstOrDefault();
            
            if (applicable != null)
            {
                totalPrice = totalPrice * (1 - applicable.DiscountPercentage / 100);
            }
            
            return totalPrice;
        }

        private bool ValidateCoupon(CouponCode coupon)
        {
            if (!coupon.IsActive) return false;
            
            var now = DateTime.UtcNow;
            if (now < coupon.ValidFrom || now > coupon.ValidTo) return false;
            
            if (coupon.MaxUsage.HasValue && coupon.CurrentUsage >= coupon.MaxUsage) return false;
            
            return true;
        }

        private decimal ApplyCoupon(decimal price, CouponCode coupon)
        {
            return price * (1 - coupon.DiscountPercentage / 100);
        }

        #endregion

        #region Test Models

        private class Discount
        {
            public Guid Id { get; set; }
            public string Name { get; set; }
            public decimal Percentage { get; set; }
            public DateTime StartDate { get; set; }
            public DateTime EndDate { get; set; }
            public bool IsActive { get; set; }
        }

        private class SeasonalPrice
        {
            public Guid Id { get; set; }
            public string SeasonName { get; set; }
            public decimal PriceMultiplier { get; set; }
            public DateTime StartDate { get; set; }
            public DateTime EndDate { get; set; }
            public int? Priority { get; set; }
        }

        private class LengthOfStayPrice
        {
            public int MinNights { get; set; }
            public int? MaxNights { get; set; }
            public decimal DiscountPercentage { get; set; }
        }

        private class GroupDiscount
        {
            public int MinRooms { get; set; }
            public int? MaxRooms { get; set; }
            public decimal DiscountPercentage { get; set; }
        }

        private class CouponCode
        {
            public string Code { get; set; }
            public decimal DiscountPercentage { get; set; }
            public int? MaxUsage { get; set; }
            public int CurrentUsage { get; set; }
            public DateTime ValidFrom { get; set; }
            public DateTime ValidTo { get; set; }
            public bool IsActive { get; set; }
        }

        #endregion
    }
}
