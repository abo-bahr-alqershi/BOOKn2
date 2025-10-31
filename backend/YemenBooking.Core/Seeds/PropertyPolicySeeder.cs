using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية لسياسات العقارات
    /// Property Policies Seeder
    /// </summary>
    public class PropertyPolicySeeder : ISeeder<PropertyPolicy>
    {
        // معرفات العقارات الثابتة (يجب أن تتطابق مع PropertySeeder)
        private static readonly Guid Property1Id = Guid.Parse("10000000-0000-0000-0000-000000000001");
        private static readonly Guid Property2Id = Guid.Parse("10000000-0000-0000-0000-000000000002");
        private static readonly Guid Property3Id = Guid.Parse("10000000-0000-0000-0000-000000000003");
        private static readonly Guid Property4Id = Guid.Parse("10000000-0000-0000-0000-000000000004");
        private static readonly Guid Property5Id = Guid.Parse("10000000-0000-0000-0000-000000000005");

        public IEnumerable<PropertyPolicy> SeedData()
        {
            var policies = new List<PropertyPolicy>();
            // Fixed: Use static date instead of DateTime.UtcNow for PostgreSQL compatibility
            var baseDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

            // ========== فندق الزهراء - Property 1 ==========
            
            // سياسة الإلغاء
            // Fixed: Use static GUIDs instead of Guid.NewGuid() for PostgreSQL compatibility
            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000001"),
                PropertyId = Property1Id,
                Type = PolicyType.Cancellation,
                Description = "سياسة إلغاء مرنة: يمكن الإلغاء مجاناً قبل 48 ساعة من موعد تسجيل الوصول",
                Rules = "{\"freeCancel\":true,\"fullRefund\":true,\"penaltyAfterDeadline\":\"100%\"}",
                CancellationWindowDays = 2,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 20,
                MinHoursBeforeCheckIn = 48,
                CreatedAt = baseDate.AddDays(-30),
                UpdatedAt = baseDate.AddDays(-30),
                IsActive = true,
                IsDeleted = false
            });

            // سياسة الدفع
            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000002"),
                PropertyId = Property1Id,
                Type = PolicyType.Payment,
                Description = "يتطلب دفع مقدمة 20% عند الحجز، والباقي عند تسجيل الوصول",
                Rules = "{\"depositRequired\":true,\"acceptedMethods\":[\"بطاقة ائتمان\",\"نقداً\",\"تحويل بنكي\"]}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 20,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-30),
                UpdatedAt = baseDate.AddDays(-30),
                IsActive = true,
                IsDeleted = false
            });

            // سياسة تسجيل الوصول
            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000003"),
                PropertyId = Property1Id,
                Type = PolicyType.CheckIn,
                Description = "تسجيل الوصول من الساعة 2 ظهراً، تسجيل المغادرة حتى 12 ظهراً",
                Rules = "{\"checkInTime\":\"14:00\",\"checkOutTime\":\"12:00\",\"earlyCheckIn\":\"متاح بطلب مسبق\",\"lateCheckOut\":\"متاح مقابل رسوم\"}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 24,
                CreatedAt = baseDate.AddDays(-30),
                UpdatedAt = baseDate.AddDays(-30),
                IsActive = true,
                IsDeleted = false
            });

            // سياسة الأطفال
            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000004"),
                PropertyId = Property1Id,
                Type = PolicyType.Children,
                Description = "الأطفال أقل من 6 سنوات مجاناً، من 6-12 سنة بنصف السعر",
                Rules = "{\"childrenAllowed\":true,\"freeUnder\":6,\"halfPriceUnder\":12,\"maxChildrenPerRoom\":2}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-30),
                UpdatedAt = baseDate.AddDays(-30),
                IsActive = true,
                IsDeleted = false
            });

            // سياسة الحيوانات الأليفة
            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000005"),
                PropertyId = Property1Id,
                Type = PolicyType.Pets,
                Description = "لا يُسمح باصطحاب الحيوانات الأليفة",
                Rules = "{\"petsAllowed\":false,\"reason\":\"للحفاظ على راحة جميع النزلاء\"}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-30),
                UpdatedAt = baseDate.AddDays(-30),
                IsActive = true,
                IsDeleted = false
            });

            // سياسة التعديل
            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000006"),
                PropertyId = Property1Id,
                Type = PolicyType.Modification,
                Description = "يمكن تعديل الحجز مجاناً قبل 24 ساعة من موعد الوصول",
                Rules = "{\"modificationAllowed\":true,\"freeModificationHours\":24,\"feesAfter\":\"10% من قيمة الحجز\"}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 24,
                CreatedAt = baseDate.AddDays(-30),
                UpdatedAt = baseDate.AddDays(-30),
                IsActive = true,
                IsDeleted = false
            });

            // ========== منتجع البحر - Property 2 ==========
            
            // سياسة إلغاء صارمة
            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000007"),
                PropertyId = Property2Id,
                Type = PolicyType.Cancellation,
                Description = "سياسة إلغاء صارمة: استرداد 50% إذا تم الإلغاء قبل 7 أيام",
                Rules = "{\"freeCancel\":false,\"refundPercentage\":50,\"daysBeforeCheckIn\":7}",
                CancellationWindowDays = 7,
                RequireFullPaymentBeforeConfirmation = true,
                MinimumDepositPercentage = 100,
                MinHoursBeforeCheckIn = 168,
                CreatedAt = baseDate.AddDays(-25),
                UpdatedAt = baseDate.AddDays(-25),
                IsActive = true,
                IsDeleted = false
            });

            // سياسة دفع كامل
            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000008"),
                PropertyId = Property2Id,
                Type = PolicyType.Payment,
                Description = "يتطلب الدفع الكامل عند تأكيد الحجز",
                Rules = "{\"fullPaymentRequired\":true,\"acceptedMethods\":[\"بطاقة ائتمان\",\"تحويل بنكي\"]}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = true,
                MinimumDepositPercentage = 100,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-25),
                UpdatedAt = baseDate.AddDays(-25),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000009"),
                PropertyId = Property2Id,
                Type = PolicyType.CheckIn,
                Description = "تسجيل الوصول من 3 عصراً، المغادرة حتى 11 صباحاً",
                Rules = "{\"checkInTime\":\"15:00\",\"checkOutTime\":\"11:00\",\"lateCheckOutFee\":\"50% من سعر الليلة\"}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 48,
                CreatedAt = baseDate.AddDays(-25),
                UpdatedAt = baseDate.AddDays(-25),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000010"),
                PropertyId = Property2Id,
                Type = PolicyType.Children,
                Description = "الأطفال أقل من 12 سنة مجاناً مع والديهم",
                Rules = "{\"childrenAllowed\":true,\"freeUnder\":12,\"maxChildren\":3}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-25),
                UpdatedAt = baseDate.AddDays(-25),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000011"),
                PropertyId = Property2Id,
                Type = PolicyType.Pets,
                Description = "يُسمح بالحيوانات الأليفة الصغيرة مقابل رسوم إضافية",
                Rules = "{\"petsAllowed\":true,\"fee\":5000,\"maxWeight\":\"10 كجم\",\"requiresApproval\":true}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-25),
                UpdatedAt = baseDate.AddDays(-25),
                IsActive = true,
                IsDeleted = false
            });

            // ========== شقق النخيل - Property 3 ==========
            
            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000012"),
                PropertyId = Property3Id,
                Type = PolicyType.Cancellation,
                Description = "سياسة إلغاء معتدلة: إلغاء مجاني قبل 5 أيام، بعدها يُحتفظ بالمقدمة",
                Rules = "{\"freeCancel\":true,\"daysBeforeCheckIn\":5,\"penaltyAfter\":\"فقدان المقدمة\"}",
                CancellationWindowDays = 5,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 30,
                MinHoursBeforeCheckIn = 120,
                CreatedAt = baseDate.AddDays(-20),
                UpdatedAt = baseDate.AddDays(-20),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000013"),
                PropertyId = Property3Id,
                Type = PolicyType.Payment,
                Description = "دفع مقدمة 30% عند الحجز، الباقي نقداً عند الوصول",
                Rules = "{\"depositPercentage\":30,\"acceptCash\":true,\"acceptCard\":false}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 30,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-20),
                UpdatedAt = baseDate.AddDays(-20),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000014"),
                PropertyId = Property3Id,
                Type = PolicyType.CheckIn,
                Description = "تسجيل الوصول مرن من 12 ظهراً إلى 10 مساءً",
                Rules = "{\"checkInFrom\":\"12:00\",\"checkInUntil\":\"22:00\",\"checkOutTime\":\"12:00\",\"flexible\":true}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 12,
                CreatedAt = baseDate.AddDays(-20),
                UpdatedAt = baseDate.AddDays(-20),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000015"),
                PropertyId = Property3Id,
                Type = PolicyType.Children,
                Description = "مرحب بالأطفال من جميع الأعمار، أطفال أقل من 3 سنوات مجاناً",
                Rules = "{\"childrenAllowed\":true,\"freeUnder\":3,\"cribs\":\"متوفرة عند الطلب\"}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-20),
                UpdatedAt = baseDate.AddDays(-20),
                IsActive = true,
                IsDeleted = false
            });

            // ========== فيلا الياسمين - Property 4 ==========
            
            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000016"),
                PropertyId = Property4Id,
                Type = PolicyType.Cancellation,
                Description = "سياسة إلغاء شديدة الصرامة: لا استرداد للمبالغ المدفوعة",
                Rules = "{\"freeCancel\":false,\"refundPercentage\":0,\"nonRefundable\":true}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = true,
                MinimumDepositPercentage = 100,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-15),
                UpdatedAt = baseDate.AddDays(-15),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000017"),
                PropertyId = Property4Id,
                Type = PolicyType.Payment,
                Description = "الدفع الكامل مطلوب عند الحجز لتأكيد الحجز",
                Rules = "{\"fullPaymentRequired\":true,\"acceptedMethods\":[\"بطاقة ائتمان\"]}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = true,
                MinimumDepositPercentage = 100,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-15),
                UpdatedAt = baseDate.AddDays(-15),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000018"),
                PropertyId = Property4Id,
                Type = PolicyType.CheckIn,
                Description = "تسجيل وصول مرن حسب الاتفاق المسبق",
                Rules = "{\"flexibleCheckIn\":true,\"requiresCoordination\":true,\"contactOwner\":true}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 72,
                CreatedAt = baseDate.AddDays(-15),
                UpdatedAt = baseDate.AddDays(-15),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000019"),
                PropertyId = Property4Id,
                Type = PolicyType.Pets,
                Description = "لا يُسمح بالحيوانات الأليفة مطلقاً",
                Rules = "{\"petsAllowed\":false,\"strict\":true}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-15),
                UpdatedAt = baseDate.AddDays(-15),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000020"),
                PropertyId = Property4Id,
                Type = PolicyType.Modification,
                Description = "لا يمكن تعديل الحجز بعد التأكيد",
                Rules = "{\"modificationAllowed\":false,\"reason\":\"حجز غير قابل للتعديل\"}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-15),
                UpdatedAt = baseDate.AddDays(-15),
                IsActive = true,
                IsDeleted = false
            });

            // ========== استراحة الجبل - Property 5 ==========
            
            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000021"),
                PropertyId = Property5Id,
                Type = PolicyType.Cancellation,
                Description = "سياسة إلغاء مرنة جداً: إلغاء مجاني حتى 24 ساعة قبل الوصول",
                Rules = "{\"freeCancel\":true,\"hoursBeforeCheckIn\":24,\"fullRefund\":true}",
                CancellationWindowDays = 1,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 10,
                MinHoursBeforeCheckIn = 24,
                CreatedAt = baseDate.AddDays(-10),
                UpdatedAt = baseDate.AddDays(-10),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000022"),
                PropertyId = Property5Id,
                Type = PolicyType.Payment,
                Description = "مقدمة رمزية 10% للحجز، الباقي عند الوصول",
                Rules = "{\"depositPercentage\":10,\"payAtProperty\":true,\"cashPreferred\":true}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 10,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-10),
                UpdatedAt = baseDate.AddDays(-10),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000023"),
                PropertyId = Property5Id,
                Type = PolicyType.Children,
                Description = "عائلي 100%: مرحب بالأطفال، ألعاب ومرافق خاصة متوفرة",
                Rules = "{\"childrenAllowed\":true,\"freeUnder\":8,\"playground\":true,\"kidsMenu\":true}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-10),
                UpdatedAt = baseDate.AddDays(-10),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000024"),
                PropertyId = Property5Id,
                Type = PolicyType.Pets,
                Description = "يُسمح بالحيوانات الأليفة بدون رسوم إضافية",
                Rules = "{\"petsAllowed\":true,\"noFees\":true,\"petFriendly\":true,\"outdoorSpace\":true}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 0,
                CreatedAt = baseDate.AddDays(-10),
                UpdatedAt = baseDate.AddDays(-10),
                IsActive = true,
                IsDeleted = false
            });

            policies.Add(new PropertyPolicy
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000025"),
                PropertyId = Property5Id,
                Type = PolicyType.Modification,
                Description = "تعديل مجاني للحجز في أي وقت قبل 12 ساعة من الوصول",
                Rules = "{\"modificationAllowed\":true,\"freeModificationHours\":12,\"flexible\":true}",
                CancellationWindowDays = 0,
                RequireFullPaymentBeforeConfirmation = false,
                MinimumDepositPercentage = 0,
                MinHoursBeforeCheckIn = 12,
                CreatedAt = baseDate.AddDays(-10),
                UpdatedAt = baseDate.AddDays(-10),
                IsActive = true,
                IsDeleted = false
            });

            return policies;
        }
    }
}
