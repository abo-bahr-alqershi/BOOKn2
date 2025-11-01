using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Features.Pricing.Services;

namespace YemenBooking.Infrastructure.Redis.Availability
{
    /// <summary>
    /// معالج الإتاحة المحسن - الطبقة الثالثة في النظام
    /// يتعامل مع فحص الإتاحة والتسعير الديناميكي
    /// </summary>
    public class AvailabilityProcessor
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly IAvailabilityService _availabilityService;
        private readonly IPricingService _pricingService;
        private readonly ILogger<AvailabilityProcessor> _logger;
        private readonly IDatabase _db;

        /// <summary>
        /// مُنشئ معالج الإتاحة
        /// </summary>
        public AvailabilityProcessor(
            IRedisConnectionManager redisManager,
            IAvailabilityService availabilityService,
            IPricingService pricingService,
            ILogger<AvailabilityProcessor> logger)
        {
            _redisManager = redisManager;
            _availabilityService = availabilityService;
            _pricingService = pricingService;
            _logger = logger;
            _db = _redisManager.GetDatabase();
        }

        #region فحص الإتاحة

        /// <summary>
        /// فحص إتاحة العقار في فترة معينة
        /// </summary>
        public async Task<PropertyAvailabilityResult> CheckPropertyAvailabilityAsync(
            Guid propertyId,
            DateTime checkIn,
            DateTime checkOut,
            int guestsCount,
            string unitTypeId = null,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation(
                    "فحص إتاحة العقار {PropertyId} من {CheckIn} إلى {CheckOut} لـ {Guests} ضيف",
                    propertyId, checkIn, checkOut, guestsCount);

                var result = new PropertyAvailabilityResult
                {
                    PropertyId = propertyId,
                    CheckIn = checkIn,
                    CheckOut = checkOut,
                    RequestedGuests = guestsCount
                };

                // 1. جلب جميع وحدات العقار
                var unitsKey = RedisKeySchemas.GetPropertyUnitsKey(propertyId);
                var unitIds = await _db.SetMembersAsync(unitsKey);

                if (!unitIds.Any())
                {
                    result.IsAvailable = false;
                    result.Message = "لا توجد وحدات في هذا العقار";
                    return result;
                }

                // 2. فحص كل وحدة
                var availableUnits = new List<AvailableUnit>();
                var pipeline = _db.CreateBatch();
                var availabilityTasks = new Dictionary<string, Task<SortedSetEntry[]>>();

                foreach (var unitId in unitIds)
                {
                    var availKey = RedisKeySchemas.GetUnitAvailabilityKey(Guid.Parse(unitId));
                    availabilityTasks[unitId] = pipeline.SortedSetRangeByScoreWithScoresAsync(
                        availKey, 
                        0, 
                        checkOut.Ticks);
                }

                pipeline.Execute();
                await Task.WhenAll(availabilityTasks.Values);

                // 3. معالجة النتائج
                foreach (var kvp in availabilityTasks)
                {
                    var unitId = Guid.Parse(kvp.Key);
                    var ranges = await kvp.Value;
                    
                    // فحص الوحدة
                    var unitAvailable = await CheckUnitAvailabilityAsync(
                        unitId, 
                        checkIn, 
                        checkOut, 
                        guestsCount,
                        unitTypeId,
                        ranges);

                    if (unitAvailable != null)
                    {
                        availableUnits.Add(unitAvailable);
                    }
                }

                // 4. تحديد النتيجة
                result.IsAvailable = availableUnits.Any();
                result.AvailableUnits = availableUnits;
                result.TotalAvailableUnits = availableUnits.Count;

                if (result.IsAvailable)
                {
                    result.Message = $"يوجد {result.TotalAvailableUnits} وحدة متاحة";
                    
                    // حساب أقل سعر
                    result.LowestPricePerNight = availableUnits.Min(u => u.PricePerNight);
                    result.Currency = availableUnits.First().Currency;
                }
                else
                {
                    result.Message = "لا توجد وحدات متاحة في الفترة المطلوبة";
                }

                _logger.LogInformation(
                    "نتيجة فحص الإتاحة: {IsAvailable} - {Message}",
                    result.IsAvailable, result.Message);

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في فحص إتاحة العقار {PropertyId}", propertyId);
                throw;
            }
        }

        /// <summary>
        /// فحص إتاحة وحدة محددة
        /// </summary>
        private async Task<AvailableUnit> CheckUnitAvailabilityAsync(
            Guid unitId,
            DateTime checkIn,
            DateTime checkOut,
            int guestsCount,
            string requestedUnitTypeId,
            SortedSetEntry[] availabilityRanges)
        {
            try
            {
                // 1. جلب معلومات الوحدة
                var unitKey = RedisKeySchemas.GetUnitKey(unitId);
                var unitData = await _db.HashGetAllAsync(unitKey);
                
                if (unitData.Length == 0)
                {
                    return null;
                }

                var unitInfo = ParseUnitInfo(unitData);

                // 2. فحص نوع الوحدة
                if (!string.IsNullOrWhiteSpace(requestedUnitTypeId) && 
                    unitInfo.UnitTypeId != requestedUnitTypeId)
                {
                    return null;
                }

                // 3. فحص السعة
                if (unitInfo.MaxCapacity < guestsCount)
                {
                    return null;
                }

                // 4. فحص الحالة النشطة
                if (!unitInfo.IsActive || !unitInfo.IsAvailable)
                {
                    return null;
                }

                // 5. فحص الإتاحة في التواريخ المطلوبة
                var isAvailable = CheckDateRangeAvailability(
                    availabilityRanges,
                    checkIn,
                    checkOut);

                if (!isAvailable)
                {
                    return null;
                }

                // 6. حساب السعر
                var nights = (int)(checkOut - checkIn).TotalDays;
                var totalPrice = await CalculateUnitPriceAsync(unitId, checkIn, checkOut);
                var pricePerNight = nights > 0 ? totalPrice / nights : totalPrice;

                // 7. بناء نتيجة الوحدة المتاحة
                return new AvailableUnit
                {
                    UnitId = unitId,
                    UnitName = unitInfo.Name,
                    UnitTypeId = unitInfo.UnitTypeId,
                    UnitTypeName = unitInfo.UnitTypeName,
                    MaxCapacity = unitInfo.MaxCapacity,
                    TotalPrice = totalPrice,
                    PricePerNight = pricePerNight,
                    Currency = unitInfo.Currency,
                    Nights = nights
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في فحص إتاحة الوحدة {UnitId}", unitId);
                return null;
            }
        }

        /// <summary>
        /// فحص الإتاحة لقائمة من التواريخ
        /// </summary>
        public async Task<BatchAvailabilityResult> CheckBatchAvailabilityAsync(
            List<AvailabilityCheckRequest> requests,
            CancellationToken cancellationToken = default)
        {
            var results = new List<PropertyAvailabilityResult>();
            var semaphore = new SemaphoreSlim(10); // معالجة 10 طلبات بالتوازي

            var tasks = requests.Select(async request =>
            {
                await semaphore.WaitAsync(cancellationToken);
                try
                {
                    var result = await CheckPropertyAvailabilityAsync(
                        request.PropertyId,
                        request.CheckIn,
                        request.CheckOut,
                        request.GuestsCount,
                        request.UnitTypeId,
                        cancellationToken);
                    
                    return result;
                }
                finally
                {
                    semaphore.Release();
                }
            });

            results.AddRange(await Task.WhenAll(tasks));

            return new BatchAvailabilityResult
            {
                Results = results,
                TotalChecked = requests.Count,
                TotalAvailable = results.Count(r => r.IsAvailable)
            };
        }

        #endregion

        #region حساب الأسعار

        /// <summary>
        /// حساب سعر الوحدة للفترة المطلوبة
        /// </summary>
        private async Task<decimal> CalculateUnitPriceAsync(
            Guid unitId,
            DateTime checkIn,
            DateTime checkOut)
        {
            try
            {
                // 1. التحقق من الكاش أولاً
                var cacheKey = string.Format(
                    RedisKeySchemas.PRICING_CACHE, 
                    unitId, 
                    checkIn, 
                    checkOut);
                
                var cachedPrice = await _db.StringGetAsync(cacheKey);
                if (!cachedPrice.IsNullOrEmpty && decimal.TryParse(cachedPrice, out var cached))
                {
                    _logger.LogDebug("إرجاع السعر من الكاش للوحدة {UnitId}", unitId);
                    return cached;
                }

                // 2. جلب قواعد التسعير
                var pricingKey = RedisKeySchemas.GetUnitPricingKey(unitId);
                var pricingData = await _db.StringGetAsync(pricingKey);
                
                decimal totalPrice;
                
                if (!pricingData.IsNullOrEmpty)
                {
                    // حساب السعر باستخدام القواعد المخزنة
                    totalPrice = await CalculatePriceWithRulesAsync(
                        unitId,
                        pricingData,
                        checkIn,
                        checkOut);
                }
                else
                {
                    // استخدام خدمة التسعير الأساسية
                    totalPrice = await _pricingService.CalculatePriceAsync(
                        unitId, 
                        checkIn, 
                        checkOut);
                }

                // 3. حفظ في الكاش
                await _db.StringSetAsync(
                    cacheKey, 
                    totalPrice.ToString(), 
                    TimeSpan.FromHours(1));

                return totalPrice;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في حساب سعر الوحدة {UnitId}", unitId);
                
                // في حالة الخطأ، احسب السعر الأساسي
                return await GetBasePriceAsync(unitId);
            }
        }

        /// <summary>
        /// حساب السعر باستخدام القواعد المخزنة
        /// </summary>
        private async Task<decimal> CalculatePriceWithRulesAsync(
            Guid unitId,
            RedisValue pricingData,
            DateTime checkIn,
            DateTime checkOut)
        {
            // تحليل قواعد التسعير من البيانات المسلسلة
            var pricingDoc = MessagePack.MessagePackSerializer.Deserialize<PricingIndexDocument>(pricingData);
            
            var nights = (int)(checkOut - checkIn).TotalDays;
            decimal totalPrice = 0;

            for (var date = checkIn; date < checkOut; date = date.AddDays(1))
            {
                decimal dayPrice = pricingDoc.BasePrice;

                // تطبيق التسعير الموسمي
                var seasonalRule = pricingDoc.SeasonalRules?
                    .FirstOrDefault(r => date >= r.StartDate && date <= r.EndDate);
                
                if (seasonalRule != null)
                {
                    if (seasonalRule.PriceType == "fixed")
                    {
                        dayPrice = seasonalRule.PriceOrPercentage;
                    }
                    else if (seasonalRule.PriceType == "percentage")
                    {
                        dayPrice = pricingDoc.BasePrice * (1 + seasonalRule.PriceOrPercentage / 100);
                    }
                }

                // تطبيق تسعير نهاية الأسبوع
                var weekendRule = pricingDoc.WeekendRules?
                    .FirstOrDefault(r => r.WeekendDays.Contains(date.DayOfWeek));
                
                if (weekendRule != null)
                {
                    if (weekendRule.PriceType == "fixed")
                    {
                        dayPrice = weekendRule.PriceOrPercentage;
                    }
                    else if (weekendRule.PriceType == "percentage")
                    {
                        dayPrice = dayPrice * (1 + weekendRule.PriceOrPercentage / 100);
                    }
                }

                // تطبيق التسعير الخاص
                var specialRule = pricingDoc.SpecialRules?
                    .FirstOrDefault(r => date >= r.StartDate && date <= r.EndDate);
                
                if (specialRule != null)
                {
                    if (specialRule.PriceType == "fixed")
                    {
                        dayPrice = specialRule.PriceOrPercentage;
                    }
                    else if (specialRule.PriceType == "percentage")
                    {
                        dayPrice = dayPrice * (1 + specialRule.PriceOrPercentage / 100);
                    }
                }

                totalPrice += dayPrice;
            }

            // تطبيق خصومات الإقامة الطويلة
            var longStayDiscount = pricingDoc.LongStayDiscounts?
                .Where(d => nights >= d.MinNights)
                .OrderByDescending(d => d.MinNights)
                .FirstOrDefault();

            if (longStayDiscount != null)
            {
                totalPrice = totalPrice * (1 - longStayDiscount.DiscountPercentage / 100);
            }

            // إضافة الرسوم الإضافية
            if (pricingDoc.AdditionalFees != null)
            {
                foreach (var fee in pricingDoc.AdditionalFees.Where(f => !f.IsOptional))
                {
                    switch (fee.FeeType)
                    {
                        case "per_night":
                            totalPrice += fee.Amount * nights;
                            break;
                        case "per_stay":
                            totalPrice += fee.Amount;
                            break;
                    }
                }
            }

            return Math.Round(totalPrice, 2);
        }

        /// <summary>
        /// الحصول على السعر الأساسي للوحدة
        /// </summary>
        private async Task<decimal> GetBasePriceAsync(Guid unitId)
        {
            var unitKey = RedisKeySchemas.GetUnitKey(unitId);
            var basePrice = await _db.HashGetAsync(unitKey, "base_price");
            
            if (!basePrice.IsNullOrEmpty && decimal.TryParse(basePrice, out var price))
            {
                return price;
            }

            return 0;
        }

        #endregion

        #region تحديث الإتاحة

        /// <summary>
        /// تحديث إتاحة وحدة
        /// </summary>
        public async Task UpdateUnitAvailabilityAsync(
            Guid unitId,
            List<AvailabilityRange> availableRanges,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation(
                    "تحديث إتاحة الوحدة {UnitId} مع {Count} فترة",
                    unitId, availableRanges.Count);

                var availKey = RedisKeySchemas.GetUnitAvailabilityKey(unitId);
                var batch = _db.CreateBatch();

                // حذف الإتاحة القديمة
                _ = batch.KeyDeleteAsync(availKey);

                // إضافة الفترات الجديدة
                foreach (var range in availableRanges.Where(r => r.IsBookable))
                {
                    var rangeData = range.ToRedisFormat();
                    _ = batch.SortedSetAddAsync(availKey, rangeData, range.StartDate.Ticks);

                    // إضافة إلى فهرس التاريخ
                    var currentDate = range.StartDate.Date;
                    while (currentDate <= range.EndDate.Date)
                    {
                        var dateKey = string.Format(RedisKeySchemas.AVAILABILITY_DATE, currentDate);
                        _ = batch.SetAddAsync(dateKey, unitId.ToString());
                        currentDate = currentDate.AddDays(1);
                    }
                }

                batch.Execute();

                _logger.LogInformation("✅ تم تحديث إتاحة الوحدة {UnitId}", unitId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث إتاحة الوحدة {UnitId}", unitId);
                throw;
            }
        }

        /// <summary>
        /// حجز وحدة وتحديث الإتاحة
        /// </summary>
        public async Task<bool> BookUnitAsync(
            Guid unitId,
            DateTime checkIn,
            DateTime checkOut,
            Guid bookingId,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation(
                    "حجز الوحدة {UnitId} من {CheckIn} إلى {CheckOut}",
                    unitId, checkIn, checkOut);

                // 1. التحقق من الإتاحة مرة أخرى
                var availKey = RedisKeySchemas.GetUnitAvailabilityKey(unitId);
                var ranges = await _db.SortedSetRangeByScoreWithScoresAsync(
                    availKey,
                    0,
                    checkOut.Ticks);

                var isAvailable = CheckDateRangeAvailability(ranges, checkIn, checkOut);
                
                if (!isAvailable)
                {
                    _logger.LogWarning("الوحدة {UnitId} غير متاحة للحجز", unitId);
                    return false;
                }

                // 2. تحديث الإتاحة (إزالة الفترة المحجوزة)
                var tran = _db.CreateTransaction();
                
                // البحث عن الفترة التي تحتوي على التواريخ المطلوبة
                foreach (var range in ranges)
                {
                    var rangeData = AvailabilityRange.FromRedisFormat(range.Element);
                    
                    if (rangeData.StartDate <= checkIn && rangeData.EndDate >= checkOut)
                    {
                        // إزالة الفترة القديمة
                        _ = tran.SortedSetRemoveAsync(availKey, range.Element);
                        
                        // إضافة الفترات الجديدة (قبل وبعد الحجز)
                        if (rangeData.StartDate < checkIn)
                        {
                            var beforeRange = new AvailabilityRange
                            {
                                StartDate = rangeData.StartDate,
                                EndDate = checkIn.AddDays(-1),
                                IsBookable = true
                            };
                            _ = tran.SortedSetAddAsync(availKey, beforeRange.ToRedisFormat(), beforeRange.StartDate.Ticks);
                        }
                        
                        if (rangeData.EndDate > checkOut)
                        {
                            var afterRange = new AvailabilityRange
                            {
                                StartDate = checkOut.AddDays(1),
                                EndDate = rangeData.EndDate,
                                IsBookable = true
                            };
                            _ = tran.SortedSetAddAsync(availKey, afterRange.ToRedisFormat(), afterRange.StartDate.Ticks);
                        }
                        
                        break;
                    }
                }

                // 3. إزالة من فهرس التواريخ
                var currentDate = checkIn.Date;
                while (currentDate <= checkOut.Date)
                {
                    var dateKey = string.Format(RedisKeySchemas.AVAILABILITY_DATE, currentDate);
                    _ = tran.SetRemoveAsync(dateKey, unitId.ToString());
                    currentDate = currentDate.AddDays(1);
                }

                // 4. حفظ معلومات الحجز
                var bookingKey = $"booking:{bookingId}";
                _ = tran.HashSetAsync(bookingKey, new[]
                {
                    new HashEntry("unit_id", unitId.ToString()),
                    new HashEntry("check_in", checkIn.Ticks),
                    new HashEntry("check_out", checkOut.Ticks),
                    new HashEntry("status", "confirmed"),
                    new HashEntry("created_at", DateTime.UtcNow.Ticks)
                });

                var result = await tran.ExecuteAsync();
                
                if (result)
                {
                    _logger.LogInformation("✅ تم حجز الوحدة {UnitId} بنجاح", unitId);
                }
                else
                {
                    _logger.LogWarning("❌ فشل حجز الوحدة {UnitId}", unitId);
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في حجز الوحدة {UnitId}", unitId);
                throw;
            }
        }

        #endregion

        #region دوال مساعدة

        /// <summary>
        /// فحص توفر فترة زمنية في نطاقات الإتاحة
        /// </summary>
        private bool CheckDateRangeAvailability(
            SortedSetEntry[] ranges,
            DateTime checkIn,
            DateTime checkOut)
        {
            foreach (var range in ranges)
            {
                var rangeData = AvailabilityRange.FromRedisFormat(range.Element);
                
                // إذا وجدت فترة تحتوي على التواريخ المطلوبة بالكامل
                if (rangeData.StartDate <= checkIn && rangeData.EndDate >= checkOut)
                {
                    return true;
                }
            }

            return false;
        }

        /// <summary>
        /// تحليل معلومات الوحدة من Redis
        /// </summary>
        private UnitInfo ParseUnitInfo(HashEntry[] unitData)
        {
            var dict = unitData.ToDictionary(x => x.Name.ToString(), x => x.Value);
            
            return new UnitInfo
            {
                Id = Guid.Parse(dict.GetValueOrDefault("id", Guid.Empty.ToString())),
                Name = dict.GetValueOrDefault("name"),
                UnitTypeId = dict.GetValueOrDefault("unit_type_id"),
                UnitTypeName = dict.GetValueOrDefault("unit_type"),
                MaxCapacity = int.Parse(dict.GetValueOrDefault("max_capacity", "0")),
                BasePrice = decimal.Parse(dict.GetValueOrDefault("base_price", "0")),
                Currency = dict.GetValueOrDefault("currency", "YER"),
                IsActive = dict.GetValueOrDefault("is_active") == "1",
                IsAvailable = dict.GetValueOrDefault("is_available") == "1"
            };
        }

        #endregion

        #region نماذج البيانات الداخلية

        /// <summary>
        /// معلومات الوحدة
        /// </summary>
        private class UnitInfo
        {
            public Guid Id { get; set; }
            public string Name { get; set; }
            public string UnitTypeId { get; set; }
            public string UnitTypeName { get; set; }
            public int MaxCapacity { get; set; }
            public decimal BasePrice { get; set; }
            public string Currency { get; set; }
            public bool IsActive { get; set; }
            public bool IsAvailable { get; set; }
        }

        #endregion
    }

    #region نماذج النتائج

    /// <summary>
    /// نتيجة فحص إتاحة العقار
    /// </summary>
    public class PropertyAvailabilityResult
    {
        public Guid PropertyId { get; set; }
        public DateTime CheckIn { get; set; }
        public DateTime CheckOut { get; set; }
        public int RequestedGuests { get; set; }
        public bool IsAvailable { get; set; }
        public string Message { get; set; }
        public List<AvailableUnit> AvailableUnits { get; set; } = new();
        public int TotalAvailableUnits { get; set; }
        public decimal? LowestPricePerNight { get; set; }
        public string Currency { get; set; }
    }

    /// <summary>
    /// معلومات الوحدة المتاحة
    /// </summary>
    public class AvailableUnit
    {
        public Guid UnitId { get; set; }
        public string UnitName { get; set; }
        public string UnitTypeId { get; set; }
        public string UnitTypeName { get; set; }
        public int MaxCapacity { get; set; }
        public decimal TotalPrice { get; set; }
        public decimal PricePerNight { get; set; }
        public string Currency { get; set; }
        public int Nights { get; set; }
    }

    /// <summary>
    /// طلب فحص الإتاحة
    /// </summary>
    public class AvailabilityCheckRequest
    {
        public Guid PropertyId { get; set; }
        public DateTime CheckIn { get; set; }
        public DateTime CheckOut { get; set; }
        public int GuestsCount { get; set; }
        public string UnitTypeId { get; set; }
    }

    /// <summary>
    /// نتيجة فحص الإتاحة الجماعي
    /// </summary>
    public class BatchAvailabilityResult
    {
        public List<PropertyAvailabilityResult> Results { get; set; } = new();
        public int TotalChecked { get; set; }
        public int TotalAvailable { get; set; }
    }

    #endregion
}
