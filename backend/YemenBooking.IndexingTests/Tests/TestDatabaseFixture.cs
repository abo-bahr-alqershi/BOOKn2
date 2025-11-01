using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Infrastructure.Redis.Configuration;
using YemenBooking.Infrastructure.Repositories;
using YemenBooking.Infrastructure.Services;
using YemenBooking.Infrastructure.Services.RedisConnectionManager;

namespace YemenBooking.IndexingTests.Tests
{
    /// <summary>
    /// موفر البيانات والخدمات للاختبارات
    /// يتم إنشاؤه مرة واحدة ومشاركته بين جميع الاختبارات
    /// </summary>
    public class TestDatabaseFixture : IDisposable
    {
        /// <summary>
        /// موفر الخدمات الرئيسي
        /// </summary>
        public IServiceProvider ServiceProvider { get; private set; }

        /// <summary>
        /// التكوين
        /// </summary>
        public IConfiguration Configuration { get; private set; }

        /// <summary>
        /// قاعدة البيانات الاختبارية
        /// </summary>
        public YemenBookingDbContext DbContext { get; private set; }

        /// <summary>
        /// مدير اتصال Redis
        /// </summary>
        public IRedisConnectionManager RedisManager { get; private set; }

        /// <summary>
        /// خدمة الفهرسة
        /// </summary>
        public IIndexingService IndexingService { get; private set; }

        /// <summary>
        /// مُنشئ الموفر
        /// </summary>
        public TestDatabaseFixture()
        {
            InitializeAsync().GetAwaiter().GetResult();
        }

        /// <summary>
        /// تهيئة البيئة الاختبارية
        /// </summary>
        private async Task InitializeAsync()
        {
            // بناء التكوين
            var builder = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.test.json", optional: true)
                .AddJsonFile("appsettings.Development.json", optional: true)
                .AddInMemoryCollection(new[]
                {
                    new KeyValuePair<string, string>("Redis:Enabled", "true"),
                    new KeyValuePair<string, string>("Redis:Database", "1"), // قاعدة بيانات منفصلة للاختبار
                })
                .AddEnvironmentVariables();

            Configuration = builder.Build();

            // بناء حاوي الخدمات
            var services = new ServiceCollection();

            // إضافة خدمات التسجيل
            services.AddLogging(logging =>
            {
                logging.AddConsole();
                logging.AddDebug();
                logging.SetMinimumLevel(LogLevel.Debug);
            });

            // إضافة كاش الذاكرة
            services.AddMemoryCache();

            // إضافة HttpContextAccessor (مطلوب لبعض الخدمات)
            services.AddSingleton<Microsoft.AspNetCore.Http.IHttpContextAccessor, Microsoft.AspNetCore.Http.HttpContextAccessor>();

            // إضافة قاعدة البيانات (In-Memory للاختبار السريع أو PostgreSQL الحقيقية)
            var useInMemoryDb = Configuration.GetValue<bool>("Testing:UseInMemoryDatabase", false);
            if (useInMemoryDb)
            {
                services.AddDbContext<YemenBookingDbContext>(options =>
                    options.UseInMemoryDatabase($"TestDb_{Guid.NewGuid()}"));
            }
            else
            {
                services.AddDbContext<YemenBookingDbContext>(options =>
                    options.UseNpgsql(Configuration.GetConnectionString("DefaultConnection")));
            }

            // إضافة المستودعات
            RegisterRepositories(services);

            // إضافة الخدمات
            RegisterServices(services);

            // إضافة نظام Redis للفهرسة
            services.AddRedisIndexingSystem(Configuration);

            // بناء موفر الخدمات
            ServiceProvider = services.BuildServiceProvider();

            // تهيئة الخدمات
            await InitializeServicesAsync();
        }

        /// <summary>
        /// تسجيل المستودعات
        /// </summary>
        private void RegisterRepositories(IServiceCollection services)
        {
            services.AddScoped<IPropertyRepository, PropertyRepository>();
            services.AddScoped<IUnitRepository, UnitRepository>();
            services.AddScoped<IReviewRepository, ReviewRepository>();
            services.AddScoped<ICurrencyExchangeRepository, CurrencyExchangeRepository>();
            services.AddScoped<IBookingRepository, BookingRepository>();
            services.AddScoped<IUserRepository, UserRepository>();
            services.AddScoped<IAmenityRepository, AmenityRepository>();
            services.AddScoped<IPropertyTypeRepository, PropertyTypeRepository>();
            services.AddScoped<IPropertyAmenityRepository, PropertyAmenityRepository>();
            services.AddScoped<IPropertyServiceRepository, PropertyServiceRepository>();
            services.AddScoped<IPricingRuleRepository, PricingRuleRepository>();
            services.AddScoped<IUnitAvailabilityRepository, UnitAvailabilityRepository>();
            services.AddScoped<IDynamicFieldRepository, DynamicFieldRepository>();
            services.AddScoped<IPropertyDynamicFieldValueRepository, PropertyDynamicFieldValueRepository>();
        }

        /// <summary>
        /// تسجيل الخدمات
        /// </summary>
        private void RegisterServices(IServiceCollection services)
        {
            // خدمات حقيقية للاختبار الشامل
            services.AddScoped<IAvailabilityService, RealAvailabilityService>();
            services.AddScoped<IPricingService, RealPricingService>();
        }

        /// <summary>
        /// تهيئة الخدمات الأساسية
        /// </summary>
        private async Task InitializeServicesAsync()
        {
            using var scope = ServiceProvider.CreateScope();
            
            // الحصول على الخدمات
            DbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            RedisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            IndexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();

            // تطبيق الترحيلات إذا لزم الأمر
            if (!Configuration.GetValue<bool>("Testing:UseInMemoryDatabase", false))
            {
                await DbContext.Database.MigrateAsync();
            }
            else
            {
                await DbContext.Database.EnsureCreatedAsync();
            }

            // تهيئة البيانات الأساسية
            await SeedBasicDataAsync();

            // تنظيف Redis وإعادة بناء الفهرس
            await CleanupRedisAsync();
            await RebuildIndexAsync();
        }

        /// <summary>
        /// زرع البيانات الأساسية
        /// </summary>
        private async Task SeedBasicDataAsync()
        {
            using var scope = ServiceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();

            // إضافة أنواع العقارات إذا لم تكن موجودة
            if (!await dbContext.PropertyTypes.AnyAsync())
            {
                var propertyTypes = new[]
                {
                    new Core.Entities.PropertyType 
                    { 
                        Id = Guid.Parse("30000000-0000-0000-0000-000000000001"), 
                        Name = "منتجع",
                        Icon = "🏖️",
                        IsActive = true 
                    },
                    new Core.Entities.PropertyType 
                    { 
                        Id = Guid.Parse("30000000-0000-0000-0000-000000000002"), 
                        Name = "شقق مفروشة",
                        Icon = "🏢",
                        IsActive = true 
                    },
                    new Core.Entities.PropertyType 
                    { 
                        Id = Guid.Parse("30000000-0000-0000-0000-000000000003"), 
                        Name = "فندق",
                        Icon = "🏨",
                        IsActive = true 
                    },
                    new Core.Entities.PropertyType 
                    { 
                        Id = Guid.Parse("30000000-0000-0000-0000-000000000004"), 
                        Name = "فيلا",
                        Icon = "🏡",
                        IsActive = true 
                    },
                    new Core.Entities.PropertyType 
                    { 
                        Id = Guid.Parse("30000000-0000-0000-0000-000000000005"), 
                        Name = "شاليه",
                        Icon = "🏠",
                        IsActive = true 
                    },
                };

                dbContext.PropertyTypes.AddRange(propertyTypes);
                await dbContext.SaveChangesAsync();
            }

            // إضافة أنواع الوحدات إذا لم تكن موجودة
            if (!await dbContext.UnitTypes.AnyAsync())
            {
                var unitTypes = new[]
                {
                    new Core.Entities.UnitType
                    {
                        Id = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                        Name = "غرفة مفردة",
                        PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"),
                        MaxCapacity = 1,
                        IsActive = true
                    },
                    new Core.Entities.UnitType
                    {
                        Id = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                        Name = "غرفة مزدوجة",
                        PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"),
                        MaxCapacity = 2,
                        IsActive = true
                    },
                    new Core.Entities.UnitType
                    {
                        Id = Guid.Parse("20000000-0000-0000-0000-000000000003"),
                        Name = "جناح",
                        PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"),
                        MaxCapacity = 4,
                        IsActive = true
                    },
                    new Core.Entities.UnitType
                    {
                        Id = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                        Name = "شقة",
                        PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000002"),
                        MaxCapacity = 6,
                        IsActive = true
                    },
                };

                dbContext.UnitTypes.AddRange(unitTypes);
                await dbContext.SaveChangesAsync();
            }

            // إضافة المرافق إذا لم تكن موجودة
            if (!await dbContext.Amenities.AnyAsync())
            {
                var amenities = new[]
                {
                    new Core.Entities.Amenity { Id = Guid.NewGuid(), Name = "واي فاي", Icon = "📶", IsActive = true },
                    new Core.Entities.Amenity { Id = Guid.NewGuid(), Name = "مسبح", Icon = "🏊", IsActive = true },
                    new Core.Entities.Amenity { Id = Guid.NewGuid(), Name = "موقف سيارات", Icon = "🚗", IsActive = true },
                    new Core.Entities.Amenity { Id = Guid.NewGuid(), Name = "مطعم", Icon = "🍽️", IsActive = true },
                    new Core.Entities.Amenity { Id = Guid.NewGuid(), Name = "صالة رياضية", Icon = "💪", IsActive = true },
                };

                dbContext.Amenities.AddRange(amenities);
                await dbContext.SaveChangesAsync();
            }

            // إضافة المستخدم الافتراضي للاختبار
            if (!await dbContext.Users.AnyAsync())
            {
                var testUser = new Core.Entities.User
                {
                    Id = Guid.Parse("10000000-0000-0000-0000-000000000001"),
                    Email = "test@example.com",
                    PasswordHash = "hashed_password",
                    FullName = "مستخدم اختباري",
                    PhoneNumber = "770123456",
                    Role = Core.Enums.UserRole.Owner,
                    IsActive = true,
                    EmailConfirmed = true,
                    CreatedAt = DateTime.UtcNow
                };

                dbContext.Users.Add(testUser);
                await dbContext.SaveChangesAsync();
            }
        }

        /// <summary>
        /// تنظيف Redis
        /// </summary>
        private async Task CleanupRedisAsync()
        {
            var db = RedisManager.GetDatabase();
            await db.ExecuteAsync("FLUSHDB");
        }

        /// <summary>
        /// إعادة بناء الفهرس
        /// </summary>
        private async Task RebuildIndexAsync()
        {
            try
            {
                await IndexingService.RebuildIndexAsync();
                Console.WriteLine("✅ تم إعادة بناء الفهرس بنجاح");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ خطأ في إعادة بناء الفهرس: {ex.Message}");
            }
        }

        /// <summary>
        /// تنظيف الموارد
        /// </summary>
        public void Dispose()
        {
            // تنظيف قاعدة البيانات الاختبارية
            if (Configuration.GetValue<bool>("Testing:UseInMemoryDatabase", false))
            {
                DbContext?.Database.EnsureDeleted();
            }

            DbContext?.Dispose();
            
            if (ServiceProvider is IDisposable disposable)
            {
                disposable.Dispose();
            }
        }
    }

    /// <summary>
    /// خدمة الإتاحة الحقيقية للاختبار
    /// </summary>
    public class RealAvailabilityService : IAvailabilityService
    {
        private readonly YemenBookingDbContext _dbContext;
        private readonly ILogger<RealAvailabilityService> _logger;

        public RealAvailabilityService(YemenBookingDbContext dbContext, ILogger<RealAvailabilityService> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<bool> CheckAvailabilityAsync(Guid unitId, DateTime checkIn, DateTime checkOut, Guid? excludeBookingId = null)
        {
            // التحقق من التعارض مع الحجوزات
            var query = _dbContext.Bookings
                .Where(b => b.UnitId == unitId && b.CheckIn < checkOut && b.CheckOut > checkIn);
            
            if (excludeBookingId.HasValue)
                query = query.Where(b => b.Id != excludeBookingId.Value);

            return !await query.AnyAsync();
        }

        public async Task BlockForBookingAsync(Guid unitId, Guid bookingId, DateTime checkIn, DateTime checkOut)
        {
            // حفظ فترة الحجز
            await Task.CompletedTask;
        }

        public async Task ReleaseBookingAsync(Guid bookingId)
        {
            // تحرير فترة الحجز
            await Task.CompletedTask;
        }

        public async Task<Dictionary<DateTime, string>> GetMonthlyCalendarAsync(Guid unitId, int year, int month)
        {
            var calendar = new Dictionary<DateTime, string>();
            var daysInMonth = DateTime.DaysInMonth(year, month);
            
            for (int day = 1; day <= daysInMonth; day++)
            {
                var date = new DateTime(year, month, day);
                var isAvailable = await CheckAvailabilityAsync(unitId, date, date.AddDays(1));
                calendar[date] = isAvailable ? "available" : "booked";
            }
            
            return calendar;
        }

        public async Task ApplyBulkAvailabilityAsync(Guid unitId, List<Application.Features.Units.Commands.BulkOperations.AvailabilityPeriodDto> periods)
        {
            await Task.CompletedTask;
        }

        public async Task<IEnumerable<Guid>> GetAvailableUnitsInPropertyAsync(
            Guid propertyId, DateTime checkIn, DateTime checkOut, int guestCount,
            System.Threading.CancellationToken cancellationToken = default)
        {
            var units = await _dbContext.Units
                .Where(u => u.PropertyId == propertyId && 
                           u.IsAvailable && 
                           u.MaxCapacity >= guestCount)
                .Select(u => u.Id)
                .ToListAsync(cancellationToken);
            
            var availableUnits = new List<Guid>();
            foreach (var unitId in units)
            {
                if (await CheckAvailabilityAsync(unitId, checkIn, checkOut))
                    availableUnits.Add(unitId);
            }
            
            return availableUnits;
        }
    }

    /// <summary>
    /// خدمة التسعير الحقيقية للاختبار
    /// </summary>
    public class RealPricingService : IPricingService
    {
        private readonly YemenBookingDbContext _dbContext;
        private readonly ILogger<RealPricingService> _logger;

        public RealPricingService(YemenBookingDbContext dbContext, ILogger<RealPricingService> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<decimal> CalculatePriceAsync(Guid unitId, DateTime checkIn, DateTime checkOut)
        {
            var unit = await _dbContext.Units.FindAsync(unitId);
            if (unit == null) return 0;

            var nights = Math.Max(1, (checkOut - checkIn).Days);
            var basePrice = unit.BasePrice?.Amount ?? 100;
            
            return basePrice * nights;
        }

        public async Task<Dictionary<DateTime, decimal>> GetPricingCalendarAsync(Guid unitId, int year, int month)
        {
            var unit = await _dbContext.Units.FindAsync(unitId);
            var basePrice = unit?.BasePrice?.Amount ?? 100;
            
            var calendar = new Dictionary<DateTime, decimal>();
            var daysInMonth = DateTime.DaysInMonth(year, month);
            
            for (int day = 1; day <= daysInMonth; day++)
            {
                calendar[new DateTime(year, month, day)] = basePrice;
            }
            
            return calendar;
        }

        public async Task ApplySeasonalPricingAsync(Guid unitId, 
            Application.Features.Pricing.Commands.SeasonalPricing.SeasonalPricingDto seasonalPricing)
        {
            await Task.CompletedTask;
        }

        public async Task ApplyBulkPricingAsync(Guid unitId,
            List<Application.Features.Pricing.Commands.BulkOperations.PricingPeriodDto> periods)
        {
            await Task.CompletedTask;
        }

        public async Task<Application.Features.Pricing.Queries.GetPricingBreakdown.PricingBreakdownDto> 
            GetPricingBreakdownAsync(Guid unitId, DateTime checkIn, DateTime checkOut)
        {
            var totalPrice = await CalculatePriceAsync(unitId, checkIn, checkOut);
            var nights = Math.Max(1, (checkOut - checkIn).Days);
            
            return new Application.Features.Pricing.Queries.GetPricingBreakdown.PricingBreakdownDto
            {
                CheckIn = checkIn,
                CheckOut = checkOut,
                TotalNights = nights,
                Currency = "YER"
            };
        }
    }
}
