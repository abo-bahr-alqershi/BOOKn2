using System;

namespace YemenBooking.Infrastructure.Redis.Core
{
    /// <summary>
    /// مخططات مفاتيح Redis المحسنة للنظام الجديد
    /// يحتوي على جميع أنماط المفاتيح المستخدمة في النظام
    /// </summary>
    public static class RedisKeySchemas
    {
        #region المفاتيح الأساسية للعقارات
        
        /// <summary>
        /// مفتاح Hash للعقار: property:{id} → Hash
        /// </summary>
        public const string PROPERTY_HASH = "property:{0}";
        
        /// <summary>
        /// مفتاح البيانات المسلسلة بـ MessagePack: property:{id}:bin → MessagePack
        /// </summary>
        public const string PROPERTY_BINARY = "property:{0}:bin";
        
        /// <summary>
        /// مفتاح البيانات الوصفية: property:{id}:meta → Metadata
        /// </summary>
        public const string PROPERTY_META = "property:{0}:meta";
        
        /// <summary>
        /// مجموعة جميع العقارات النشطة
        /// </summary>
        public const string PROPERTIES_ALL_SET = "properties:all";
        
        #endregion

        #region الفهارس الجغرافية
        
        /// <summary>
        /// فهرس جغرافي عام لجميع العقارات: geo:properties → GEOADD
        /// </summary>
        public const string GEO_PROPERTIES = "geo:properties";
        
        /// <summary>
        /// فهرس جغرافي حسب المدينة: geo:cities:{city} → GEOADD
        /// </summary>
        public const string GEO_CITY = "geo:cities:{0}";
        
        #endregion

        #region فهارس الترتيب (Sorted Sets)
        
        /// <summary>
        /// فهرس السعر: idx:price → Sorted Set
        /// </summary>
        public const string INDEX_PRICE = "idx:price";
        
        /// <summary>
        /// فهرس التقييم: idx:rating → Sorted Set
        /// </summary>
        public const string INDEX_RATING = "idx:rating";
        
        /// <summary>
        /// فهرس تاريخ الإنشاء: idx:created → Sorted Set
        /// </summary>
        public const string INDEX_CREATED = "idx:created";
        
        /// <summary>
        /// فهرس عدد الحجوزات: idx:bookings → Sorted Set
        /// </summary>
        public const string INDEX_BOOKINGS = "idx:bookings";
        
        /// <summary>
        /// فهرس الشعبية: idx:popularity → Sorted Set
        /// </summary>
        public const string INDEX_POPULARITY = "idx:popularity";

        /// <summary>
        /// فهرس الحد الأقصى للبالغين على مستوى العقار: idx:max_adults → Sorted Set
        /// </summary>
        public const string INDEX_MAX_ADULTS = "idx:max_adults";

        /// <summary>
        /// فهرس الحد الأقصى للأطفال على مستوى العقار: idx:max_children → Sorted Set
        /// </summary>
        public const string INDEX_MAX_CHILDREN = "idx:max_children";

        /// <summary>
        /// فهرس السعة القصوى على مستوى العقار: idx:max_capacity → Sorted Set
        /// يستخدم لدعم فلتر GuestsCount في البحث البسيط
        /// </summary>
        public const string INDEX_MAX_CAPACITY = "idx:max_capacity";
        
        #endregion

        #region فهارس التصنيف (Sets)
        
        /// <summary>
        /// فهرس نوع العقار: tag:type:{typeId} → Set
        /// </summary>
        public const string TAG_TYPE = "tag:type:{0}";
        
        /// <summary>
        /// فهرس المدينة: tag:city:{city} → Set
        /// </summary>
        public const string TAG_CITY = "tag:city:{0}";
        
        /// <summary>
        /// فهرس المرافق: tag:amenity:{amenityId} → Set
        /// </summary>
        public const string TAG_AMENITY = "tag:amenity:{0}";
        
        /// <summary>
        /// فهرس الخدمات: tag:service:{serviceId} → Set
        /// </summary>
        public const string TAG_SERVICE = "tag:service:{0}";
        
        /// <summary>
        /// فهرس العقارات المميزة: tag:featured → Set
        /// </summary>
        public const string TAG_FEATURED = "tag:featured";

        /// <summary>
        /// عقارات تحتوي وحداتها على عدد بالغين (>0): tag:property:has_adults → Set
        /// </summary>
        public const string TAG_PROPERTY_HAS_ADULTS = "tag:property:has_adults";

        /// <summary>
        /// عقارات تحتوي وحداتها على عدد أطفال (>0): tag:property:has_children → Set
        /// </summary>
        public const string TAG_PROPERTY_HAS_CHILDREN = "tag:property:has_children";
        
        #endregion

        #region فهارس الحقول الديناميكية
        
        /// <summary>
        /// فهرس قيمة حقل ديناميكي: dynamic_value:{field}:{value} → Set
        /// يستخدم لدعم الفلترة المباشرة عبر Redis دون جلب كل البيانات للذاكرة
        /// </summary>
        public const string DYNAMIC_FIELD_VALUE = "dynamic_value:{0}:{1}";
        
        #endregion

        #region فهارس الوحدات
        
        /// <summary>
        /// مفتاح Hash للوحدة: unit:{id} → Hash
        /// </summary>
        public const string UNIT_HASH = "unit:{0}";
        
        /// <summary>
        /// مجموعة وحدات العقار: property:units:{propertyId} → Set
        /// </summary>
        public const string PROPERTY_UNITS = "property:units:{0}";
        
        /// <summary>
        /// فهرس نوع الوحدة: tag:unittype:{typeId} → Set
        /// </summary>
        public const string TAG_UNIT_TYPE = "tag:unittype:{0}";

        /// <summary>
        /// فهرس نوع الوحدة الذي يدعم عدد بالغين: tag:unittype:has_adults → Set (قائمة أنواع)
        /// </summary>
        public const string TAG_UNIT_TYPE_HAS_ADULTS = "tag:unittype:has_adults";

        /// <summary>
        /// فهرس نوع الوحدة الذي يدعم عدد أطفال: tag:unittype:has_children → Set (قائمة أنواع)
        /// </summary>
        public const string TAG_UNIT_TYPE_HAS_CHILDREN = "tag:unittype:has_children";

        /// <summary>
        /// فهرس وجود عدد بالغين على مستوى الوحدات: tag:unit:has_adults → Set (قائمة وحدات)
        /// </summary>
        public const string TAG_UNIT_HAS_ADULTS = "tag:unit:has_adults";

        /// <summary>
        /// فهرس وجود عدد أطفال على مستوى الوحدات: tag:unit:has_children → Set (قائمة وحدات)
        /// </summary>
        public const string TAG_UNIT_HAS_CHILDREN = "tag:unit:has_children";

        /// <summary>
        /// فهرس عدد البالغين للوحدة: idx:unit:max_adults → Sorted Set (member=unitId, score=maxAdults)
        /// </summary>
        public const string INDEX_UNIT_MAX_ADULTS = "idx:unit:max_adults";

        /// <summary>
        /// فهرس عدد الأطفال للوحدة: idx:unit:max_children → Sorted Set (member=unitId, score=maxChildren)
        /// </summary>
        public const string INDEX_UNIT_MAX_CHILDREN = "idx:unit:max_children";
        
        #endregion

        #region فهارس الإتاحة
        
        /// <summary>
        /// فهرس إتاحة الوحدة: avail:unit:{unitId} → Sorted Set
        /// </summary>
        public const string AVAILABILITY_UNIT = "avail:unit:{0}";
        
        /// <summary>
        /// فهرس الإتاحة حسب التاريخ: avail:date:{YYYYMMDD} → Set
        /// </summary>
        public const string AVAILABILITY_DATE = "avail:date:{0:yyyyMMdd}";
        
        /// <summary>
        /// فهرس الإتاحة للعقار: avail:property:{propertyId} → Set
        /// </summary>
        public const string AVAILABILITY_PROPERTY = "avail:property:{0}";
        
        #endregion

        #region فهارس التسعير
        
        /// <summary>
        /// قواعد تسعير الوحدة: pricing:unit:{unitId} → Hash
        /// </summary>
        public const string PRICING_UNIT = "pricing:unit:{0}";

        /// <summary>
        /// فهرس تسعير الوحدة كفترات مثل الإتاحة: price:unit:{unitId} → Sorted Set
        /// العنصر: "startTicks:endTicks:price:currency"، الدرجة = startTicks
        /// </summary>
        public const string PRICING_UNIT_ZSET = "price:unit:{0}";

        /// <summary>
        /// فهرس حسب التاريخ للتسعير (اختياري للاستخدامات المستقبلية): price:date:{YYYYMMDD} → Set
        /// </summary>
        public const string PRICING_DATE = "price:date:{0:yyyyMMdd}";
        
        /// <summary>
        /// كاش الأسعار المحسوبة: pricing:cache:{unitId}:{checkIn}:{checkOut} → String
        /// </summary>
        public const string PRICING_CACHE = "pricing:cache:{0}:{1:yyyyMMdd}:{2:yyyyMMdd}";
        
        #endregion

        #region فهرس البحث النصي (RediSearch)
        
        /// <summary>
        /// اسم فهرس RediSearch الرئيسي
        /// </summary>
        public const string SEARCH_INDEX_NAME = "idx:properties";
        
        /// <summary>
        /// بادئة المفاتيح لفهرس البحث
        /// </summary>
        public const string SEARCH_KEY_PREFIX = "property:";
        
        #endregion

        #region مفاتيح الكاش
        
        /// <summary>
        /// كاش نتائج البحث L1 (Memory): cache:search:l1:{hash}
        /// </summary>
        public const string CACHE_SEARCH_L1 = "cache:search:l1:{0}";
        
        /// <summary>
        /// كاش نتائج البحث L2 (Redis): cache:search:l2:{hash}
        /// </summary>
        public const string CACHE_SEARCH_L2 = "cache:search:l2:{0}";
        
        /// <summary>
        /// كاش البيانات L3 (Redis): cache:data:l3:{key}
        /// </summary>
        public const string CACHE_DATA_L3 = "cache:data:l3:{0}";
        
        /// <summary>
        /// كاش أسعار الصرف: cache:fx:{from}:{to}
        /// </summary>
        public const string CACHE_EXCHANGE_RATE = "cache:fx:{0}:{1}";
        
        #endregion

        #region مفاتيح Lua Scripts
        
        /// <summary>
        /// مفتاح تخزين Lua Script للبحث المعقد
        /// </summary>
        public const string LUA_COMPLEX_SEARCH = "lua:search:complex";
        
        /// <summary>
        /// مفتاح تخزين Lua Script لفلترة الإتاحة
        /// </summary>
        public const string LUA_AVAILABILITY_FILTER = "lua:filter:availability";
        
        /// <summary>
        /// مفتاح تخزين Lua Script لحساب الأسعار
        /// </summary>
        public const string LUA_PRICE_CALCULATOR = "lua:calc:price";
        
        #endregion

        #region مفاتيح المراقبة والإحصائيات
        
        /// <summary>
        /// عداد طلبات البحث: stats:search:count
        /// </summary>
        public const string STATS_SEARCH_COUNT = "stats:search:count";
        
        /// <summary>
        /// متوسط وقت الاستجابة: stats:search:latency
        /// </summary>
        public const string STATS_SEARCH_LATENCY = "stats:search:latency";
        
        /// <summary>
        /// معدل نجاح الكاش: stats:cache:hitrate
        /// </summary>
        public const string STATS_CACHE_HITRATE = "stats:cache:hitrate";
        
        /// <summary>
        /// عداد الأخطاء: stats:errors:{type}
        /// </summary>
        public const string STATS_ERRORS = "stats:errors:{0}";
        
        #endregion

        #region مفاتيح مؤقتة
        
        /// <summary>
        /// مفاتيح مؤقتة للعمليات: temp:{operation}:{guid}
        /// </summary>
        public const string TEMP_OPERATION = "temp:{0}:{1}";
        
        /// <summary>
        /// قفل للعمليات الحرجة: lock:{resource}:{id}
        /// </summary>
        public const string LOCK_RESOURCE = "lock:{0}:{1}";
        
        #endregion

        #region دوال مساعدة لبناء المفاتيح
        
        /// <summary>
        /// بناء مفتاح العقار
        /// </summary>
        public static string GetPropertyKey(Guid propertyId) 
            => string.Format(PROPERTY_HASH, propertyId);
        
        /// <summary>
        /// بناء مفتاح البيانات المسلسلة للعقار
        /// </summary>
        public static string GetPropertyBinaryKey(Guid propertyId) 
            => string.Format(PROPERTY_BINARY, propertyId);
        
        /// <summary>
        /// بناء مفتاح البيانات الوصفية للعقار
        /// </summary>
        public static string GetPropertyMetaKey(Guid propertyId) 
            => string.Format(PROPERTY_META, propertyId);
        
        /// <summary>
        /// بناء مفتاح المدينة
        /// </summary>
        public static string GetCityKey(string city) 
            => string.Format(TAG_CITY, city?.ToLowerInvariant() ?? "unknown");
        
        /// <summary>
        /// بناء مفتاح نوع العقار
        /// </summary>
        public static string GetTypeKey(Guid typeId) 
            => string.Format(TAG_TYPE, typeId);
        
        /// <summary>
        /// بناء مفتاح المرافق
        /// </summary>
        public static string GetAmenityKey(Guid amenityId) 
            => string.Format(TAG_AMENITY, amenityId);
        
        /// <summary>
        /// بناء مفتاح وحدات العقار
        /// </summary>
        public static string GetPropertyUnitsKey(Guid propertyId) 
            => string.Format(PROPERTY_UNITS, propertyId);
        
        /// <summary>
        /// بناء مفتاح الوحدة
        /// </summary>
        public static string GetUnitKey(Guid unitId) 
            => string.Format(UNIT_HASH, unitId);
        
        /// <summary>
        /// بناء مفتاح إتاحة الوحدة
        /// </summary>
        public static string GetUnitAvailabilityKey(Guid unitId) 
            => string.Format(AVAILABILITY_UNIT, unitId);
        
        /// <summary>
        /// بناء مفتاح التسعير للوحدة
        /// </summary>
        public static string GetUnitPricingKey(Guid unitId) 
            => string.Format(PRICING_UNIT, unitId);

        /// <summary>
        /// بناء مفتاح فهرس ZSET لتسعير الوحدة
        /// </summary>
        public static string GetUnitPricingZKey(Guid unitId)
            => string.Format(PRICING_UNIT_ZSET, unitId);
        
        /// <summary>
        /// بناء مفتاح كاش البحث L2
        /// </summary>
        public static string GetSearchCacheKey(string hash) 
            => string.Format(CACHE_SEARCH_L2, hash);
        
        /// <summary>
        /// بناء مفتاح القفل
        /// </summary>
        public static string GetLockKey(string resource, string id) 
            => string.Format(LOCK_RESOURCE, resource, id);
        
        /// <summary>
        /// بناء مفتاح فهرس لقيمة حقل ديناميكي
        /// </summary>
        public static string GetDynamicFieldValueKey(string field, string value)
            => string.Format(DYNAMIC_FIELD_VALUE,
                field?.ToLowerInvariant() ?? "unknown",
                value?.ToLowerInvariant() ?? "unknown");
        
        #endregion
    }
}
