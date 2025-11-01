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
        private readonly IDatabase _db;
        private readonly SemaphoreSlim _indexingLock;
        
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
            _db = _redisManager.GetDatabase();
            _indexingLock = new SemaphoreSlim(5, 5); // حد أقصى 5 عمليات فهرسة متزامنة
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
            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                _logger.LogInformation("بدء فهرسة العقار: {PropertyId} - {PropertyName}", 
                    property.Id, property.Name);

                // 1. بناء نموذج الفهرس
                var indexDoc = await BuildPropertyIndexDocumentAsync(property, cancellationToken);

                // 2. إنشاء معاملة Pipeline لضمان الذرية
                var tran = _db.CreateTransaction();

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
                    
                    // تحديث حالة الفهرسة في قاعدة البيانات
                    await MarkPropertyAsIndexedAsync(property.Id, cancellationToken);
                    
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
                throw;
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
                var propertyKey = RedisKeySchemas.GetPropertyKey(property.Id);
                var oldData = await _db.HashGetAllAsync(propertyKey);
                PropertyIndexDocument oldDoc = null;
                
                if (oldData.Length > 0)
                {
                    oldDoc = PropertyIndexDocument.FromHashEntries(oldData);
                }

                // 2. بناء نموذج الفهرس الجديد
                var newDoc = await BuildPropertyIndexDocumentAsync(property, cancellationToken);

                // 3. إنشاء معاملة للتحديث
                var tran = _db.CreateTransaction();

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
                var propertyKey = RedisKeySchemas.GetPropertyKey(propertyId);
                var data = await _db.HashGetAllAsync(propertyKey);
                
                if (data.Length == 0)
                {
                    _logger.LogWarning("العقار غير موجود في الفهارس: {PropertyId}", propertyId);
                    return true;
                }

                var doc = PropertyIndexDocument.FromHashEntries(data);

                // 2. إنشاء معاملة للحذف
                var tran = _db.CreateTransaction();

                // 3. حذف من جميع الفهارس
                await RemoveFromAllIndexesAsync(tran, doc);

                // 4. حذف البيانات الأساسية
                _ = tran.KeyDeleteAsync(propertyKey);
                _ = tran.KeyDeleteAsync(RedisKeySchemas.GetPropertyBinaryKey(propertyId));
                _ = tran.KeyDeleteAsync(RedisKeySchemas.GetPropertyMetaKey(propertyId));

                // 5. حذف وحدات العقار
                var unitsKey = RedisKeySchemas.GetPropertyUnitsKey(propertyId);
                var unitIds = await _db.SetMembersAsync(unitsKey);
                
                foreach (var unitId in unitIds)
                {
                    _ = tran.KeyDeleteAsync(RedisKeySchemas.GetUnitKey(Guid.Parse(unitId)));
                    _ = tran.KeyDeleteAsync(RedisKeySchemas.GetUnitAvailabilityKey(Guid.Parse(unitId)));
                    _ = tran.KeyDeleteAsync(RedisKeySchemas.GetUnitPricingKey(Guid.Parse(unitId)));
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
                var tran = _db.CreateTransaction();

                // حفظ بيانات الوحدة
                var unitKey = RedisKeySchemas.GetUnitKey(unit.Id);
                _ = tran.HashSetAsync(unitKey, unitDoc.ToHashEntries());

                // إضافة إلى مجموعة وحدات العقار
                var unitsSetKey = RedisKeySchemas.GetPropertyUnitsKey(unit.PropertyId);
                _ = tran.SetAddAsync(unitsSetKey, unit.Id.ToString());

                // إضافة إلى فهرس نوع الوحدة
                var unitTypeKey = string.Format(RedisKeySchemas.TAG_UNIT_TYPE, unit.UnitTypeId);
                _ = tran.SetAddAsync(unitTypeKey, unit.Id.ToString());

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

                // بيانات التسعير (محسوبة من الوحدات)
                MinPrice = unitsList.Any() ? unitsList.Min(u => u.BasePrice.Amount) : 0,
                MaxPrice = unitsList.Any() ? unitsList.Max(u => u.BasePrice.Amount) : 0,
                AveragePrice = unitsList.Any() ? unitsList.Average(u => u.BasePrice.Amount) : 0,
                BaseCurrency = unitsList.FirstOrDefault()?.BasePrice.Currency ?? "YER",

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
                LastModifiedTicks = property.UpdatedAt.Ticks
            };

            // حساب نقاط الشعبية
            doc.CalculatePopularityScore();

            return doc;
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

        #endregion

        #region عمليات الفهارس المساعدة

        /// <summary>
        /// إضافة العقار إلى جميع الفهارس
        /// </summary>
        private async Task AddToIndexesAsync(ITransaction tran, PropertyIndexDocument doc)
        {
            var propId = doc.Id.ToString();

            // مجموعة جميع العقارات
            _ = tran.SetAddAsync(RedisKeySchemas.PROPERTIES_ALL_SET, propId);

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

            // فهارس التصنيف
            _ = tran.SetAddAsync(RedisKeySchemas.GetCityKey(doc.City), propId);
            _ = tran.SetAddAsync(RedisKeySchemas.GetTypeKey(doc.PropertyTypeId), propId);

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
                _ = tran.SetRemoveAsync(RedisKeySchemas.GetTypeKey(oldDoc.PropertyTypeId), propId);
                _ = tran.SetAddAsync(RedisKeySchemas.GetTypeKey(newDoc.PropertyTypeId), propId);
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

            // حذف من فهارس المرافق والخدمات
            foreach (var amenityId in doc.AmenityIds)
            {
                _ = tran.SetRemoveAsync(RedisKeySchemas.GetAmenityKey(amenityId), propId);
            }

            foreach (var serviceId in doc.ServiceIds)
            {
                _ = tran.SetRemoveAsync(string.Format(RedisKeySchemas.TAG_SERVICE, serviceId), propId);
            }
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
            
            foreach (var unit in units)
            {
                var unitDoc = BuildUnitIndexDocument(unit);
                var unitKey = RedisKeySchemas.GetUnitKey(unit.Id);
                _ = tran.HashSetAsync(unitKey, unitDoc.ToHashEntries());
                
                var unitsSetKey = RedisKeySchemas.GetPropertyUnitsKey(property.Id);
                _ = tran.SetAddAsync(unitsSetKey, unit.Id.ToString());
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
            var propertyKey = RedisKeySchemas.GetPropertyKey(propertyId);
            var currentCapacity = await _db.HashGetAsync(propertyKey, "max_capacity");
            
            if (currentCapacity.IsNullOrEmpty || unitCapacity > (int)currentCapacity)
            {
                _ = tran.HashSetAsync(propertyKey, "max_capacity", unitCapacity);
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
            var propertyKey = RedisKeySchemas.GetPropertyKey(propertyId);
            var currentMinPrice = await _db.HashGetAsync(propertyKey, "min_price");
            var currentMaxPrice = await _db.HashGetAsync(propertyKey, "max_price");
            
            if (currentMinPrice.IsNullOrEmpty || unitPrice < (decimal)currentMinPrice)
            {
                _ = tran.HashSetAsync(propertyKey, "min_price", unitPrice.ToString());
                _ = tran.SortedSetAddAsync(RedisKeySchemas.INDEX_PRICE, 
                    propertyId.ToString(), (double)unitPrice, SortedSetWhen.Always);
            }
            
            if (currentMaxPrice.IsNullOrEmpty || unitPrice > (decimal)currentMaxPrice)
            {
                _ = tran.HashSetAsync(propertyKey, "max_price", unitPrice.ToString());
            }
        }

        #endregion
    }
}
