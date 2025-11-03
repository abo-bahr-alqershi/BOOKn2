using System;
using System.Collections.Generic;
using System.Linq;
using StackExchange.Redis;
using MessagePack;

namespace YemenBooking.Infrastructure.Redis.Models
{
    /// <summary>
    /// نموذج فهرس العقار المحسن والشامل
    /// يحتوي على جميع البيانات اللازمة للبحث والفلترة
    /// </summary>
    [MessagePackObject]
    public class PropertyIndexDocument
    {
        #region الخصائص الأساسية
        
        /// <summary>
        /// معرف العقار الفريد
        /// </summary>
        [Key(0)]
        public Guid Id { get; set; }
        
        /// <summary>
        /// اسم العقار
        /// </summary>
        [Key(1)]
        public string Name { get; set; }
        
        /// <summary>
        /// اسم العقار بالأحرف الصغيرة للبحث
        /// </summary>
        [Key(2)]
        public string NameNormalized { get; set; }
        
        /// <summary>
        /// وصف العقار
        /// </summary>
        [Key(3)]
        public string Description { get; set; }
        
        #endregion

        #region بيانات الموقع
        
        /// <summary>
        /// اسم المدينة
        /// </summary>
        [Key(4)]
        public string City { get; set; }
        
        /// <summary>
        /// العنوان الكامل
        /// </summary>
        [Key(5)]
        public string FullAddress { get; set; }
        
        /// <summary>
        /// خط العرض
        /// </summary>
        [Key(6)]
        public double Latitude { get; set; }
        
        /// <summary>
        /// خط الطول
        /// </summary>
        [Key(7)]
        public double Longitude { get; set; }
        
        /// <summary>
        /// المنطقة أو الحي
        /// </summary>
        [Key(8)]
        public string District { get; set; }
        
        #endregion

        #region بيانات التصنيف
        
        /// <summary>
        /// معرف نوع العقار
        /// </summary>
        [Key(9)]
        public Guid PropertyTypeId { get; set; }
        
        /// <summary>
        /// اسم نوع العقار
        /// </summary>
        [Key(10)]
        public string PropertyTypeName { get; set; }
        
        /// <summary>
        /// تصنيف النجوم (1-5)
        /// </summary>
        [Key(11)]
        public int StarRating { get; set; }
        
        #endregion

        #region بيانات التسعير
        
        /// <summary>
        /// أقل سعر متاح
        /// </summary>
        [Key(12)]
        public decimal MinPrice { get; set; }
        
        /// <summary>
        /// أعلى سعر متاح
        /// </summary>
        [Key(13)]
        public decimal MaxPrice { get; set; }
        
        /// <summary>
        /// متوسط السعر
        /// </summary>
        [Key(14)]
        public decimal AveragePrice { get; set; }
        
        /// <summary>
        /// العملة الأساسية
        /// </summary>
        [Key(15)]
        public string BaseCurrency { get; set; }
        
        /// <summary>
        /// هل يوجد خصومات نشطة
        /// </summary>
        [Key(16)]
        public bool HasActiveDiscounts { get; set; }
        
        #endregion

        #region بيانات التقييم والشعبية
        
        /// <summary>
        /// متوسط التقييم (0-5)
        /// </summary>
        [Key(17)]
        public decimal AverageRating { get; set; }
        
        /// <summary>
        /// عدد التقييمات
        /// </summary>
        [Key(18)]
        public int ReviewsCount { get; set; }
        
        /// <summary>
        /// عدد الحجوزات الكلي
        /// </summary>
        [Key(19)]
        public int TotalBookings { get; set; }
        
        /// <summary>
        /// عدد المشاهدات
        /// </summary>
        [Key(20)]
        public int ViewsCount { get; set; }
        
        /// <summary>
        /// نقاط الشعبية المحسوبة
        /// </summary>
        [Key(21)]
        public double PopularityScore { get; set; }
        
        #endregion

        #region بيانات السعة والوحدات
        
        /// <summary>
        /// أقصى سعة استيعابية
        /// </summary>
        [Key(22)]
        public int MaxCapacity { get; set; }
        
        /// <summary>
        /// عدد الوحدات الكلي
        /// </summary>
        [Key(23)]
        public int TotalUnits { get; set; }
        
        /// <summary>
        /// عدد الوحدات المتاحة حالياً
        /// </summary>
        [Key(24)]
        public int AvailableUnitsCount { get; set; }
        
        /// <summary>
        /// معرفات الوحدات
        /// </summary>
        [Key(25)]
        public List<Guid> UnitIds { get; set; } = new();
        
        /// <summary>
        /// معرفات أنواع الوحدات المتوفرة في العقار
        /// </summary>
        [Key(251)]
        public List<Guid> UnitTypeIds { get; set; } = new();
        
        /// <summary>
        /// أسماء أنواع الوحدات للبحث النصي
        /// </summary>
        [Key(252)]
        public List<string> UnitTypeNames { get; set; } = new();
        
        /// <summary>
        /// الحد الأقصى لعدد البالغين عبر وحدات العقار
        /// </summary>
        [Key(253)]
        public int MaxAdults { get; set; }
        
        /// <summary>
        /// الحد الأقصى لعدد الأطفال عبر وحدات العقار
        /// </summary>
        [Key(254)]
        public int MaxChildren { get; set; }
        
        #endregion

        #region المرافق والخدمات
        
        /// <summary>
        /// معرفات المرافق المتوفرة
        /// </summary>
        [Key(26)]
        public List<Guid> AmenityIds { get; set; } = new();
        
        /// <summary>
        /// أسماء المرافق للبحث النصي
        /// </summary>
        [Key(27)]
        public List<string> AmenityNames { get; set; } = new();
        
        /// <summary>
        /// معرفات الخدمات المتوفرة
        /// </summary>
        [Key(28)]
        public List<Guid> ServiceIds { get; set; } = new();
        
        /// <summary>
        /// أسماء الخدمات للبحث النصي
        /// </summary>
        [Key(29)]
        public List<string> ServiceNames { get; set; } = new();
        
        #endregion

        #region الصور والوسائط
        
        /// <summary>
        /// روابط الصور
        /// </summary>
        [Key(30)]
        public List<string> ImageUrls { get; set; } = new();
        
        /// <summary>
        /// الصورة الرئيسية
        /// </summary>
        [Key(31)]
        public string MainImageUrl { get; set; }
        
        /// <summary>
        /// عدد الصور المتاحة
        /// </summary>
        [Key(32)]
        public int ImagesCount { get; set; }
        
        #endregion

        #region الحقول الديناميكية
        
        /// <summary>
        /// الحقول الديناميكية الإضافية
        /// </summary>
        [Key(33)]
        public Dictionary<string, string> DynamicFields { get; set; } = new();
        
        /// <summary>
        /// العلامات (Tags) للبحث
        /// </summary>
        [Key(34)]
        public List<string> Tags { get; set; } = new();
        
        #endregion

        #region بيانات الحالة
        
        /// <summary>
        /// هل العقار نشط
        /// </summary>
        [Key(35)]
        public bool IsActive { get; set; }
        
        /// <summary>
        /// هل العقار معتمد
        /// </summary>
        [Key(36)]
        public bool IsApproved { get; set; }
        
        /// <summary>
        /// هل العقار مميز
        /// </summary>
        [Key(37)]
        public bool IsFeatured { get; set; }
        
        /// <summary>
        /// هل العقار مفهرس
        /// </summary>
        [Key(38)]
        public bool IsIndexed { get; set; }
        
        #endregion

        #region بيانات المالك
        
        /// <summary>
        /// معرف المالك
        /// </summary>
        [Key(39)]
        public Guid OwnerId { get; set; }
        
        /// <summary>
        /// اسم المالك أو الشركة
        /// </summary>
        [Key(40)]
        public string OwnerName { get; set; }
        
        /// <summary>
        /// تقييم المالك
        /// </summary>
        [Key(41)]
        public decimal OwnerRating { get; set; }
        
        #endregion

        #region الطوابع الزمنية
        
        /// <summary>
        /// تاريخ الإنشاء
        /// </summary>
        [Key(42)]
        public DateTime CreatedAt { get; set; }
        
        /// <summary>
        /// تاريخ آخر تحديث
        /// </summary>
        [Key(43)]
        public DateTime UpdatedAt { get; set; }
        
        /// <summary>
        /// تاريخ آخر فهرسة
        /// </summary>
        [Key(44)]
        public DateTime LastIndexedAt { get; set; }
        
        /// <summary>
        /// عدد التكات لآخر تعديل (للمقارنة السريعة)
        /// </summary>
        [Key(45)]
        public long LastModifiedTicks { get; set; }
        
        #endregion

        #region دوال التحويل
        
        /// <summary>
        /// تحويل إلى HashEntry للتخزين في Redis
        /// </summary>
        public HashEntry[] ToHashEntries()
        {
            var entries = new List<HashEntry>
            {
                // الخصائص الأساسية
                new("id", Id.ToString()),
                new("name", Name ?? ""),
                new("name_lower", NameNormalized ?? Name?.ToLowerInvariant() ?? ""),
                // ✅ الحل الاحترافي: name_tag للبحث الدقيق في النصوص القصيرة
                new("name_tag", CreateSearchTags(Name)),
                new("description", Description ?? ""),
                
                // بيانات الموقع
                new("city", City ?? ""),
                new("address", FullAddress ?? ""),
                new("latitude", Latitude),
                new("longitude", Longitude),
                new("district", District ?? ""),
                
                // بيانات التصنيف
                new("property_type_id", PropertyTypeId.ToString()),
                new("property_type", PropertyTypeName ?? ""),
                // ✅ property_type_name كـ TAG للبحث بالاسم
                new("property_type_name", CreateSearchTags(PropertyTypeName)),
                new("star_rating", StarRating),
                
                // بيانات التسعير
                new("min_price", MinPrice.ToString()),
                new("max_price", MaxPrice.ToString()),
                new("avg_price", AveragePrice.ToString()),
                new("currency", BaseCurrency ?? "YER"),
                new("has_discounts", HasActiveDiscounts ? "1" : "0"),
                
                // بيانات التقييم والشعبية
                new("average_rating", AverageRating.ToString()),
                new("reviews_count", ReviewsCount),
                new("booking_count", TotalBookings),
                new("views_count", ViewsCount),
                new("popularity_score", PopularityScore),
                
                // بيانات السعة والوحدات
                new("max_capacity", MaxCapacity),
                new("units_count", TotalUnits),
                new("available_units", AvailableUnitsCount),
                new("max_adults", MaxAdults),
                new("max_children", MaxChildren),
                
                // بيانات الحالة
                new("is_active", IsActive ? "1" : "0"),
                new("is_approved", IsApproved ? "1" : "0"),
                new("is_featured", IsFeatured ? "1" : "0"),
                new("is_indexed", IsIndexed ? "1" : "0"),
                
                // بيانات المالك
                new("owner_id", OwnerId.ToString()),
                new("owner_name", OwnerName ?? ""),
                new("owner_rating", OwnerRating.ToString()),
                
                // الطوابع الزمنية
                new("created_at", CreatedAt.Ticks),
                new("updated_at", UpdatedAt.Ticks),
                new("indexed_at", LastIndexedAt.Ticks),
                new("modified_ticks", LastModifiedTicks),
                
                // الصور
                new("main_image", MainImageUrl ?? ""),
                new("images_count", ImagesCount),
                
                // معرفات وأنواع الوحدات
                new("unit_type_ids", string.Join(",", UnitTypeIds ?? new List<Guid>())),
                new("unit_type_names", string.Join(",", UnitTypeNames ?? new List<string>())),
                
                // معرفات المرافق والخدمات
                new("amenity_ids", string.Join(",", AmenityIds ?? new List<Guid>())),
                new("service_ids", string.Join(",", ServiceIds ?? new List<Guid>()))
            };
            
            // إضافة DynamicFields بطريقتين:
            // 1. individual fields (df:*) للقراءة المباشرة
            // 2. dynamic_fields TEXT للبحث عبر RediSearch
            if (DynamicFields != null && DynamicFields.Any())
            {
                // 1. Individual fields: df:wifi, df:pool, etc
                var dynamicEntries = DynamicFields.Select(kv => 
                    new HashEntry($"df:{kv.Key}", kv.Value ?? "")
                ).ToList();
                entries.AddRange(dynamicEntries);
                
                // 2. Concatenated TEXT field للبحث
                // Format: "key:value key:value ..."
                var searchableText = string.Join(" ", DynamicFields.Select(kv => 
                    $"{kv.Key}:{kv.Value}"));
                entries.Add(new HashEntry("dynamic_fields", searchableText));
            }
            else
            {
                entries.Add(new HashEntry("dynamic_fields", ""));
            }
            
            return entries.ToArray();
        }
        
        /// <summary>
        /// إنشاء من HashEntry المخزنة في Redis
        /// </summary>
        public static PropertyIndexDocument FromHashEntries(HashEntry[] entries)
        {
            var dict = entries.ToDictionary(x => x.Name.ToString(), x => x.Value);
            
            // استخراج DynamicFields من individual fields بـ prefix "df:"
            var dynamicFields = new Dictionary<string, string>();
            foreach (var entry in entries)
            {
                var key = entry.Name.ToString();
                if (key.StartsWith("df:"))
                {
                    var fieldName = key.Substring(3); // إزالة "df:" prefix
                    dynamicFields[fieldName] = entry.Value.ToString();
                }
            }
            
            return new PropertyIndexDocument
            {
                // الخصائص الأساسية
                Id = Guid.Parse(dict.GetValueOrDefault("id", Guid.Empty.ToString())),
                Name = dict.GetValueOrDefault("name"),
                NameNormalized = dict.GetValueOrDefault("name_lower"),
                Description = dict.GetValueOrDefault("description"),
                
                // بيانات الموقع
                City = dict.GetValueOrDefault("city"),
                FullAddress = dict.GetValueOrDefault("address"),
                Latitude = double.Parse(dict.GetValueOrDefault("latitude", "0")),
                Longitude = double.Parse(dict.GetValueOrDefault("longitude", "0")),
                District = dict.GetValueOrDefault("district"),
                
                // بيانات التصنيف
                PropertyTypeId = Guid.Parse(dict.GetValueOrDefault("property_type_id", Guid.Empty.ToString())),
                PropertyTypeName = dict.GetValueOrDefault("property_type"),
                StarRating = int.Parse(dict.GetValueOrDefault("star_rating", "0")),
                
                // بيانات التسعير
                MinPrice = decimal.Parse(dict.GetValueOrDefault("min_price", "0")),
                MaxPrice = decimal.Parse(dict.GetValueOrDefault("max_price", "0")),
                AveragePrice = decimal.Parse(dict.GetValueOrDefault("avg_price", "0")),
                BaseCurrency = dict.GetValueOrDefault("currency", "YER"),
                HasActiveDiscounts = dict.GetValueOrDefault("has_discounts") == "1",
                
                // بيانات التقييم والشعبية
                AverageRating = decimal.Parse(dict.GetValueOrDefault("average_rating", "0")),
                ReviewsCount = int.Parse(dict.GetValueOrDefault("reviews_count", "0")),
                TotalBookings = int.Parse(dict.GetValueOrDefault("booking_count", "0")),
                ViewsCount = int.Parse(dict.GetValueOrDefault("views_count", "0")),
                PopularityScore = double.Parse(dict.GetValueOrDefault("popularity_score", "0")),
                
                // بيانات السعة والوحدات
                MaxCapacity = int.Parse(dict.GetValueOrDefault("max_capacity", "0")),
                TotalUnits = int.Parse(dict.GetValueOrDefault("units_count", "0")),
                AvailableUnitsCount = int.Parse(dict.GetValueOrDefault("available_units", "0")),
                MaxAdults = int.Parse(dict.GetValueOrDefault("max_adults", "0")),
                MaxChildren = int.Parse(dict.GetValueOrDefault("max_children", "0")),
                
                // بيانات الحالة
                IsActive = dict.GetValueOrDefault("is_active") == "1",
                IsApproved = dict.GetValueOrDefault("is_approved") == "1",
                IsFeatured = dict.GetValueOrDefault("is_featured") == "1",
                IsIndexed = dict.GetValueOrDefault("is_indexed") == "1",
                
                // بيانات المالك
                OwnerId = Guid.Parse(dict.GetValueOrDefault("owner_id", Guid.Empty.ToString())),
                OwnerName = dict.GetValueOrDefault("owner_name"),
                OwnerRating = decimal.Parse(dict.GetValueOrDefault("owner_rating", "0")),
                
                // الطوابع الزمنية
                CreatedAt = new DateTime(long.Parse(dict.GetValueOrDefault("created_at", "0"))),
                UpdatedAt = new DateTime(long.Parse(dict.GetValueOrDefault("updated_at", "0"))),
                LastIndexedAt = new DateTime(long.Parse(dict.GetValueOrDefault("indexed_at", "0"))),
                LastModifiedTicks = long.Parse(dict.GetValueOrDefault("modified_ticks", "0")),
                
                // الصور
                MainImageUrl = dict.GetValueOrDefault("main_image"),
                ImagesCount = int.Parse(dict.GetValueOrDefault("images_count", "0")),
                
                // معرفات وأنواع الوحدات
                UnitTypeIds = ParseGuidsFromString(dict.GetValueOrDefault("unit_type_ids", "")),
                UnitTypeNames = ParseStringsFromString(dict.GetValueOrDefault("unit_type_names", "")),
                
                // معرفات المرافق والخدمات
                AmenityIds = ParseGuidsFromString(dict.GetValueOrDefault("amenity_ids", "")),
                ServiceIds = ParseGuidsFromString(dict.GetValueOrDefault("service_ids", "")),
                
                // الحقول الديناميكية
                DynamicFields = dynamicFields
            };
        }
        
        /// <summary>
        /// حساب نقاط الشعبية بناءً على عدة عوامل
        /// </summary>
        public void CalculatePopularityScore()
        {
            // صيغة حساب الشعبية المتقدمة
            var ratingWeight = 0.3;
            var bookingWeight = 0.3;
            var viewWeight = 0.1;
            var reviewWeight = 0.2;
            var featuredWeight = 0.1;
            
            // تطبيع القيم (0-1)
            var normalizedRating = Math.Min((double)AverageRating / 5.0, 1.0);
            var normalizedBookings = Math.Min(TotalBookings / 100.0, 1.0);
            var normalizedViews = Math.Min(ViewsCount / 1000.0, 1.0);
            var normalizedReviews = Math.Min(ReviewsCount / 50.0, 1.0);
            var featuredBonus = IsFeatured ? 1.0 : 0.0;
            
            // حساب النقاط
            var score = (normalizedRating * ratingWeight) +
                        (normalizedBookings * bookingWeight) +
                        (normalizedViews * viewWeight) +
                        (normalizedReviews * reviewWeight) +
                        (featuredBonus * featuredWeight);
            
            // تحويل إلى نطاق 0-100
            PopularityScore = score * 100;
        }
        
        /// <summary>
        /// تحليل معرفات GUIDs من نص
        /// </summary>
        private static List<Guid> ParseGuidsFromString(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return new List<Guid>();
            
            return value.Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Select(s => Guid.TryParse(s, out var guid) ? guid : Guid.Empty)
                .Where(g => g != Guid.Empty)
                .ToList();
        }
        
        /// <summary>
        /// إنشاء tags للبحث من نص - يفصل بـ | للاستخدام في TAG fields
        /// الحل الاحترافي للنصوص القصيرة: تقسيم الكلمات + إضافة النص الكامل
        /// </summary>
        private static string CreateSearchTags(string? text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return "";
            
            // تنظيف النص
            var cleanText = text.Trim();
            
            // تقسيم الكلمات وإضافة النص الكامل
            var words = cleanText.Split(new[] { ' ', '\t', '\n', '\r', '-', '_' }, 
                StringSplitOptions.RemoveEmptyEntries);
            
            var tags = new List<string> { cleanText }; // النص الكامل
            tags.AddRange(words.Select(w => w.Trim()).Where(w => w.Length > 2)); // الكلمات الفردية
            
            // ✅ إضافة lowercase versions - نسخة مستقلة لتجنب modification during enumeration
            var originalTags = tags.ToList(); // نسخة آمنة
            tags.AddRange(originalTags.Select(t => t.ToLowerInvariant()).Distinct());
            
            return string.Join("|", tags.Distinct());
        }
        
        /// <summary>
        /// تحليل قائمة نصوص من نص
        /// </summary>
        private static List<string> ParseStringsFromString(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return new List<string>();
            
            return value.Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Select(s => s.Trim())
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .ToList();
        }
        
        /// <summary>
        /// تحليل الحقول الديناميكية من JSON
        /// </summary>
        private static Dictionary<string, string> ParseDynamicFields(string jsonValue)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(jsonValue) || jsonValue == "{}") 
                    return new Dictionary<string, string>();
                    
                return System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(jsonValue) 
                    ?? new Dictionary<string, string>();
            }
            catch
            {
                return new Dictionary<string, string>();
            }
        }
        
        #endregion
    }
}
