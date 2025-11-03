using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using MessagePack;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Redis.Indexing
{
    /// <summary>
    /// طبقة الفهرسة الذكية - الطبقة الأولى في النظام
    /// مسؤولة عن إنشاء وتحديث وإدارة جميع الفهارس في Redis
    /// </summary>
    public class SmartIndexingLayer
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ILogger<SmartIndexingLayer> _logger;
        private IDatabase _db;
        private readonly SemaphoreSlim _indexingLock;
        private readonly object _dbLock = new object();
        
        /// <summary>
        /// مُنشئ طبقة الفهرسة الذكية
        /// </summary>
        public SmartIndexingLayer(
            IRedisConnectionManager redisManager,
            IPropertyRepository propertyRepository,
            ILogger<SmartIndexingLayer> logger)
        {
            _redisManager = redisManager;
            _propertyRepository = propertyRepository;
            _logger = logger;
            // تأجيل الحصول على Database لتجنب مشاكل التزامن
            _db = null;
            _indexingLock = new SemaphoreSlim(3, 3); // حد أقصى 3 عمليات فهرسة متزامنة لتحسين الاستقرار
        }

        private IDatabase GetDatabase()
        {
            if (_db != null)
                return _db;
                
            lock (_dbLock)
            {
                if (_db == null)
                {
                    _db = _redisManager.GetDatabase();
                }
            }
            return _db;
        }

        #region عمليات الفهرسة الأساسية

        /// <summary>
        /// فهرسة عقار جديد بالكامل
        /// يتم استخدامها عند إضافة عقار جديد أو إعادة الفهرسة
        /// </summary>
        public async Task<bool> IndexPropertyAsync(
            Property property, 
            CancellationToken cancellationToken = default)
        {
            // التحقق من صحة المدخلات
            if (property == null)
            {
                _logger.LogWarning("محاولة فهرسة عقار null");
                return false;
            }
            
            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                _logger.LogInformation("بدء فهرسة العقار: {PropertyId} - {PropertyName}", 
                    property.Id, property.Name);

                // 1. بناء نموذج الفهرس
                var indexDoc = await BuildPropertyIndexDocumentAsync(property, cancellationToken);
                
                // التحقق من صحة البيانات
                if (indexDoc == null)
                {
                    _logger.LogWarning("فشل بناء نموذج الفهرس للعقار: {PropertyId}", property.Id);
                    return false;
                }

                // 2. إنشاء معاملة Pipeline لضمان الذرية
                var db = GetDatabase();
                if (db == null)
                {
                    _logger.LogWarning("تعذر الحصول على اتصال Redis للفهرسة");
                    return false;
                }
                var tran = db.CreateTransaction();
                if (tran == null)
                {
                    _logger.LogWarning("تعذر إنشاء معاملة Redis للفهرسة");
                    return false;
                }

                // 3. حفظ البيانات الأساسية في Hash
                var propertyKey = RedisKeySchemas.GetPropertyKey(property.Id);
                _ = tran.HashSetAsync(propertyKey, indexDoc.ToHashEntries());

                // 4. حفظ البيانات المسلسلة بـ MessagePack
                var binaryKey = RedisKeySchemas.GetPropertyBinaryKey(property.Id);
                var serialized = MessagePackSerializer.Serialize(indexDoc);
                _ = tran.StringSetAsync(binaryKey, serialized);

                // 5. إضافة إلى الفهارس المختلفة
                await AddToIndexesAsync(tran, indexDoc);

                // 6. فهرسة الوحدات التابعة
                await IndexPropertyUnitsAsync(tran, property, cancellationToken);

                // 7. تنفيذ المعاملة
                var result = await tran.ExecuteAsync();

                if (result)
                {
                    _logger.LogInformation("✅ تمت فهرسة العقار بنجاح: {PropertyId}", property.Id);
                    
                    // ملاحظة: تم تعطيل تحديث حالة الفهرسة في قاعدة البيانات لتجنب مشاكل التزامن
                    // الفهرسة الحقيقية تحدث في Redis وليس هناك حاجة لتحديث قاعدة البيانات
                    // await MarkPropertyAsIndexedAsync(property.Id, cancellationToken);
                    
                    // نشر حدث الفهرسة
                    await PublishIndexingEventAsync("property:indexed", property.Id);
                }
                else
                {
                    _logger.LogError("❌ فشلت فهرسة العقار: {PropertyId}", property.Id);
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في فهرسة العقار: {PropertyId}", property.Id);
                return false;
            }
            finally
            {
                _indexingLock.Release();
            }
        }

        /// <summary>
        /// تحديث فهرسة عقار موجود
        /// يستخدم عند تعديل بيانات العقار
        /// </summary>
        public async Task<bool> UpdatePropertyIndexAsync(
            Property property,
            CancellationToken cancellationToken = default)
        {
            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                _logger.LogInformation("تحديث فهرسة العقار: {PropertyId}", property.Id);

                // 1. جلب البيانات القديمة للمقارنة
                var db = GetDatabase();
                var propertyKey = RedisKeySchemas.GetPropertyKey(property.Id);
                var oldData = await db.HashGetAllAsync(propertyKey);
                PropertyIndexDocument oldDoc = null;
                
                if (oldData.Length > 0)
                {
                    oldDoc = PropertyIndexDocument.FromHashEntries(oldData);
                }

                // 2. بناء نموذج الفهرس الجديد
                var newDoc = await BuildPropertyIndexDocumentAsync(property, cancellationToken);

                // 3. إنشاء معاملة للتحديث
                var tran = db.CreateTransaction();

                // 4. تحديث البيانات الأساسية
                _ = tran.HashSetAsync(propertyKey, newDoc.ToHashEntries());

                // 5. تحديث البيانات المسلسلة
                var binaryKey = RedisKeySchemas.GetPropertyBinaryKey(property.Id);
                var serialized = MessagePackSerializer.Serialize(newDoc);
                _ = tran.StringSetAsync(binaryKey, serialized);

                // 6. تحديث الفهارس المتأثرة فقط
                if (oldDoc != null)
                {
                    await UpdateChangedIndexesAsync(tran, oldDoc, newDoc);
                }
                else
                {
                    await AddToIndexesAsync(tran, newDoc);
                }

                // 7. تنفيذ المعاملة
                var result = await tran.ExecuteAsync();

                if (result)
                {
                    _logger.LogInformation("✅ تم تحديث فهرسة العقار بنجاح: {PropertyId}", property.Id);
                    await PublishIndexingEventAsync("property:updated", property.Id);
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث فهرسة العقار: {PropertyId}", property.Id);
                throw;
            }
            finally
            {
                _indexingLock.Release();
            }
        }

        /// <summary>
        /// حذف عقار من جميع الفهارس
        /// </summary>
        public async Task<bool> RemovePropertyFromIndexesAsync(
            Guid propertyId,
            CancellationToken cancellationToken = default)
        {
            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                _logger.LogInformation("حذف العقار من الفهارس: {PropertyId}", propertyId);

                // 1. جلب البيانات الحالية للعقار
                var db = GetDatabase();
                var propertyKey = RedisKeySchemas.GetPropertyKey(propertyId);
                var data = await db.HashGetAllAsync(propertyKey);
                
                if (data.Length == 0)
                {
                    _logger.LogWarning("العقار غير موجود في الفهارس: {PropertyId}", propertyId);
                    return true;
                }

                var doc = PropertyIndexDocument.FromHashEntries(data);

                // 2. إنشاء معاملة للحذف
                var tran = db.CreateTransaction();

                // 3. حذف من جميع الفهارس
                await RemoveFromAllIndexesAsync(tran, doc);

                // 4. حذف البيانات الأساسية
                _ = tran.KeyDeleteAsync(propertyKey);
                _ = tran.KeyDeleteAsync(RedisKeySchemas.GetPropertyBinaryKey(propertyId));
                _ = tran.KeyDeleteAsync(RedisKeySchemas.GetPropertyMetaKey(propertyId));

                // 5. حذف وحدات العقار
                var unitsKey = RedisKeySchemas.GetPropertyUnitsKey(propertyId);
                var unitIds = await db.SetMembersAsync(unitsKey);
                
                foreach (var unitId in unitIds)
                {
                    _ = tran.KeyDeleteAsync(RedisKeySchemas.GetUnitKey(Guid.Parse(unitId)));
                    _ = tran.KeyDeleteAsync(RedisKeySchemas.GetUnitAvailabilityKey(Guid.Parse(unitId)));
                    _ = tran.KeyDeleteAsync(RedisKeySchemas.GetUnitPricingKey(Guid.Parse(unitId)));
                    _ = tran.KeyDeleteAsync(RedisKeySchemas.GetUnitPricingZKey(Guid.Parse(unitId)));
                }
                
                _ = tran.KeyDeleteAsync(unitsKey);

                // 6. تنفيذ المعاملة
                var result = await tran.ExecuteAsync();

                if (result)
                {
                    _logger.LogInformation("✅ تم حذف العقار من الفهارس بنجاح: {PropertyId}", propertyId);
                    await PublishIndexingEventAsync("property:removed", propertyId);
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في حذف العقار من الفهارس: {PropertyId}", propertyId);
                throw;
            }
            finally
            {
                _indexingLock.Release();
            }
        }

        #endregion

        #region عمليات فهرسة الوحدات

        /// <summary>
        /// فهرسة وحدة سكنية واحدة
        /// </summary>
        public async Task<bool> IndexUnitAsync(
            Unit unit,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("فهرسة الوحدة: {UnitId} للعقار: {PropertyId}", 
                    unit.Id, unit.PropertyId);

                var unitDoc = BuildUnitIndexDocument(unit);
                var db = GetDatabase();
                var tran = db.CreateTransaction();

                // حفظ بيانات الوحدة
                var unitKey = RedisKeySchemas.GetUnitKey(unit.Id);
                _ = tran.HashSetAsync(unitKey, unitDoc.ToHashEntries());

                // إضافة إلى مجموعة وحدات العقار
                var unitsSetKey = RedisKeySchemas.GetPropertyUnitsKey(unit.PropertyId);
                _ = tran.SetAddAsync(unitsSetKey, unit.Id.ToString());

                // إضافة إلى فهرس نوع الوحدة
                var unitTypeKey = string.Format(RedisKeySchemas.TAG_UNIT_TYPE, unit.UnitTypeId);
                _ = tran.SetAddAsync(unitTypeKey, unit.Id.ToString());

                // فهارس وجود وعدد البالغين/الأطفال للوحدة
                if (unitDoc.MaxAdults > 0)
                {
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_UNIT_HAS_ADULTS, unit.Id.ToString());
                    _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_UNIT_MAX_ADULTS, unit.Id.ToString(), unitDoc.MaxAdults);
                    // تمييز نوع الوحدة بأنه يدعم عدد بالغين
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_UNIT_TYPE_HAS_ADULTS, unit.UnitTypeId.ToString());
                    // تمييز العقار بأنه يحتوي وحدات ببالغين
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_PROPERTY_HAS_ADULTS, unit.PropertyId.ToString());
                }

                if (unitDoc.MaxChildren > 0)
                {
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_UNIT_HAS_CHILDREN, unit.Id.ToString());
                    _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_UNIT_MAX_CHILDREN, unit.Id.ToString(), unitDoc.MaxChildren);
                    // تمييز نوع الوحدة بأنه يدعم عدد أطفال
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_UNIT_TYPE_HAS_CHILDREN, unit.UnitTypeId.ToString());
                    // تمييز العقار بأنه يحتوي وحدات بأطفال
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_PROPERTY_HAS_CHILDREN, unit.PropertyId.ToString());
                }

                // إضافة فترة تسعير افتراضية تغطي كل الزمن بناءً على السعر الأساسي
                var priceZKey = RedisKeySchemas.GetUnitPricingZKey(unit.Id);
                var startTicks = 0L; // من البداية
                var endTicks = DateTime.MaxValue.Ticks; // إلى أقصى تاريخ
                var priceElement = $"{startTicks}:{endTicks}:{unitDoc.BasePrice}:{unitDoc.Currency}";
                _ = tran.SortedSetAddAsync(priceZKey, priceElement, startTicks);

                var result = await tran.ExecuteAsync();

                if (result)
                {
                    _logger.LogInformation("✅ تمت فهرسة الوحدة بنجاح: {UnitId}", unit.Id);
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في فهرسة الوحدة: {UnitId}", unit.Id);
                throw;
            }
        }

        #endregion

        #region بناء نماذج الفهرسة

        /// <summary>
        /// بناء نموذج فهرس العقار من الكيان
        /// </summary>
        private async Task<PropertyIndexDocument> BuildPropertyIndexDocumentAsync(
            Property property,
            CancellationToken cancellationToken)
        {
            // جلب البيانات الإضافية - سيتم الحصول على الوحدات من property.Units إذا كانت محملة
            var unitsList = property.Units?.ToList() ?? new List<Unit>();
            if (unitsList.Count == 0)
            {
                try
                {
                    var withUnits = await _propertyRepository.GetPropertyWithUnitsAsync(property.Id, cancellationToken);
                    if (withUnits?.Units != null)
                    {
                        unitsList = withUnits.Units.ToList();
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogDebug(ex, "تعذر جلب الوحدات من قاعدة البيانات للعقار {PropertyId}", property.Id);
                }
            }

            // حساب أقل سعر ومرجعية العملة من فهارس تسعير الوحدات (ZSET)
            var (computedMinPrice, computedCurrency) = await ComputeMinPriceFromUnitPricingAsync(unitsList, cancellationToken);

            var doc = new PropertyIndexDocument
            {
                // الخصائص الأساسية
                Id = property.Id,
                Name = property.Name,
                NameNormalized = property.Name?.ToLowerInvariant(),
                Description = property.Description,

                // بيانات الموقع
                City = property.City,
                FullAddress = property.Address,
                Latitude = (double)property.Latitude,
                Longitude = (double)property.Longitude,
                District = "", // غير متوفر في Property

                // بيانات التصنيف
                PropertyTypeId = property.TypeId,
                PropertyTypeName = property.PropertyType?.Name,
                StarRating = property.StarRating,

                // بيانات التسعير (محسوبة من فهرس تسعير الوحدات)
                MinPrice = computedMinPrice,
                MaxPrice = unitsList.Any() ? unitsList.Max(u => u.BasePrice.Amount) : 0,
                AveragePrice = unitsList.Any() ? unitsList.Average(u => u.BasePrice.Amount) : 0,
                BaseCurrency = computedCurrency,

                // بيانات التقييم والشعبية
                AverageRating = property.AverageRating,
                ReviewsCount = 0, // غير متوفر في Property - يمكن حسابه من Reviews
                TotalBookings = property.BookingCount,
                ViewsCount = property.ViewCount,

                // بيانات السعة والوحدات
                MaxCapacity = unitsList.Any() ? unitsList.Max(u => u.MaxCapacity) : 0,
                TotalUnits = unitsList.Count,
                AvailableUnitsCount = unitsList.Count(u => u.IsActive),
                UnitIds = unitsList.Select(u => u.Id).ToList(),
                
                // أنواع الوحدات المتوفرة
                UnitTypeIds = unitsList.Select(u => u.UnitTypeId).Distinct().ToList(),
                UnitTypeNames = unitsList.Select(u => u.UnitType?.Name).Where(n => !string.IsNullOrWhiteSpace(n)).Distinct().ToList(),

                // الحد الأقصى للبالغين/الأطفال عبر وحدات العقار
                MaxAdults = unitsList.Any() ? unitsList.Max(u => (u.AdultsCapacity ?? u.MaxCapacity)) : 0,
                MaxChildren = unitsList.Any() ? unitsList.Max(u => (u.ChildrenCapacity ?? 0)) : 0,

                // المرافق والخدمات
                AmenityIds = property.Amenities?.Select(a => a.Id).ToList() ?? new List<Guid>(),
                AmenityNames = property.Amenities?.Select(a => a.PropertyTypeAmenity?.Amenity?.Name ?? "").ToList() ?? new List<string>(),
                ServiceIds = new List<Guid>(), // غير متوفر في Property
                ServiceNames = new List<string>(), // غير متوفر في Property

                // الصور
                ImageUrls = property.Images?.Select(i => i.Url).ToList() ?? new List<string>(),
                MainImageUrl = property.Images?.FirstOrDefault(i => i.IsMain)?.Url,
                ImagesCount = property.Images?.Count ?? 0,

                // بيانات الحالة
                IsActive = property.IsActive,
                IsApproved = property.IsApproved,
                IsFeatured = property.IsFeatured,
                IsIndexed = true,

                // بيانات المالك
                OwnerId = property.OwnerId,
                OwnerName = property.Owner?.Name,
                OwnerRating = 0, // غير متوفر في User

                // الطوابع الزمنية
                CreatedAt = property.CreatedAt,
                UpdatedAt = property.UpdatedAt,
                LastIndexedAt = DateTime.UtcNow,
                LastModifiedTicks = property.UpdatedAt.Ticks,
                
                // الحقول الديناميكية
                DynamicFields = await GetDynamicFieldsForPropertyAsync(property.Id, cancellationToken),
                Tags = new List<string>() // يمكن إضافة tags لاحقاً
            };

            // حساب نقاط الشعبية
            doc.CalculatePopularityScore();

            return doc;
        }

        /// <summary>
        /// حساب أقل سعر عبر جميع وحدات العقار من ZSET التسعير
        /// </summary>
        private async Task<(decimal minPrice, string currency)> ComputeMinPriceFromUnitPricingAsync(
            List<Unit> units,
            CancellationToken cancellationToken)
        {
            try
            {
                if (units == null || units.Count == 0)
                    return (0m, "YER");

                var db = GetDatabase();
                decimal globalMin = decimal.MaxValue;
                string currency = "YER";

                foreach (var unit in units)
                {
                    var zkey = RedisKeySchemas.GetUnitPricingZKey(unit.Id);
                    var ranges = await db.SortedSetRangeByRankAsync(zkey, 0, -1);
                    if (ranges != null && ranges.Length > 0)
                    {
                        foreach (var rv in ranges)
                        {
                            var parts = rv.ToString().Split(':');
                            if (parts.Length >= 4)
                            {
                                if (decimal.TryParse(parts[2], out var price))
                                {
                                    if (price < globalMin)
                                    {
                                        globalMin = price;
                                        currency = parts[3];
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        // fallback للسعر الأساسي للوحدة
                        var price = unit.BasePrice.Amount;
                        if (price < globalMin)
                        {
                            globalMin = price;
                            currency = unit.BasePrice.Currency ?? "YER";
                        }
                    }
                }

                if (globalMin == decimal.MaxValue)
                {
                    return (0m, "YER");
                }
                return (globalMin, currency);
            }
            catch
            {
                // fallback عند أي خطأ
                var fallbackMin = units.Any() ? units.Min(u => u.BasePrice.Amount) : 0m;
                var fallbackCurr = units.FirstOrDefault()?.BasePrice.Currency ?? "YER";
                return (fallbackMin, fallbackCurr);
            }
        }

        /// <summary>
        /// بناء نموذج فهرس الوحدة من الكيان
        /// </summary>
        private UnitIndexDocument BuildUnitIndexDocument(Unit unit)
        {
            return new UnitIndexDocument
            {
                Id = unit.Id,
                PropertyId = unit.PropertyId,
                Name = unit.Name,
                UnitTypeId = unit.UnitTypeId,
                UnitTypeName = unit.UnitType?.Name,
                MaxCapacity = unit.MaxCapacity,
                MaxAdults = unit.AdultsCapacity ?? unit.MaxCapacity, // استخدم السعة الكلية إذا لم تحدد سعة البالغين
                MaxChildren = unit.ChildrenCapacity ?? 0,
                BasePrice = unit.BasePrice.Amount,
                Currency = unit.BasePrice.Currency,
                BedroomsCount = 0, // غير متوفر في Unit - يمكن الحصول عليه من UnitType أو الحقول المخصصة
                BathroomsCount = 0, // غير متوفر في Unit - يمكن الحصول عليه من UnitType أو الحقول المخصصة
                AreaSquareMeters = 0, // غير متوفر في Unit - يمكن الحصول عليه من UnitType أو الحقول المخصصة
                FloorNumber = 0, // غير متوفر في Unit - يمكن الحصول عليه من UnitType أو الحقول المخصصة
                IsActive = unit.IsActive,
                IsAvailable = unit.IsAvailable,
                CreatedAt = unit.CreatedAt,
                UpdatedAt = unit.UpdatedAt
            };
        }

        /// <summary>
        /// جلب الحقول الديناميكية للعقار من Redis
        /// </summary>
        private async Task<Dictionary<string, string>> GetDynamicFieldsForPropertyAsync(
            Guid propertyId,
            CancellationToken cancellationToken)
        {
            try
            {
                var dynamicFieldsKey = $"{RedisKeySchemas.GetPropertyKey(propertyId)}:dynamic_fields";
                var db = GetDatabase();
                var fields = await db.HashGetAllAsync(dynamicFieldsKey);
                
                if (fields.Length == 0)
                {
                    return new Dictionary<string, string>();
                }
                
                return fields.ToDictionary(
                    x => x.Name.ToString(),
                    x => x.Value.ToString()
                );
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "خطأ في جلب الحقول الديناميكية للعقار {PropertyId}", propertyId);
                return new Dictionary<string, string>();
            }
        }
        
        #endregion

        #region عمليات الفهارس المساعدة

        /// <summary>
        /// إضافة العقار إلى جميع الفهارس
        /// </summary>
        private async Task AddToIndexesAsync(ITransaction tran, PropertyIndexDocument doc)
        {
            var propId = doc.Id.ToString();

            // مجموعة جميع العقارات النشطة والمعتمدة فقط
            if (doc.IsActive && doc.IsApproved)
            {
                _ = tran.SetAddAsync(RedisKeySchemas.PROPERTIES_ALL_SET, propId);
            }

            // الفهارس الجغرافية
            _ = tran.GeoAddAsync(
                RedisKeySchemas.GEO_PROPERTIES,
                new GeoEntry(doc.Longitude, doc.Latitude, propId));

            var cityGeoKey = string.Format(RedisKeySchemas.GEO_CITY, doc.City?.ToLowerInvariant());
            _ = tran.GeoAddAsync(cityGeoKey, new GeoEntry(doc.Longitude, doc.Latitude, propId));

            // فهارس الترتيب
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_PRICE, propId, (double)doc.MinPrice);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_RATING, propId, (double)doc.AverageRating);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_CREATED, propId, doc.CreatedAt.Ticks);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_BOOKINGS, propId, doc.TotalBookings);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_POPULARITY, propId, doc.PopularityScore);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_MAX_ADULTS, propId, doc.MaxAdults);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_MAX_CHILDREN, propId, doc.MaxChildren);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_MAX_CAPACITY, propId, doc.MaxCapacity);

            // فهارس التصنيف
            _ = tran.SetAddAsync(RedisKeySchemas.GetCityKey(doc.City), propId);
            
            // إضافة لفهرس نوع العقار بالمعرف GUID
            _ = tran.SetAddAsync(RedisKeySchemas.GetTypeKey(doc.PropertyTypeId), propId);
            
            // إضافة أيضاً لفهرس بالاسم النصي لنوع العقار لدعم البحث بالاسم
            if (!string.IsNullOrWhiteSpace(doc.PropertyTypeName))
            {
                var typeNameKey = string.Format(RedisKeySchemas.TAG_TYPE, doc.PropertyTypeName.ToLowerInvariant());
                _ = tran.SetAddAsync(typeNameKey, propId);
            }

            foreach (var amenityId in doc.AmenityIds)
            {
                _ = tran.SetAddAsync(RedisKeySchemas.GetAmenityKey(amenityId), propId);
            }

            foreach (var serviceId in doc.ServiceIds)
            {
                _ = tran.SetAddAsync(string.Format(RedisKeySchemas.TAG_SERVICE, serviceId), propId);
            }

            if (doc.IsFeatured)
            {
                _ = tran.SetAddAsync(RedisKeySchemas.TAG_FEATURED, propId);
            }

            // فهارس الحقول الديناميكية: dynamic_value:{field}:{value} → Set
            if (doc.DynamicFields != null && doc.DynamicFields.Count > 0)
            {
                foreach (var kv in doc.DynamicFields)
                {
                    if (!string.IsNullOrWhiteSpace(kv.Key) && !string.IsNullOrWhiteSpace(kv.Value))
                    {
                        var dynKey = RedisKeySchemas.GetDynamicFieldValueKey(kv.Key, kv.Value);
                        _ = tran.SetAddAsync(dynKey, propId);
                    }
                }
            }
        }

        /// <summary>
        /// تحديث الفهارس المتغيرة فقط
        /// </summary>
        private async Task UpdateChangedIndexesAsync(
            ITransaction tran,
            PropertyIndexDocument oldDoc,
            PropertyIndexDocument newDoc)
        {
            var propId = newDoc.Id.ToString();

            // تحديث المدينة
            if (oldDoc.City != newDoc.City)
            {
                _ = tran.SetRemoveAsync(RedisKeySchemas.GetCityKey(oldDoc.City), propId);
                _ = tran.SetAddAsync(RedisKeySchemas.GetCityKey(newDoc.City), propId);
            }

            // تحديث نوع العقار
            if (oldDoc.PropertyTypeId != newDoc.PropertyTypeId)
            {
                // إزالة من الفهرس القديم بالمعرف
                _ = tran.SetRemoveAsync(RedisKeySchemas.GetTypeKey(oldDoc.PropertyTypeId), propId);
                // إضافة للفهرس الجديد بالمعرف
                _ = tran.SetAddAsync(RedisKeySchemas.GetTypeKey(newDoc.PropertyTypeId), propId);
                
                // إزالة من فهرس الاسم القديم
                if (!string.IsNullOrWhiteSpace(oldDoc.PropertyTypeName))
                {
                    var oldTypeNameKey = string.Format(RedisKeySchemas.TAG_TYPE, oldDoc.PropertyTypeName.ToLowerInvariant());
                    _ = tran.SetRemoveAsync(oldTypeNameKey, propId);
                }
                
                // إضافة لفهرس الاسم الجديد
                if (!string.IsNullOrWhiteSpace(newDoc.PropertyTypeName))
                {
                    var newTypeNameKey = string.Format(RedisKeySchemas.TAG_TYPE, newDoc.PropertyTypeName.ToLowerInvariant());
                    _ = tran.SetAddAsync(newTypeNameKey, propId);
                }
            }
            // تحديث اسم النوع فقط (في حالة تغيير الاسم بدون تغيير المعرف)
            else if (oldDoc.PropertyTypeName != newDoc.PropertyTypeName)
            {
                if (!string.IsNullOrWhiteSpace(oldDoc.PropertyTypeName))
                {
                    var oldTypeNameKey = string.Format(RedisKeySchemas.TAG_TYPE, oldDoc.PropertyTypeName.ToLowerInvariant());
                    _ = tran.SetRemoveAsync(oldTypeNameKey, propId);
                }
                
                if (!string.IsNullOrWhiteSpace(newDoc.PropertyTypeName))
                {
                    var newTypeNameKey = string.Format(RedisKeySchemas.TAG_TYPE, newDoc.PropertyTypeName.ToLowerInvariant());
                    _ = tran.SetAddAsync(newTypeNameKey, propId);
                }
            }

            // تحديث المرافق
            var removedAmenities = oldDoc.AmenityIds.Except(newDoc.AmenityIds);
            var addedAmenities = newDoc.AmenityIds.Except(oldDoc.AmenityIds);

            foreach (var amenityId in removedAmenities)
            {
                _ = tran.SetRemoveAsync(RedisKeySchemas.GetAmenityKey(amenityId), propId);
            }

            foreach (var amenityId in addedAmenities)
            {
                _ = tran.SetAddAsync(RedisKeySchemas.GetAmenityKey(amenityId), propId);
            }

            // تحديث فهارس الترتيب
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_PRICE, propId, 
                (double)newDoc.MinPrice, SortedSetWhen.Always);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_RATING, propId, 
                (double)newDoc.AverageRating, SortedSetWhen.Always);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_BOOKINGS, propId, 
                newDoc.TotalBookings, SortedSetWhen.Always);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_POPULARITY, propId, 
                newDoc.PopularityScore, SortedSetWhen.Always);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_MAX_ADULTS, propId,
                newDoc.MaxAdults, SortedSetWhen.Always);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_MAX_CHILDREN, propId,
                newDoc.MaxChildren, SortedSetWhen.Always);
            _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_MAX_CAPACITY, propId,
                newDoc.MaxCapacity, SortedSetWhen.Always);

            // تحديث الموقع
            _ = tran.GeoAddAsync(
                RedisKeySchemas.GEO_PROPERTIES,
                new GeoEntry(newDoc.Longitude, newDoc.Latitude, propId));

            // تحديث العقار المميز
            if (oldDoc.IsFeatured != newDoc.IsFeatured)
            {
                if (newDoc.IsFeatured)
                {
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_FEATURED, propId);
                }
                else
                {
                    _ = tran.SetRemoveAsync(RedisKeySchemas.TAG_FEATURED, propId);
                }
            }

            // تحديث حالة الإدراج في مجموعة جميع العقارات النشطة
            var oldActiveApproved = oldDoc.IsActive && oldDoc.IsApproved;
            var newActiveApproved = newDoc.IsActive && newDoc.IsApproved;
            if (oldActiveApproved != newActiveApproved)
            {
                if (newActiveApproved)
                {
                    _ = tran.SetAddAsync(RedisKeySchemas.PROPERTIES_ALL_SET, propId);
                }
                else
                {
                    _ = tran.SetRemoveAsync(RedisKeySchemas.PROPERTIES_ALL_SET, propId);
                }
            }

            // تحديث فهارس الحقول الديناميكية
            var oldDyn = oldDoc.DynamicFields ?? new Dictionary<string, string>();
            var newDyn = newDoc.DynamicFields ?? new Dictionary<string, string>();

            // الحقول المحذوفة أو التي تغيرت قيمها
            foreach (var kv in oldDyn)
            {
                var key = kv.Key;
                var oldVal = kv.Value;
                var hasNew = newDyn.TryGetValue(key, out var newVal);
                if (!hasNew || !string.Equals(oldVal, newVal, StringComparison.OrdinalIgnoreCase))
                {
                    var oldDynKey = RedisKeySchemas.GetDynamicFieldValueKey(key, oldVal);
                    _ = tran.SetRemoveAsync(oldDynKey, propId);
                }
            }

            // الحقول الجديدة أو التي تغيرت قيمها
            foreach (var kv in newDyn)
            {
                if (!string.IsNullOrWhiteSpace(kv.Value))
                {
                    var needAdd = !oldDyn.TryGetValue(kv.Key, out var oldVal) ||
                                  !string.Equals(oldVal, kv.Value, StringComparison.OrdinalIgnoreCase);
                    if (needAdd)
                    {
                        var newDynKey = RedisKeySchemas.GetDynamicFieldValueKey(kv.Key, kv.Value);
                        _ = tran.SetAddAsync(newDynKey, propId);
                    }
                }
            }
        }

        /// <summary>
        /// حذف العقار من جميع الفهارس
        /// </summary>
        private async Task RemoveFromAllIndexesAsync(ITransaction tran, PropertyIndexDocument doc)
        {
            var propId = doc.Id.ToString();

            // حذف من المجموعات
            _ = tran.SetRemoveAsync(RedisKeySchemas.PROPERTIES_ALL_SET, propId);
            _ = tran.SetRemoveAsync(RedisKeySchemas.GetCityKey(doc.City), propId);
            _ = tran.SetRemoveAsync(RedisKeySchemas.GetTypeKey(doc.PropertyTypeId), propId);
            _ = tran.SetRemoveAsync(RedisKeySchemas.TAG_FEATURED, propId);
            
            // حذف من RediSearch index  
            var searchKey = RedisKeySchemas.SEARCH_KEY_PREFIX + propId;
            _ = tran.KeyDeleteAsync(searchKey);

            // حذف من الفهارس الجغرافية
            _ = tran.GeoRemoveAsync(RedisKeySchemas.GEO_PROPERTIES, propId);
            var cityGeoKey = string.Format(RedisKeySchemas.GEO_CITY, doc.City?.ToLowerInvariant());
            _ = tran.GeoRemoveAsync(cityGeoKey, propId);

            // حذف من فهارس الترتيب
            _ = tran.SortedSetRemoveAsync(RedisKeySchemas.INDEX_PRICE, propId);
            _ = tran.SortedSetRemoveAsync(RedisKeySchemas.INDEX_RATING, propId);
            _ = tran.SortedSetRemoveAsync(RedisKeySchemas.INDEX_CREATED, propId);
            _ = tran.SortedSetRemoveAsync(RedisKeySchemas.INDEX_BOOKINGS, propId);
            _ = tran.SortedSetRemoveAsync(RedisKeySchemas.INDEX_POPULARITY, propId);
            _ = tran.SortedSetRemoveAsync(RedisKeySchemas.INDEX_MAX_ADULTS, propId);
            _ = tran.SortedSetRemoveAsync(RedisKeySchemas.INDEX_MAX_CHILDREN, propId);
            _ = tran.SortedSetRemoveAsync(RedisKeySchemas.INDEX_MAX_CAPACITY, propId);

            // حذف من فهارس المرافق والخدمات
            foreach (var amenityId in doc.AmenityIds)
            {
                _ = tran.SetRemoveAsync(RedisKeySchemas.GetAmenityKey(amenityId), propId);
            }

            foreach (var serviceId in doc.ServiceIds)
            {
                _ = tran.SetRemoveAsync(string.Format(RedisKeySchemas.TAG_SERVICE, serviceId), propId);
            }

            // حذف من فهارس الحقول الديناميكية
            if (doc.DynamicFields != null && doc.DynamicFields.Count > 0)
            {
                foreach (var kv in doc.DynamicFields)
                {
                    if (!string.IsNullOrWhiteSpace(kv.Value))
                    {
                        var dynKey = RedisKeySchemas.GetDynamicFieldValueKey(kv.Key, kv.Value);
                        _ = tran.SetRemoveAsync(dynKey, propId);
                    }
                }
            }

            // إزالة من العلامات الخاصة بوجود بالغين/أطفال على مستوى العقار
            _ = tran.SetRemoveAsync(RedisKeySchemas.TAG_PROPERTY_HAS_ADULTS, propId);
            _ = tran.SetRemoveAsync(RedisKeySchemas.TAG_PROPERTY_HAS_CHILDREN, propId);
        }

        #endregion

        #region دوال مساعدة خاصة

        /// <summary>
        /// فهرسة وحدات العقار
        /// </summary>
        private async Task IndexPropertyUnitsAsync(
            ITransaction tran,
            Property property,
            CancellationToken cancellationToken)
        {
            // الحصول على الوحدات من property.Units إذا كانت محملة
            var units = property.Units ?? new List<Unit>();
            if (units.Count == 0)
            {
                try
                {
                    var withUnits = await _propertyRepository.GetPropertyWithUnitsAsync(property.Id, cancellationToken);
                    if (withUnits?.Units != null)
                    {
                        units = withUnits.Units.ToList();
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogDebug(ex, "تعذر جلب وحدات العقار {PropertyId} أثناء فهرسة الوحدات", property.Id);
                }
            }
            
            foreach (var unit in units)
            {
                var unitDoc = BuildUnitIndexDocument(unit);
                var unitKey = RedisKeySchemas.GetUnitKey(unit.Id);
                _ = tran.HashSetAsync(unitKey, unitDoc.ToHashEntries());
                
                var unitsSetKey = RedisKeySchemas.GetPropertyUnitsKey(property.Id);
                _ = tran.SetAddAsync(unitsSetKey, unit.Id.ToString());

                // إضافة إلى فهرس نوع الوحدة
                var unitTypeKey = string.Format(RedisKeySchemas.TAG_UNIT_TYPE, unit.UnitTypeId);
                _ = tran.SetAddAsync(unitTypeKey, unit.Id.ToString());

                // فهارس وجود وعدد البالغين/الأطفال للوحدة
                if (unitDoc.MaxAdults > 0)
                {
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_UNIT_HAS_ADULTS, unit.Id.ToString());
                    _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_UNIT_MAX_ADULTS, unit.Id.ToString(), unitDoc.MaxAdults);
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_UNIT_TYPE_HAS_ADULTS, unit.UnitTypeId.ToString());
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_PROPERTY_HAS_ADULTS, property.Id.ToString());
                }

                if (unitDoc.MaxChildren > 0)
                {
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_UNIT_HAS_CHILDREN, unit.Id.ToString());
                    _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_UNIT_MAX_CHILDREN, unit.Id.ToString(), unitDoc.MaxChildren);
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_UNIT_TYPE_HAS_CHILDREN, unit.UnitTypeId.ToString());
                    _ = tran.SetAddAsync(RedisKeySchemas.TAG_PROPERTY_HAS_CHILDREN, property.Id.ToString());
                }

                // إضافة فترة تسعير افتراضية تغطي كل الزمن بناءً على السعر الأساسي
                var priceZKey2 = RedisKeySchemas.GetUnitPricingZKey(unit.Id);
                var startTicks2 = 0L;
                var endTicks2 = DateTime.MaxValue.Ticks;
                var priceElement2 = $"{startTicks2}:{endTicks2}:{unitDoc.BasePrice}:{unitDoc.Currency}";
                _ = tran.SortedSetAddAsync(priceZKey2, priceElement2, startTicks2);
            }
            
            await Task.CompletedTask; // للحفاظ على التوقيع async
        }

        /// <summary>
        /// تحديث حالة الفهرسة في قاعدة البيانات
        /// </summary>
        private async Task MarkPropertyAsIndexedAsync(
            Guid propertyId,
            CancellationToken cancellationToken)
        {
            try
            {
                var property = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
                if (property != null && !property.IsIndexed)
                {
                    property.IsIndexed = true;
                    await _propertyRepository.UpdatePropertyAsync(property, cancellationToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل تحديث حالة الفهرسة للعقار: {PropertyId}", propertyId);
            }
        }

        /// <summary>
        /// نشر أحداث الفهرسة
        /// </summary>
        private async Task PublishIndexingEventAsync(string eventType, Guid entityId)
        {
            try
            {
                var subscriber = _redisManager.GetSubscriber();
                await subscriber.PublishAsync($"indexing:{eventType}", entityId.ToString());
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل نشر حدث الفهرسة: {EventType} - {EntityId}", eventType, entityId);
            }
        }

        /// <summary>
        /// تحديث السعة القصوى للعقار
        /// </summary>
        private async Task UpdatePropertyCapacityAsync(
            ITransaction tran,
            Guid propertyId,
            int unitCapacity)
        {
            var db = GetDatabase();
            var propertyKey = RedisKeySchemas.GetPropertyKey(propertyId);
            var currentCapacity = await db.HashGetAsync(propertyKey, "max_capacity");
            
            if (currentCapacity.IsNullOrEmpty || unitCapacity > (int)currentCapacity)
            {
                await db.HashSetAsync(propertyKey, "max_capacity", unitCapacity);
            }
        }

        /// <summary>
        /// تحديث أسعار العقار
        /// </summary>
        private async Task UpdatePropertyPricesAsync(
            ITransaction tran,
            Guid propertyId,
            decimal unitPrice)
        {
            var db = GetDatabase();
            var propertyKey = RedisKeySchemas.GetPropertyKey(propertyId);
            var currentMinPrice = await db.HashGetAsync(propertyKey, "min_price");
            var currentMaxPrice = await db.HashGetAsync(propertyKey, "max_price");
            
            if (currentMinPrice.IsNullOrEmpty || unitPrice < (decimal)currentMinPrice)
            {
                await db.HashSetAsync(propertyKey, new HashEntry[] 
                {
                    new HashEntry("min_price", (double)unitPrice)
                });
                await db.SortedSetAddAsync(RedisKeySchemas.INDEX_PRICE, 
                    propertyId.ToString(), (double)unitPrice, SortedSetWhen.Always);
            }
            
            if (currentMaxPrice.IsNullOrEmpty || unitPrice > (decimal)currentMaxPrice)
            {
                await db.HashSetAsync(propertyKey, new HashEntry[] 
                {
                    new HashEntry("max_price", (double)unitPrice)
                });
            }
        }

        #endregion

        #region عمليات القراءة

        /// <summary>
        /// قراءة فهرس العقار من Redis
        /// </summary>
        public async Task<PropertyIndexDocument?> GetPropertyIndexAsync(
            Guid propertyId,
            CancellationToken cancellationToken = default)
        {
            try
            {
                var db = GetDatabase();
                var propertyKey = RedisKeySchemas.GetPropertyKey(propertyId);
                var hashEntries = await db.HashGetAllAsync(propertyKey);
                
                if (!hashEntries.Any())
                {
                    _logger.LogInformation("لم يتم العثور على فهرس للعقار: {PropertyId}", propertyId);
                    return null;
                }

                // تحويل من HashEntries إلى PropertyIndexDocument
                var doc = PropertyIndexDocument.FromHashEntries(hashEntries);
                return doc;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في قراءة فهرس العقار: {PropertyId}", propertyId);
                return null;
            }
        }

        #endregion
    }
}
