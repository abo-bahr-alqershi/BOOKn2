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
        
        private bool _initialized = false;
        private readonly SemaphoreSlim _initializationLock = new SemaphoreSlim(1, 1);

        /// <summary>
        /// مُنشئ الموفر
        /// </summary>
        public TestDatabaseFixture()
        {
            Initialize();
        }

        /// <summary>
        /// تهيئة البيئة الاختبارية بشكل متزامن
        /// </summary>
        private void Initialize()
        {
            // بناء التكوين
            var builder = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.test.json", optional: true)
                .AddJsonFile("appsettings.Development.json", optional: true)
                .AddInMemoryCollection(new[]
                {
                    new KeyValuePair<string, string>("Redis:Enabled", "true"),
                    new KeyValuePair<string, string>("Redis:Database", "0"), // RediSearch يتطلب Database 0
                    new KeyValuePair<string, string>("Monitoring:Enabled", "false"), // تعطيل مراقبة الخلفية
                    new KeyValuePair<string, string>("Redis:EnableScheduledMaintenance", "false"), // تعطيل خدمة الصيانة الدورية
                    new KeyValuePair<string, string>("Redis:ResetStatsOnStartup", "false"),
                    // ✅ إعدادات Circuit Breaker أكثر تساهلاً للاختبارات
                    new KeyValuePair<string, string>("CircuitBreaker:FailureThreshold", "100"), // زيادة عتبة الفشل
                    new KeyValuePair<string, string>("CircuitBreaker:BreakDurationSeconds", "5"), // تقليل مدة الفتح
                    new KeyValuePair<string, string>("CircuitBreaker:RetryCount", "5"), // زيادة عدد المحاولات
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
            var useInMemoryDb = Configuration.GetValue<bool>("Testing:UseInMemoryDatabase", true);
            if (useInMemoryDb)
            {
                services.AddDbContext<YemenBookingDbContext>(options =>
                {
                    options.UseInMemoryDatabase($"TestDb_{Guid.NewGuid()}")
                          .EnableSensitiveDataLogging()
                          .EnableDetailedErrors();
                    // ✅ تعطيل ChangeTracker التلقائي لتجنب الحلقات اللانهائية
                    options.UseQueryTrackingBehavior(QueryTrackingBehavior.TrackAll);
                });
            }
            else
            {
                services.AddDbContext<YemenBookingDbContext>(options =>
                {
                    options.UseNpgsql(Configuration.GetConnectionString("DefaultConnection"))
                          .EnableSensitiveDataLogging()
                          .EnableDetailedErrors();
                    // ✅ تعطيل ChangeTracker التلقائي لتجنب الحلقات اللانهائية
                    options.UseQueryTrackingBehavior(QueryTrackingBehavior.TrackAll);
                });
            }

            // إضافة المستودعات
            RegisterRepositories(services);

            // إضافة الخدمات
            RegisterServices(services);

            // إضافة نظام Redis للفهرسة
            services.AddRedisIndexingSystem(Configuration);

            // بناء موفر الخدمات
            ServiceProvider = services.BuildServiceProvider();

            // تهيئة قاعدة البيانات فقط - تجاهل الفهرسة في التهيئة
            Task.Run(async () => await InitializeDatabaseOnlyAsync()).Wait(TimeSpan.FromSeconds(10));
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
            // services.AddScoped<IDynamicFieldRepository, DynamicFieldRepository>();  // معلق - الكيان غير موجود
            // services.AddScoped<IPropertyDynamicFieldValueRepository, PropertyDynamicFieldValueRepository>(); // معلق - الكيان غير موجود
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
        /// تهيئة قاعدة البيانات فقط
        /// </summary>
        private async Task InitializeDatabaseOnlyAsync()
        {
            await _initializationLock.WaitAsync();
            try
            {
                if (_initialized) return;
                
                using var scope = ServiceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();

                // تطبيق الترحيلات إذا لزم الأمر
                var useInMemoryDb = Configuration.GetValue<bool>("Testing:UseInMemoryDatabase", true);
                if (useInMemoryDb)
                {
                    // In-Memory database لا يدعم Migrations
                    await dbContext.Database.EnsureCreatedAsync();
                }
                else
                {
                    // قاعدة بيانات حقيقية - استخدم Migrations
                    try
                    {
                        await dbContext.Database.MigrateAsync();
                    }
                    catch
                    {
                        // إذا فشلت الترحيلات، استخدم EnsureCreated كبديل
                        await dbContext.Database.EnsureCreatedAsync();
                    }
                }

                // تهيئة البيانات الأساسية فقط
                await SeedBasicDataAsync();

                // تنظيف Redis فقط - بدون إعادة بناء الفهرس لتجنب الحلقة اللانهائية
                await CleanupRedisAsync();
                // تجاهل RebuildIndexAsync لتجنب الحلقة اللانهائية
                // await RebuildIndexAsync();
                
                _initialized = true;
            }
            finally
            {
                _initializationLock.Release();
            }
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
                    new YemenBooking.Core.Entities.PropertyType 
                    { 
                        Id = Guid.Parse("30000000-0000-0000-0000-000000000001"), 
                        Name = "منتجع",
                        Icon = "🏖️",
                        Description = "منتجع سياحي فاخر",
                        IsActive = true,
                        DefaultAmenities = "[]" 
                    },
                    new YemenBooking.Core.Entities.PropertyType 
                    { 
                        Id = Guid.Parse("30000000-0000-0000-0000-000000000002"), 
                        Name = "شقق مفروشة",
                        Icon = "🏢",
                        Description = "شقق مفروشة للإيجار",
                        IsActive = true,
                        DefaultAmenities = "[]" 
                    },
                    new YemenBooking.Core.Entities.PropertyType 
                    { 
                        Id = Guid.Parse("30000000-0000-0000-0000-000000000003"), 
                        Name = "فندق",
                        Icon = "🏨",
                        Description = "فندق عصري مع خدمات متكاملة",
                        IsActive = true,
                        DefaultAmenities = "[]" 
                    },
                    new YemenBooking.Core.Entities.PropertyType 
                    { 
                        Id = Guid.Parse("30000000-0000-0000-0000-000000000004"), 
                        Name = "فيلا",
                        Description = "فيلا خاصة مستقلة",
                        Icon = "🏡",
                        IsActive = true,
                        DefaultAmenities = "[]" 
                    },
                    new YemenBooking.Core.Entities.PropertyType 
                    { 
                        Id = Guid.Parse("30000000-0000-0000-0000-000000000005"), 
                        Name = "شاليه",
                        Description = "شاليه صغير مريح",
                        Icon = "🏠",
                        IsActive = true,
                        DefaultAmenities = "[]" 
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
                    new YemenBooking.Core.Entities.UnitType
                    {
                        Id = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                        Name = "غرفة مفردة",
                        Description = "غرفة مفردة مريحة",
                        PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"),
                        MaxCapacity = 1,
                        IsActive = true,
                        DefaultPricingRules = "[]"
                    },
                    new YemenBooking.Core.Entities.UnitType
                    {
                        Id = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                        Name = "غرفة مزدوجة",
                        Description = "غرفة مزدوجة واسعة",
                        PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"),
                        MaxCapacity = 2,
                        IsActive = true,
                        DefaultPricingRules = "[]"
                    },
                    new YemenBooking.Core.Entities.UnitType
                    {
                        Id = Guid.Parse("20000000-0000-0000-0000-000000000003"),
                        Name = "جناح",
                        Description = "جناح فاخر",
                        PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"),
                        MaxCapacity = 4,
                        IsActive = true,
                        DefaultPricingRules = "[]"
                    },
                    new YemenBooking.Core.Entities.UnitType
                    {
                        Id = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                        Name = "شقة",
                        Description = "شقة كاملة مفروشة",
                        PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000002"),
                        MaxCapacity = 6,
                        IsActive = true,
                        DefaultPricingRules = "[]"
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
                    new YemenBooking.Core.Entities.Amenity { Id = Guid.NewGuid(), Name = "واي فاي", Icon = "📶", Description = "انترنت واي فاي مجاني", IsActive = true },
                    new YemenBooking.Core.Entities.Amenity { Id = Guid.NewGuid(), Name = "مسبح", Icon = "🏊", Description = "مسبح خارجي", IsActive = true },
                    new YemenBooking.Core.Entities.Amenity { Id = Guid.NewGuid(), Name = "موقف سيارات", Icon = "🚗", Description = "موقف سيارات مجاني", IsActive = true },
                    new YemenBooking.Core.Entities.Amenity { Id = Guid.NewGuid(), Name = "مطعم", Icon = "🍽️", Description = "مطعم داخلي", IsActive = true },
                    new YemenBooking.Core.Entities.Amenity { Id = Guid.NewGuid(), Name = "صالة رياضية", Icon = "💪", Description = "صالة رياضية مجهزة", IsActive = true },
                };

                dbContext.Amenities.AddRange(amenities);
                await dbContext.SaveChangesAsync();
            }

            // إضافة المستخدم الافتراضي للاختبار
            if (!await dbContext.Users.AnyAsync())
            {
                var testUser = new YemenBooking.Core.Entities.User
                {
                    Id = Guid.Parse("10000000-0000-0000-0000-000000000001"),
                    Email = "test@example.com",
                    Password = "hashed_password",
                    Name = "مستخدم اختباري",
                    Phone = "770123456",
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
            // var db = RedisManager.GetDatabase();
            // await db.ExecuteAsync("FLUSHDB");
            await Task.CompletedTask;
        }

        // تم حذف RebuildIndexAsync لتجنب الحلقة اللانهائية عند بدء الاختبارات
        // يتم الفهرسة عند الحاجة داخل الاختبارات نفسها

        /// <summary>
        /// تنظيف الموارد
        /// </summary>
        public void Dispose()
        {
            // تنظيف قاعدة البيانات الاختبارية
            if (Configuration.GetValue<bool>("Testing:UseInMemoryDatabase", false))
            {
                using var scope = ServiceProvider?.CreateScope();
                var dbContext = scope?.ServiceProvider.GetService<YemenBookingDbContext>();
                dbContext?.Database.EnsureDeleted();
            }
            
            _initializationLock?.Dispose();
            
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
                .AsNoTracking()  // ✅ عدم التتبع لتحسين الأداء
                .Where(u => u.PropertyId == propertyId && 
                           u.IsAvailable && 
                           u.MaxCapacity >= guestCount)
                .Select(u => u.Id)
                .ToListAsync(cancellationToken);
            
            // ✅ معالجة متوازية بدلاً من حلقة متسلسلة
            var availabilityTasks = units.Select(async unitId => 
                new { UnitId = unitId, IsAvailable = await CheckAvailabilityAsync(unitId, checkIn, checkOut) }
            );
            
            var results = await Task.WhenAll(availabilityTasks);
            return results.Where(r => r.IsAvailable).Select(r => r.UnitId);
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
            
            var days = new List<YemenBooking.Application.Features.Pricing.Queries.GetPricingBreakdown.DayPriceDto>();
            var dailyPrice = totalPrice / nights;
            
            for (var date = checkIn; date < checkOut; date = date.AddDays(1))
            {
                days.Add(new YemenBooking.Application.Features.Pricing.Queries.GetPricingBreakdown.DayPriceDto
                {
                    Date = date,
                    Price = dailyPrice,
                    PriceType = "Standard",
                    Description = "السعر الأساسي"
                });
            }
            
            return new YemenBooking.Application.Features.Pricing.Queries.GetPricingBreakdown.PricingBreakdownDto
            {
                CheckIn = checkIn,
                CheckOut = checkOut,
                TotalNights = nights,
                Currency = "YER",
                Days = days,
                SubTotal = totalPrice,
                Total = totalPrice
            };
        }
    }
}
