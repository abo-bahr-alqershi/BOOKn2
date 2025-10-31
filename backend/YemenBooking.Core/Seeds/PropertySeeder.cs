using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية لكائن Property
    /// </summary>
    public class PropertySeeder : ISeeder<Property>
    {
        // معرفات ثابتة للعقارات (لربطها بالسياسات)
        public static readonly Guid Property1Id = Guid.Parse("10000000-0000-0000-0000-000000000001");
        public static readonly Guid Property2Id = Guid.Parse("10000000-0000-0000-0000-000000000002");
        public static readonly Guid Property3Id = Guid.Parse("10000000-0000-0000-0000-000000000003");
        public static readonly Guid Property4Id = Guid.Parse("10000000-0000-0000-0000-000000000004");
        public static readonly Guid Property5Id = Guid.Parse("10000000-0000-0000-0000-000000000005");
        public static readonly Guid Property6Id = Guid.Parse("10000000-0000-0000-0000-000000000006");
        public static readonly Guid Property7Id = Guid.Parse("10000000-0000-0000-0000-000000000007");
        public static readonly Guid Property8Id = Guid.Parse("10000000-0000-0000-0000-000000000008");
        public static readonly Guid Property9Id = Guid.Parse("10000000-0000-0000-0000-000000000009");
        public static readonly Guid Property10Id = Guid.Parse("10000000-0000-0000-0000-000000000010");
        public static readonly Guid Property11Id = Guid.Parse("10000000-0000-0000-0000-000000000011");
        public static readonly Guid Property12Id = Guid.Parse("10000000-0000-0000-0000-000000000012");
        public static readonly Guid Property13Id = Guid.Parse("10000000-0000-0000-0000-000000000013");
        public static readonly Guid Property14Id = Guid.Parse("10000000-0000-0000-0000-000000000014");
        public static readonly Guid Property15Id = Guid.Parse("10000000-0000-0000-0000-000000000015");
        
        // معرف المالك (Owner User)
        private static readonly Guid OwnerId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB");
        
        // معرف نوع عقار افتراضي
        private static readonly Guid PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000001");

        public IEnumerable<Property> SeedData()
        {
            // Fixed: Use static date instead of DateTime.UtcNow for PostgreSQL compatibility
            var baseDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            
            return new List<Property>
            {
                // فندق الزهراء - صنعاء
                new Property
                {
                    Id = Property1Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "فندق الزهراء",
                    Address = "شارع الزبيري، صنعاء القديمة",
                    City = "صنعاء",
                    Latitude = 15.3694m,
                    Longitude = 44.1910m,
                    StarRating = 4,
                    Description = "فندق راقي في قلب صنعاء القديمة، يوفر إطلالات رائعة على المدينة التاريخية",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-60),
                    ViewCount = 1250,
                    BookingCount = 89,
                    Currency = "YER",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // منتجع البحر - عدن
                new Property
                {
                    Id = Property2Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "منتجع البحر",
                    Address = "كورنيش عدن، خور مكسر",
                    City = "عدن",
                    Latitude = 12.8000m,
                    Longitude = 45.0367m,
                    StarRating = 5,
                    Description = "منتجع شاطئي فاخر مع خدمات عالمية ومرافق ترفيهية متكاملة",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-50),
                    ViewCount = 2100,
                    BookingCount = 145,
                    Currency = "YER",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // شقق النخيل - تعز
                new Property
                {
                    Id = Property3Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "شقق النخيل المفروشة",
                    Address = "حي الروضة، تعز",
                    City = "تعز",
                    Latitude = 13.5779m,
                    Longitude = 44.0179m,
                    StarRating = 3,
                    Description = "شقق مفروشة عائلية بمواصفات عالية ومرافق حديثة",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-40),
                    ViewCount = 850,
                    BookingCount = 67,
                    Currency = "YER",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // فيلا الياسمين - صنعاء
                new Property
                {
                    Id = Property4Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "فيلا الياسمين",
                    Address = "حدة، شارع النصر",
                    City = "صنعاء",
                    Latitude = 15.3547m,
                    Longitude = 44.2066m,
                    StarRating = 5,
                    Description = "فيلا فاخرة للإيجار الكامل، مثالية للعائلات والمناسبات الخاصة",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-30),
                    ViewCount = 680,
                    BookingCount = 23,
                    Currency = "YER",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // استراحة الجبل - صنعاء
                new Property
                {
                    Id = Property5Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "استراحة الجبل",
                    Address = "وادي ظهر، غرب صنعاء",
                    City = "صنعاء",
                    Latitude = 15.4200m,
                    Longitude = 44.1500m,
                    StarRating = 4,
                    Description = "استراحة جبلية هادئة محاطة بالطبيعة، مثالية للعائلات",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-20),
                    ViewCount = 920,
                    BookingCount = 56,
                    Currency = "YER",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // فندق المرجان - عدن
                new Property
                {
                    Id = Property6Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "فندق المرجان",
                    Address = "المعلا، عدن",
                    City = "عدن",
                    Latitude = 12.7839m,
                    Longitude = 45.0187m,
                    StarRating = 3,
                    Description = "فندق اقتصادي في موقع استراتيجي بالقرب من المطار والميناء",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-90),
                    ViewCount = 1580,
                    BookingCount = 234,
                    Currency = "YER",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // منتجع الوادي السياحي - تعز
                new Property
                {
                    Id = Property7Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "منتجع الوادي السياحي",
                    Address = "وادي الضباب، تعز",
                    City = "تعز",
                    Latitude = 13.5925m,
                    Longitude = 43.9950m,
                    StarRating = 4,
                    Description = "منتجع سياحي جبلي بإطلالة خلابة على الوادي الأخضر",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-75),
                    ViewCount = 2240,
                    BookingCount = 187,
                    Currency = "USD",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // شقق السعيد المفروشة - صنعاء
                new Property
                {
                    Id = Property8Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "شقق السعيد المفروشة",
                    Address = "شارع تعز، صنعاء الجديدة",
                    City = "صنعاء",
                    Latitude = 15.3320m,
                    Longitude = 44.2130m,
                    StarRating = 3,
                    Description = "شقق مفروشة حديثة ومجهزة بالكامل، مناسبة للإقامات الطويلة",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-55),
                    ViewCount = 975,
                    BookingCount = 142,
                    Currency = "YER",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // فيلا البحر الأحمر - عدن
                new Property
                {
                    Id = Property9Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "فيلا البحر الأحمر",
                    Address = "جولد مور، عدن",
                    City = "عدن",
                    Latitude = 12.8205m,
                    Longitude = 45.0560m,
                    StarRating = 5,
                    Description = "فيلا فاخرة على شاطئ البحر مع مسبح خاص وخدمات VIP",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-35),
                    ViewCount = 3420,
                    BookingCount = 78,
                    Currency = "USD",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // بيت الضيافة التراثي - صنعاء
                new Property
                {
                    Id = Property10Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "بيت الضيافة التراثي",
                    Address = "باب اليمن، صنعاء القديمة",
                    City = "صنعاء",
                    Latitude = 15.3615m,
                    Longitude = 44.1874m,
                    StarRating = 4,
                    Description = "بيت تراثي يمني أصيل مع ديكور عتيق وخدمات حديثة",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-110),
                    ViewCount = 2850,
                    BookingCount = 196,
                    Currency = "YER",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // استوديوهات النهضة - تعز
                new Property
                {
                    Id = Property11Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "استوديوهات النهضة",
                    Address = "شارع جمال، تعز",
                    City = "تعز",
                    Latitude = 13.5795m,
                    Longitude = 44.0245m,
                    StarRating = 2,
                    Description = "استوديوهات صغيرة اقتصادية مناسبة للمسافرين الأفراد",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-45),
                    ViewCount = 650,
                    BookingCount = 98,
                    Currency = "YER",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // فندق القصر الذهبي - عدن
                new Property
                {
                    Id = Property12Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "فندق القصر الذهبي",
                    Address = "كريتر، عدن",
                    City = "عدن",
                    Latitude = 12.7797m,
                    Longitude = 44.9978m,
                    StarRating = 5,
                    Description = "فندق فاخر بموقع متميز في قلب المدينة التاريخية",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-125),
                    ViewCount = 4200,
                    BookingCount = 312,
                    Currency = "USD",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // شاليهات الريف - صنعاء
                new Property
                {
                    Id = Property13Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "شاليهات الريف",
                    Address = "منطقة حدة، شمال صنعاء",
                    City = "صنعاء",
                    Latitude = 15.3890m,
                    Longitude = 44.1980m,
                    StarRating = 4,
                    Description = "شاليهات مستقلة محاطة بالحدائق الخضراء مع مرافق شواء",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-65),
                    ViewCount = 1470,
                    BookingCount = 123,
                    Currency = "YER",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // أجنحة الأندلس - تعز
                new Property
                {
                    Id = Property14Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "أجنحة الأندلس الفندقية",
                    Address = "المظفر، تعز",
                    City = "تعز",
                    Latitude = 13.5811m,
                    Longitude = 44.0220m,
                    StarRating = 4,
                    Description = "أجنحة فندقية واسعة مع صالة معيشة منفصلة ومطبخ صغير",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-85),
                    ViewCount = 1920,
                    BookingCount = 167,
                    Currency = "YER",
                    IsActive = true,
                    IsDeleted = false
                },
                
                // منتجع السياحة الساحلي - عدن
                new Property
                {
                    Id = Property15Id,
                    OwnerId = OwnerId,
                    TypeId = PropertyTypeId,
                    Name = "منتجع السياحة الساحلي",
                    Address = "شاطئ أبين، عدن",
                    City = "عدن",
                    Latitude = 12.8112m,
                    Longitude = 45.0422m,
                    StarRating = 5,
                    Description = "منتجع شاطئي فخم مع جميع المرافق الترفيهية والرياضية المائية",
                    IsApproved = true,
                    CreatedAt = baseDate.AddDays(-100),
                    ViewCount = 5100,
                    BookingCount = 289,
                    Currency = "USD",
                    IsActive = true,
                    IsFeatured = true,
                    IsDeleted = false
                }
            };
        }
    }
} 