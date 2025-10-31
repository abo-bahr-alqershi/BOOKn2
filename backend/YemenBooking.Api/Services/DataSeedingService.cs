using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Seeds;
using YemenBooking.Core.Entities;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Infrastructure.Seeds;
using Microsoft.Extensions.Logging;

namespace YemenBooking.Api.Services
{
    public class DataSeedingService
    {
        private readonly global::YemenBooking.Infrastructure.Data.Context.YemenBookingDbContext _context;
        private readonly ILogger<DataSeedingService> _logger;

        public DataSeedingService(global::YemenBooking.Infrastructure.Data.Context.YemenBookingDbContext context, ILogger<DataSeedingService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task SeedAsync()
        {
            // Initialize currencies
            if (!await _context.Currencies.AnyAsync())
            {
                _context.Currencies.AddRange(
                    new Currency { Code = "YER", ArabicCode = "ريال", Name = "Yemeni Rial", ArabicName = "الريال اليمني", IsDefault = true },
                    new Currency { Code = "USD", ArabicCode = "دولار", Name = "US Dollar", ArabicName = "الدولار الأمريكي", IsDefault = false, ExchangeRate = 0.004m, LastUpdated = DateTime.UtcNow }
                );
                await _context.SaveChangesAsync();
            }

            // Initialize cities
            if (!await _context.Cities.AnyAsync())
            {
                _context.Cities.AddRange(
                    new City { Name = "صنعاء", Country = "اليمن", ImagesJson = "[]" },
                    new City { Name = "عدن", Country = "اليمن", ImagesJson = "[]" },
                    new City { Name = "تعز", Country = "اليمن", ImagesJson = "[]" }
                );
                await _context.SaveChangesAsync();
            }

            // Roles (Admin, Owner, Staff, Client)
            if (!await _context.Roles.AnyAsync())
            {
                _context.Roles.AddRange(
                    new Role { Id = Guid.Parse("11111111-1111-1111-1111-111111111111"), Name = "Admin", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow, IsActive = true },
                    new Role { Id = Guid.Parse("22222222-2222-2222-2222-222222222222"), Name = "Owner", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow, IsActive = true },
                    new Role { Id = Guid.Parse("33333333-3333-3333-3333-333333333333"), Name = "Staff", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow, IsActive = true },
                    new Role { Id = Guid.Parse("44444444-4444-4444-4444-444444444444"), Name = "Client", CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow, IsActive = true }
                );
                await _context.SaveChangesAsync();
            }

            // Users
            if (!await _context.Users.AnyAsync())
            {
                _context.Users.AddRange(new UserSeeder().SeedData());
                await _context.SaveChangesAsync();
            }

            // Migrate Favorites from Users.FavoritesJson to Favorites table (one-time)
            if (!await _context.Favorites.AnyAsync())
            {
                try
                {
                    var allUsers = await _context.Users.AsNoTracking().ToListAsync();
                    var propsList = await _context.Properties.AsNoTracking().Select(p => p.Id).ToListAsync();
                    var props = propsList.ToHashSet();
                    var toAdd = new List<Favorite>();
                    foreach (var u in allUsers)
                    {
                        List<Guid>? favIds = null;
                        try { favIds = System.Text.Json.JsonSerializer.Deserialize<List<Guid>>(u.FavoritesJson ?? "[]"); }
                        catch { favIds = new List<Guid>(); }
                        if (favIds == null || favIds.Count == 0) continue;
                        foreach (var pid in favIds.Distinct())
                        {
                            if (!props.Contains(pid)) continue;
                            toAdd.Add(new Favorite
                            {
                                Id = Guid.NewGuid(),
                                UserId = u.Id,
                                PropertyId = pid,
                                DateAdded = DateTime.UtcNow,
                                CreatedAt = DateTime.UtcNow,
                                UpdatedAt = DateTime.UtcNow,
                                IsActive = true,
                                IsDeleted = false
                            });
                        }
                    }
                    if (toAdd.Count > 0)
                    {
                        await _context.Favorites.AddRangeAsync(toAdd);
                        await _context.SaveChangesAsync();
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Favorites migration skipped due to error");
                }
            }

            // UserRoles: Link admin user to Admin role
            if (!await _context.UserRoles.AnyAsync())
            {
                var adminUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == "admin@example.com");
                var ownerUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == "owner@example.com");
                var adminRole = await _context.Roles.FirstOrDefaultAsync(r => r.Name == "Admin");
                var ownerRole = await _context.Roles.FirstOrDefaultAsync(r => r.Name == "Owner");

                var userRoles = new List<UserRole>();
                if (adminUser != null && adminRole != null)
                {
                    userRoles.Add(new UserRole
                    {
                        Id = Guid.Parse("CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"),
                        UserId = adminUser.Id,
                        RoleId = adminRole.Id,
                        AssignedAt = DateTime.UtcNow,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true
                    });
                }
                if (ownerUser != null && ownerRole != null)
                {
                    userRoles.Add(new UserRole
                    {
                        Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"),
                        UserId = ownerUser.Id,
                        RoleId = ownerRole.Id,
                        AssignedAt = DateTime.UtcNow,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true
                    });
                }
                if (userRoles.Any())
                {
                    _context.UserRoles.AddRange(userRoles);
                    await _context.SaveChangesAsync();
                }
            }

            // Property types
            if (!await _context.PropertyTypes.AnyAsync())
            {
                _context.PropertyTypes.AddRange(new PropertyTypeSeeder().SeedData());
                await _context.SaveChangesAsync();
            }

            // Unit types: create one default unit type per property type
            if (!await _context.UnitTypes.AnyAsync())
            {
                var propertyTypesForUnitTypes = await _context.PropertyTypes.AsNoTracking().ToListAsync();
                var unitTypes = propertyTypesForUnitTypes.Select(pt => new UnitType
                {
                    Id = Guid.NewGuid(),
                    PropertyTypeId = pt.Id,
                    Name = pt.Name + " Default",
                    Description = pt.Name + " default unit type",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 4,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true
                }).ToList();
                _context.UnitTypes.AddRange(unitTypes);
                await _context.SaveChangesAsync();
            }

            // Properties: assign valid TypeId, OwnerId and City (must match seeded City.Name values)
            // تحديث: إضافة العقارات الجديدة فقط (التي لا توجد بالفعل)
            var existingPropertyIds = await _context.Properties.Select(p => p.Id).ToListAsync();
            var propertyTypes = await _context.PropertyTypes.AsNoTracking().ToListAsync();
            var cities = await _context.Cities.AsNoTracking().Select(c => c.Name).ToListAsync();
            var seededProperties = new PropertySeeder().SeedData().ToList();
            var rnd = new Random();
            var ownerId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB");

            // تصفية العقارات الجديدة فقط
            var newProperties = seededProperties.Where(p => !existingPropertyIds.Contains(p.Id)).ToList();

            if (newProperties.Any())
            {
                foreach (var prop in newProperties)
                {
                    // الحفاظ على العملة المحددة في السيدر
                    if (string.IsNullOrEmpty(prop.Currency))
                    {
                        prop.Currency = "YER";
                    }
                    prop.TypeId = propertyTypes[rnd.Next(propertyTypes.Count)].Id; // valid FK
                    prop.OwnerId = ownerId; // existing seeded user
                    if (cities.Count > 0)
                    {
                        // Override faker random city with a valid seeded city to satisfy FK constraint
                        prop.City = cities[rnd.Next(cities.Count)];
                    }
                }
                _context.Properties.AddRange(newProperties);
                await _context.SaveChangesAsync();
            }

            // Property Policies: seed policies for properties
            if (!await _context.PropertyPolicies.AnyAsync())
            {
                var propertyPolicySeeder = new PropertyPolicySeeder();
                var policies = propertyPolicySeeder.SeedData().ToList();
                if (policies.Any())
                {
                    _context.PropertyPolicies.AddRange(policies);
                    await _context.SaveChangesAsync();
                    _logger.LogInformation($"✅ تم بذر {policies.Count} سياسة عقار");
                }
            }

            // Property Services: seed services for properties
            if (!await _context.PropertyServices.AnyAsync())
            {
                var propertiesForServices = await _context.Properties.AsNoTracking().ToListAsync();
                if (propertiesForServices.Any())
                {
                    var propertyServiceSeeder = new PropertyServiceSeeder(propertiesForServices);
                    var services = propertyServiceSeeder.SeedData().ToList();
                    if (services.Any())
                    {
                        _context.PropertyServices.AddRange(services);
                        await _context.SaveChangesAsync();
                    }
                }
            }

            // Units: assign valid PropertyId and UnitTypeId
            // تحديث: إضافة الوحدات الجديدة دائماً (مع توليد معرفات جديدة لتجنب التكرار)
            var properties = await _context.Properties.AsNoTracking().ToListAsync();
            var units = await _context.Units.AsNoTracking().ToListAsync();
            var unitTypesList = await _context.UnitTypes.AsNoTracking().ToListAsync();
            var existingUnitCount = await _context.Units.CountAsync();

            // إضافة وحدات جديدة فقط إذا كان العدد أقل من 80
            if (existingUnitCount < 80 && properties.Any() && unitTypesList.Any())
            {
                var seededUnits = new UnitSeeder().SeedData().ToList();
                rnd = new Random();

                foreach (var u in seededUnits)
                {
                    u.Id = Guid.NewGuid(); // توليد معرف جديد لتجنب التكرار
                    u.PropertyId = properties[rnd.Next(properties.Count)].Id;
                    u.UnitTypeId = unitTypesList[rnd.Next(unitTypesList.Count)].Id;
                    // Force unit base currency to property's currency if available, otherwise keep the seeded currency
                    var prop = properties.FirstOrDefault(p => p.Id == u.PropertyId);
                    if (prop != null && !string.IsNullOrEmpty(prop.Currency))
                    {
                        u.BasePrice = new Money(u.BasePrice.Amount, prop.Currency);
                    }
                }
                _context.Units.AddRange(seededUnits);
                await _context.SaveChangesAsync();
            }

            // Unit Availability: Create availability records for units
            if (!await _context.Set<UnitAvailability>().AnyAsync())
            {
                units = await _context.Units.AsNoTracking().ToListAsync();
                var bookings = await _context.Bookings.AsNoTracking()
                    .Where(b => b.Status != YemenBooking.Core.Enums.BookingStatus.Cancelled)
                    .ToListAsync();
                var availabilitySeeder = new UnitAvailabilitySeeder();
                var availabilitiesToAdd = new List<UnitAvailability>();

                // Create availability data for each unit
                foreach (var unit in units.Take(30)) // Create for first 30 units
                {
                    var today = DateTime.UtcNow.Date;

                    // Get existing bookings for this unit
                    var unitBookings = bookings.Where(b => b.UnitId == unit.Id).ToList();

                    // Add availability records that respect existing bookings
                    foreach (var booking in unitBookings)
                    {
                        // Create a "Booked" record for each existing booking
                        availabilitiesToAdd.Add(new UnitAvailability
                        {
                            Id = Guid.NewGuid(),
                            UnitId = unit.Id,
                            StartDate = booking.CheckIn,
                            EndDate = booking.CheckOut,
                            Status = YemenBooking.Core.Enums.AvailabilityStatus.Booked,
                            Reason = "حجز عميل",
                            Notes = $"حجز رقم {booking.Id}",
                            BookingId = booking.Id,
                            CreatedAt = booking.CreatedAt,
                            UpdatedAt = DateTime.UtcNow,
                            IsActive = true,
                            IsDeleted = false
                        });
                    }

                    // Add some maintenance periods (avoid conflicts with bookings)
                    var maintenanceDate = today.AddDays(60);
                    bool hasConflict = unitBookings.Any(b =>
                        b.CheckIn <= maintenanceDate.AddDays(3) && b.CheckOut >= maintenanceDate);

                    if (!hasConflict)
                    {
                        availabilitiesToAdd.Add(new UnitAvailability
                        {
                            Id = Guid.NewGuid(),
                            UnitId = unit.Id,
                            StartDate = maintenanceDate,
                            EndDate = maintenanceDate.AddDays(3),
                            Status = YemenBooking.Core.Enums.AvailabilityStatus.Maintenance,
                            Reason = "صيانة دورية",
                            Notes = "صيانة شهرية مجدولة",
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow,
                            IsActive = true,
                            IsDeleted = false
                        });
                    }

                    // Add some blocked periods for special events
                    var blockedDate = today.AddDays(120);
                    hasConflict = unitBookings.Any(b =>
                        b.CheckIn <= blockedDate.AddDays(5) && b.CheckOut >= blockedDate);

                    if (!hasConflict && rnd.Next(100) < 30) // 30% chance
                    {
                        availabilitiesToAdd.Add(new UnitAvailability
                        {
                            Id = Guid.NewGuid(),
                            UnitId = unit.Id,
                            StartDate = blockedDate,
                            EndDate = blockedDate.AddDays(5),
                            Status = YemenBooking.Core.Enums.AvailabilityStatus.Blocked,
                            Reason = "حدث خاص",
                            Notes = "محجوز لحدث خاص",
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow,
                            IsActive = true,
                            IsDeleted = false
                        });
                    }
                }

                if (availabilitiesToAdd.Any())
                {
                    _context.Set<UnitAvailability>().AddRange(availabilitiesToAdd);
                    await _context.SaveChangesAsync();
                }
            }

            // Pricing Rules: Create pricing rules for units matching their base prices
            if (!await _context.Set<PricingRule>().AnyAsync())
            {
                units = await _context.Units.Include(u => u.UnitType).AsNoTracking().ToListAsync();
                var pricingSeeder = new PricingRuleSeeder();
                var pricingRulesToAdd = new List<PricingRule>();
                var today = DateTime.UtcNow.Date;

                // Create pricing rules for each unit
                foreach (var unit in units.Take(30)) // Create for first 30 units
                {
                    var basePrice = unit.BasePrice?.Amount ?? 150000m;
                    var currency = unit.BasePrice?.Currency ?? "YER";

                    // Base pricing rule
                    pricingRulesToAdd.Add(new PricingRule
                    {
                        Id = Guid.NewGuid(),
                        UnitId = unit.Id,
                        PriceType = YemenBooking.Core.Enums.PriceType.Base,
                        StartDate = today.AddMonths(-1), // Start from past to cover current bookings
                        EndDate = today.AddYears(2),
                        PriceAmount = basePrice,
                        PricingTier = YemenBooking.Core.Enums.PricingTier.Standard,
                        Currency = currency,
                        Description = $"السعر الأساسي لـ {unit.Name}",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        IsDeleted = false
                    });

                    // Weekend pricing (20% increase)
                    pricingRulesToAdd.Add(new PricingRule
                    {
                        Id = Guid.NewGuid(),
                        UnitId = unit.Id,
                        PriceType = YemenBooking.Core.Enums.PriceType.Weekend,
                        StartDate = today.AddMonths(-1),
                        EndDate = today.AddYears(2),
                        PriceAmount = basePrice * 1.2m,
                        PricingTier = YemenBooking.Core.Enums.PricingTier.Standard,
                        PercentageChange = 20,
                        Currency = currency,
                        Description = "سعر نهاية الأسبوع (الجمعة والسبت)",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        IsDeleted = false
                    });

                    // Seasonal pricing for summer (30% increase)
                    var currentYear = today.Year;
                    pricingRulesToAdd.Add(new PricingRule
                    {
                        Id = Guid.NewGuid(),
                        UnitId = unit.Id,
                        PriceType = YemenBooking.Core.Enums.PriceType.Seasonal,
                        StartDate = new DateTime(currentYear, 6, 1, 0, 0, 0, DateTimeKind.Utc),
                        EndDate = new DateTime(currentYear, 8, 31, 0, 0, 0, DateTimeKind.Utc),
                        PriceAmount = basePrice * 1.3m,
                        PricingTier = YemenBooking.Core.Enums.PricingTier.Premium,
                        PercentageChange = 30,
                        Currency = currency,
                        Description = "سعر موسم الصيف",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        IsDeleted = false
                    });

                    // Holiday pricing (50% increase) 
                    pricingRulesToAdd.Add(new PricingRule
                    {
                        Id = Guid.NewGuid(),
                        UnitId = unit.Id,
                        PriceType = YemenBooking.Core.Enums.PriceType.Holiday,
                        StartDate = today.AddDays(30),
                        EndDate = today.AddDays(40),
                        PriceAmount = basePrice * 1.5m,
                        PricingTier = YemenBooking.Core.Enums.PricingTier.Luxury,
                        PercentageChange = 50,
                        MaxPrice = basePrice * 2m,
                        Currency = currency,
                        Description = "سعر العطلات والأعياد",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        IsDeleted = false
                    });

                    // Early bird discount (15% off) for 25% of units
                    if (rnd.Next(100) < 25)
                    {
                        pricingRulesToAdd.Add(new PricingRule
                        {
                            Id = Guid.NewGuid(),
                            UnitId = unit.Id,
                            PriceType = YemenBooking.Core.Enums.PriceType.EarlyBird,
                            StartDate = today.AddDays(60),
                            EndDate = today.AddDays(180),
                            PriceAmount = basePrice * 0.85m,
                            PricingTier = YemenBooking.Core.Enums.PricingTier.Economy,
                            PercentageChange = -15,
                            MinPrice = basePrice * 0.7m,
                            Currency = currency,
                            Description = "خصم الحجز المبكر (15% خصم)",
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow,
                            IsActive = true,
                            IsDeleted = false
                        });
                    }
                }

                if (pricingRulesToAdd.Any())
                {
                    _context.Set<PricingRule>().AddRange(pricingRulesToAdd);
                    await _context.SaveChangesAsync();
                }
            }

            // Property images: assign valid PropertyId and optional UnitId
            if (!await _context.PropertyImages.AnyAsync())
            {
                properties = await _context.Properties.AsNoTracking().ToListAsync();
                units = await _context.Units.AsNoTracking().ToListAsync();
                var seededImages = new PropertyImageSeeder().SeedData().ToList();
                rnd = new Random();
                foreach (var img in seededImages)
                {
                    img.PropertyId = properties[rnd.Next(properties.Count)].Id;
                    if (units.Any()) img.UnitId = units[rnd.Next(units.Count)].Id;
                }
                _context.PropertyImages.AddRange(seededImages);
                await _context.SaveChangesAsync();
            }

            // Amenities
            if (!await _context.Amenities.AnyAsync())
            {
                _context.Amenities.AddRange(new AmenitySeeder().SeedData());
                await _context.SaveChangesAsync();
            }

            // Bookings: assign valid UserId and UnitId
            // تحديث: إضافة الحجوزات الجديدة دائماً (مع توليد معرفات جديدة)
            var users = await _context.Users.AsNoTracking().ToListAsync();
            units = await _context.Units.AsNoTracking().ToListAsync();
            var existingBookingCount = await _context.Bookings.CountAsync();

            // إضافة حجوزات جديدة فقط إذا كان العدد أقل من 100
            if (existingBookingCount < 100 && users.Any() && units.Any())
            {
                var seededBookings = new BookingSeeder().SeedData().ToList();
                rnd = new Random();

                foreach (var b in seededBookings)
                {
                    b.Id = Guid.NewGuid(); // توليد معرف جديد لتجنب التكرار
                    b.UserId = users[rnd.Next(users.Count)].Id;
                    b.UnitId = units[rnd.Next(units.Count)].Id;
                }
                _context.Bookings.AddRange(seededBookings);
                await _context.SaveChangesAsync();
            }

            await SeedAvailabilityAndPricingAsync();

            // Booking Services: link some property services to existing bookings
            if (!await _context.BookingServices.AnyAsync())
            {
                var bookingsForServices = await _context.Bookings.AsNoTracking().ToListAsync();
                var servicesForBookings = await _context.PropertyServices.AsNoTracking().ToListAsync();
                var unitsForBookings = await _context.Units.AsNoTracking().ToListAsync();
                if (bookingsForServices.Any() && servicesForBookings.Any() && unitsForBookings.Any())
                {
                    var bookingServiceSeeder = new BookingServiceSeeder(bookingsForServices, servicesForBookings, unitsForBookings);
                    var bookingServicesToAdd = bookingServiceSeeder.SeedData().ToList();
                    if (bookingServicesToAdd.Any())
                    {
                        _context.BookingServices.AddRange(bookingServicesToAdd);
                        await _context.SaveChangesAsync();
                    }
                }
            }

            // Verification: ensure bookings link to services from the same property's services
            try
            {
                var bookingsInfo = await _context.Bookings.AsNoTracking()
                    .Select(b => new { b.Id, b.Status })
                    .ToListAsync();
                var nonCancelledIds = bookingsInfo
                    .Where(b => b.Status != YemenBooking.Core.Enums.BookingStatus.Cancelled)
                    .Select(b => b.Id)
                    .ToHashSet();

                var joinList = await (
                    from bs in _context.BookingServices.AsNoTracking()
                    join ps in _context.PropertyServices.AsNoTracking() on bs.ServiceId equals ps.Id
                    join b in _context.Bookings.AsNoTracking() on bs.BookingId equals b.Id
                    join u in _context.Units.AsNoTracking() on b.UnitId equals u.Id
                    select new { b.Id, BookingPropId = u.PropertyId, ServicePropId = ps.PropertyId }
                ).ToListAsync();

                var servicesByBooking = joinList
                    .GroupBy(x => x.Id)
                    .ToDictionary(g => g.Key, g => g.ToList());

                int totalNonCancelled = nonCancelledIds.Count;
                int matchedNonCancelled = servicesByBooking
                    .Where(kvp => nonCancelledIds.Contains(kvp.Key))
                    .Count(kvp => kvp.Value.Any(v => v.BookingPropId == v.ServicePropId));
                int mismatches = joinList.Count(x => x.BookingPropId != x.ServicePropId);
                int totalBs = await _context.BookingServices.CountAsync();

                double percent = totalNonCancelled == 0 ? 0 : (matchedNonCancelled * 100.0) / totalNonCancelled;
                _logger.LogInformation(
                    "BookingServices verification => Non-cancelled bookings: {TotalNonCancelled}, with >=1 matching service: {Matched} ({Percent:F1}%), Total BookingServices: {BSCount}, Cross-property links (should be 0): {Mismatches}",
                    totalNonCancelled,
                    matchedNonCancelled,
                    percent,
                    totalBs,
                    mismatches
                );
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "BookingServices verification failed");
            }

            // Reviews: seed one Arabic review per existing booking
            if (!await _context.Reviews.AnyAsync())
            {
                var bookingsList = await _context.Bookings
                    .Include(b => b.Unit)
                    .AsNoTracking()
                    .ToListAsync();
                // Arabic comments pool
                var comments = new[]
                {
                    "الخدمة ممتازة والنظافة عالية.",
                    "الإقامة كانت رائعة، أنصح به بشدة.",
                    "الموقع جيد لكن السعر مرتفع قليلاً.",
                    "المنظر كان خلاباً والخدمة رائعة.",
                    "التجربة كانت مرضية لكن كان هناك بعض الضوضاء.",
                    "الوحدة كانت نظيفة ومريحة للغاية.",
                    "التواصل مع المالك كان سلساً وودوداً.",
                    "التقييم العام جيد جداً، سأعود مرة أخرى."
                };
                rnd = new Random();
                var reviewsToAdd = bookingsList.Select(b => new Review
                {
                    Id = Guid.NewGuid(),
                    PropertyId = b.Unit.PropertyId,
                    BookingId = b.Id,
                    Cleanliness = rnd.Next(1, 6),
                    Service = rnd.Next(1, 6),
                    Location = rnd.Next(1, 6),
                    Value = rnd.Next(1, 6),
                    Comment = comments[rnd.Next(comments.Length)],
                    CreatedAt = DateTime.UtcNow.AddDays(-rnd.Next(0, 30)),
                    ResponseText = null,
                    ResponseDate = null,
                    IsPendingApproval = true
                }).ToList();
                _context.Reviews.AddRange(reviewsToAdd);
                await _context.SaveChangesAsync();
            }

            // Reports: seed diverse reports in Arabic with relationships
            if (!await _context.Reports.AnyAsync())
            {
                users = await _context.Users.AsNoTracking().ToListAsync();
                properties = await _context.Properties.AsNoTracking().ToListAsync();
                rnd = new Random();
                var reasons = new[]
                {
                    "محتوى مسيء",
                    "سلوك غير لائق",
                    "مشكلة في الحجز",
                    "خطأ تقني",
                    "طلب إلغاء غير منطقي",
                    "معلومات خاطئة",
                    "انتهاك للقواعد",
                    "شكاوى أخرى"
                };
                var descriptions = new[]
                {
                    "تم العثور على محتوى مسيء في وصف الوحدة.",
                    "سلوك المستخدم كان غير لائق خلال فترة الإقامة.",
                    "واجهت مشكلة في عملية الحجز لم يتم حلها.",
                    "تعذر الوصول إلى تفاصيل الحجز بسبب خطأ تقني.",
                    "طلب الإلغاء لم يتم قبوله من قبل الإدارة.",
                    "المعلومات المعروضة لا تتطابق مع الواقع.",
                    "تم انتهاك قواعد السكن بوجود ضيوف إضافيين.",
                    "بلاغ عام حول مشاكل أخرى تتعلق بالخدمة."
                };
                var statuses = new[] { "Open", "InReview", "Resolved", "Dismissed" };
                var reportsToAdd = users.SelectMany(u =>
                {
                    int count = rnd.Next(1, 7);
                    return Enumerable.Range(1, count).Select(_ => new Report
                    {
                        Id = Guid.NewGuid(),
                        ReporterUserId = u.Id,
                        ReportedUserId = rnd.Next(2) == 0 ? users[rnd.Next(users.Count)].Id : (Guid?)null,
                        ReportedPropertyId = properties.Any() && rnd.Next(2) == 1
                            ? properties[rnd.Next(properties.Count)].Id : (Guid?)null,
                        Reason = reasons[rnd.Next(reasons.Length)],
                        Description = descriptions[rnd.Next(descriptions.Length)],
                        Status = statuses[rnd.Next(statuses.Length)],
                        CreatedAt = DateTime.UtcNow.AddDays(-rnd.Next(0, 30)),
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        ActionNote = string.Empty,
                        AdminId = null
                    });
                }).ToList();
                _context.Reports.AddRange(reportsToAdd);
                await _context.SaveChangesAsync();
            }

            // Payment Methods are now handled by PaymentMethodEnum - no seeding required

            // Payments: seed professional diverse payments per booking
            // تحديث: إضافة المدفوعات للحجوزات التي ليس لها مدفوعات
            var bookingsListForPayments = await _context.Bookings
                .AsNoTracking()
                .ToListAsync();

            if (bookingsListForPayments.Any())
            {
                // الحصول على معرفات الحجوزات التي لها مدفوعات بالفعل
                var bookingsWithPayments = await _context.Payments
                    .Select(p => p.BookingId)
                    .Distinct()
                    .ToListAsync();

                // الحصول على جميع TransactionId الموجودة لتجنب التكرار
                var existingTransactionIds = (await _context.Payments
                    .Select(p => p.TransactionId)
                    .ToListAsync()).ToHashSet();

                // تصفية الحجوزات التي ليس لها مدفوعات
                var bookingsNeedingPayments = bookingsListForPayments
                    .Where(b => !bookingsWithPayments.Contains(b.Id))
                    .ToList();

                if (bookingsNeedingPayments.Any())
                {
                    var paymentSeeder = new PaymentSeeder(bookingsNeedingPayments, Guid.Parse("AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"));
                    var seededPayments = paymentSeeder.SeedData().ToList();

                    // ✅ توليد معرفات فريدة لجميع المدفوعات مع تجنب التكرار
                    var rndForPayments = new Random();
                    foreach (var payment in seededPayments)
                    {
                        payment.Id = Guid.NewGuid();

                        // ✅ إنشاء TransactionId فريد ومضمون عدم تكراره
                        string newTransactionId;
                        int attempts = 0;
                        do
                        {
                            var timestamp = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff"); // إضافة ميلي ثانية
                            var uniqueId = Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper();
                            var randomSuffix = rndForPayments.Next(10000, 99999);

                            // استخراج البادئة من TransactionId الأصلي
                            var originalPrefix = payment.TransactionId.Split('-')[0];
                            newTransactionId = $"{originalPrefix}-{timestamp}-{uniqueId}-{randomSuffix}";
                            attempts++;

                            if (attempts > 10) // حماية من حلقة لا نهائية
                            {
                                newTransactionId = $"TXN-{Guid.NewGuid():N}";
                                break;
                            }
                        } while (existingTransactionIds.Contains(newTransactionId));

                        payment.TransactionId = newTransactionId;
                        existingTransactionIds.Add(newTransactionId);

                        // ✅ تحديث GatewayTransactionId أيضاً لضمان الفرادة
                        payment.GatewayTransactionId = $"GW-{payment.Id:N}";
                    }

                    _context.Payments.AddRange(seededPayments);
                    await _context.SaveChangesAsync();
                    _logger.LogInformation($"✅ تم إضافة {seededPayments.Count} دفعة جديدة للحجوزات");
                }
            }

            // Seed Arabic notifications for admin@example.com
            if (!await _context.Notifications.AnyAsync())
            {
                var admin = await _context.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == "admin@example.com");
                if (admin != null)
                {
                    var now = DateTime.UtcNow;
                    var notifications = new List<Notification>
                    {
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "BOOKING_CREATED",
                            Title = "حجز جديد",
                            Message = "تم إنشاء حجز جديد برقم HBK-2025-001",
                            TitleAr = "حجز جديد",
                            MessageAr = "تم إنشاء حجز جديد برقم HBK-2025-001",
                            Priority = "MEDIUM",
                            Data = "{\"bookingNumber\":\"HBK-2025-001\"}",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddMinutes(-30),
                            UpdatedAt = now.AddMinutes(-30)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "BOOKING_CANCELLED",
                            Title = "إلغاء حجز",
                            Message = "تم إلغاء الحجز رقم HBK-2025-002",
                            TitleAr = "إلغاء حجز",
                            MessageAr = "تم إلغاء الحجز رقم HBK-2025-002",
                            Priority = "LOW",
                            Data = "{\"bookingNumber\":\"HBK-2025-002\"}",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddHours(-2),
                            UpdatedAt = now.AddHours(-2)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "PAYMENT_UPDATE",
                            Title = "تحديث الدفع",
                            Message = "تم اعتماد دفعة بمبلغ 120,000 ريال يمني",
                            TitleAr = "تحديث الدفع",
                            MessageAr = "تم اعتماد دفعة بمبلغ 120,000 ريال يمني",
                            Priority = "HIGH",
                            Data = "{\"amount\":\"120000 YER\",\"status\":\"Approved\"}",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddMinutes(-10),
                            UpdatedAt = now.AddMinutes(-10)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "PAYMENT_FAILED",
                            Title = "فشل عملية الدفع",
                            Message = "تعذر معالجة الدفعة الأخيرة، يرجى المحاولة لاحقاً",
                            TitleAr = "فشل عملية الدفع",
                            MessageAr = "تعذر معالجة الدفعة الأخيرة، يرجى المحاولة لاحقاً",
                            Priority = "URGENT",
                            RequiresAction = true,
                            Data = "{\"reason\":\"CardDeclined\"}",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddMinutes(-5),
                            UpdatedAt = now.AddMinutes(-5)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "PROMOTION_OFFER",
                            Title = "عرض ترويجي جديد",
                            Message = "خصم 20% على الحجوزات لمدة محدودة",
                            TitleAr = "عرض ترويجي جديد",
                            MessageAr = "خصم 20% على الحجوزات لمدة محدودة",
                            Priority = "LOW",
                            Data = "{\"discount\":20,\"currency\":\"YER\"}",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddDays(-1),
                            UpdatedAt = now.AddDays(-1)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "SYSTEM_UPDATE",
                            Title = "تحديث النظام",
                            Message = "تم تحديث النظام لتحسين الأداء والاستقرار",
                            TitleAr = "تحديث النظام",
                            MessageAr = "تم تحديث النظام لتحسين الأداء والاستقرار",
                            Priority = "MEDIUM",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddDays(-2),
                            UpdatedAt = now.AddDays(-2)
                        },
                        new Notification
                        {
                            Id = Guid.NewGuid(),
                            RecipientId = admin.Id,
                            Type = "SECURITY_ALERT",
                            Title = "تنبيه أمني",
                            Message = "تم اكتشاف محاولة تسجيل دخول غير معتادة وتم حظرها",
                            TitleAr = "تنبيه أمني",
                            MessageAr = "تم اكتشاف محاولة تسجيل دخول غير معتادة وتم حظرها",
                            Priority = "HIGH",
                            Channels = new List<string> { "IN_APP" },
                            CreatedAt = now.AddHours(-6),
                            UpdatedAt = now.AddHours(-6)
                        }
                    };

                    _context.Notifications.AddRange(notifications);
                    await _context.SaveChangesAsync();
                }
            }

            // Chart of Accounts (دليل الحسابات المحاسبية)
            // بذر الحسابات الأساسية للنظام المحاسبي
            try
            {
                await ChartOfAccountSeeder.SeedAsync(_context, _logger);
                _logger.LogInformation("✅ تم بذر دليل الحسابات المحاسبية بنجاح");

                // ✅ مهم جداً: إنشاء الحسابات الشخصية للمستخدمين
                // يجب أن يتم هذا بعد إنشاء دليل الحسابات وقبل العمليات المالية
                await UserAccountsSeeder.SeedAsync(_context, _logger);
                _logger.LogInformation("✅ تم إنشاء الحسابات المحاسبية الشخصية بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ فشل في بذر الحسابات المحاسبية");
            }

            // Financial Transactions (العمليات المالية)
            // ✅ تحسين: بذر العمليات المالية لجميع الحجوزات والدفعات
            if (!await _context.FinancialTransactions.AnyAsync())
            {
                try
                {
                    _logger.LogInformation("🔄 بدء بذر العمليات المالية الشاملة...");

                    // جلب جميع البيانات المطلوبة - لا نحدد بـ 50 فقط
                    var bookings = await _context.Bookings
                        .Include(b => b.Unit)
                        .OrderByDescending(b => b.CreatedAt)
                        .ToListAsync(); // ✅ جلب جميع الحجوزات

                    var payments = await _context.Payments
                        .OrderByDescending(p => p.PaymentDate)
                        .ToListAsync();

                    var allUsers = await _context.Users.ToListAsync();
                    var allProperties = await _context.Properties.ToListAsync();
                    var allUnits = await _context.Units.ToListAsync();

                    // ✅ جلب الحسابات مع تضمين الحسابات الشخصية الجديدة
                    var accounts = await _context.ChartOfAccounts
                        .Include(a => a.User)
                        .Include(a => a.Property)
                        .ToListAsync();

                    _logger.LogInformation($"📊 البيانات المتاحة: {bookings.Count} حجز، {payments.Count} دفعة، {accounts.Count} حساب محاسبي");

                    if (bookings.Any() && accounts.Any())
                    {
                        // إنشاء السيدر مع البيانات المطلوبة
                        var transactionSeeder = new FinancialTransactionSeeder(
                            bookings, payments, allUsers, allProperties, allUnits, accounts);

                        var transactions = transactionSeeder.SeedData();

                        if (transactions.Any())
                        {
                            // ✅ إضافة جميع العمليات المالية
                            _context.FinancialTransactions.AddRange(transactions);
                            await _context.SaveChangesAsync();
                            _logger.LogInformation($"✅ تم بذر {transactions.Count()} عملية مالية بنجاح لـ {bookings.Count} حجز");

                            // إحصائيات تفصيلية
                            var bookingTransactions = transactions.Count(t => t.TransactionType == TransactionType.NewBooking);
                            var paymentTransactions = transactions.Count(t => t.PaymentId != null);
                            var commissionTransactions = transactions.Count(t => t.TransactionType == TransactionType.PlatformCommission);

                            _logger.LogInformation($"📊 التفاصيل: {bookingTransactions} قيد حجز، {paymentTransactions} قيد دفعة، {commissionTransactions} قيد عمولة");

                            // ✅ إضافة عمليات مالية إضافية للدفعات
                            _logger.LogInformation("🔄 إنشاء عمليات مالية إضافية للدفعات...");

                            var paymentTransactionSeeder = new PaymentTransactionSeeder(
                                payments, bookings, accounts, allUnits, allProperties);

                            var additionalTransactions = paymentTransactionSeeder.SeedPaymentTransactions();

                            if (additionalTransactions.Any())
                            {
                                _context.FinancialTransactions.AddRange(additionalTransactions);
                                await _context.SaveChangesAsync();
                                _logger.LogInformation($"✅ تم إضافة {additionalTransactions.Count()} عملية مالية إضافية للدفعات");
                            }
                        }
                        else
                        {
                            _logger.LogWarning("⚠️ لم يتم إنشاء أي عمليات مالية - تحقق من البيانات المطلوبة");
                        }
                    }
                    else
                    {
                        _logger.LogInformation("ℹ️ تخطي بذر العمليات المالية - لا توجد حجوزات أو حسابات محاسبية");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ فشل في بذر العمليات المالية");
                }
            }
            else
            {
                _logger.LogInformation("ℹ️ العمليات المالية موجودة بالفعل، تخطي البذر");
            }

            await SeedAvailabilityAndPricingAsync();
            await SeedPropertyPoliciesAdvancedAsync();
        }

        private async Task SeedAvailabilityAndPricingAsync()
        {
            var today = DateTime.UtcNow.Date;
            var units = await _context.Units.AsNoTracking().ToListAsync();
            if (!units.Any()) return;
            var bookings = await _context.Bookings.AsNoTracking()
                .Where(b => b.Status != YemenBooking.Core.Enums.BookingStatus.Cancelled)
                .ToListAsync();
            var bookingsByUnit = bookings
                .GroupBy(b => b.UnitId)
                .ToDictionary(g => g.Key, g => g.ToList());

            var uaToAdd = new List<UnitAvailability>();

            foreach (var unit in units)
            {
                var hasUA = await _context.Set<UnitAvailability>()
                    .AnyAsync(a => a.UnitId == unit.Id);

                List<Booking>? unitBookings;
                bookingsByUnit.TryGetValue(unit.Id, out unitBookings);
                unitBookings ??= new List<Booking>();

                if (!hasUA)
                {
                    foreach (var booking in unitBookings)
                    {
                        uaToAdd.Add(new UnitAvailability
                        {
                            Id = Guid.NewGuid(),
                            UnitId = unit.Id,
                            StartDate = booking.CheckIn,
                            EndDate = booking.CheckOut,
                            Status = YemenBooking.Core.Enums.AvailabilityStatus.Booked,
                            Reason = "حجز عميل",
                            Notes = $"حجز رقم {booking.Id}",
                            BookingId = booking.Id,
                            CreatedAt = booking.CreatedAt,
                            UpdatedAt = DateTime.UtcNow,
                            IsActive = true,
                            IsDeleted = false
                        });
                    }

                    var maintStart = today.AddDays(60);
                    var hasConflict = unitBookings.Any(b => b.CheckIn <= maintStart.AddDays(3) && b.CheckOut >= maintStart);
                    if (!hasConflict)
                    {
                        uaToAdd.Add(new UnitAvailability
                        {
                            Id = Guid.NewGuid(),
                            UnitId = unit.Id,
                            StartDate = maintStart,
                            EndDate = maintStart.AddDays(3),
                            Status = YemenBooking.Core.Enums.AvailabilityStatus.Maintenance,
                            Reason = "صيانة دورية",
                            Notes = "صيانة مجدولة",
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow,
                            IsActive = true,
                            IsDeleted = false
                        });
                    }
                }
                else
                {
                    if (unitBookings.Count > 0)
                    {
                        var existingBookingIds = await _context.Set<UnitAvailability>()
                            .Where(a => a.UnitId == unit.Id && a.BookingId != null)
                            .Select(a => a.BookingId!.Value)
                            .ToListAsync();

                        foreach (var booking in unitBookings)
                        {
                            if (!existingBookingIds.Contains(booking.Id))
                            {
                                uaToAdd.Add(new UnitAvailability
                                {
                                    Id = Guid.NewGuid(),
                                    UnitId = unit.Id,
                                    StartDate = booking.CheckIn,
                                    EndDate = booking.CheckOut,
                                    Status = YemenBooking.Core.Enums.AvailabilityStatus.Booked,
                                    Reason = "حجز عميل",
                                    Notes = $"حجز رقم {booking.Id}",
                                    BookingId = booking.Id,
                                    CreatedAt = booking.CreatedAt,
                                    UpdatedAt = DateTime.UtcNow,
                                    IsActive = true,
                                    IsDeleted = false
                                });
                            }
                        }
                    }
                }
            }

            if (uaToAdd.Count > 0)
            {
                _context.Set<UnitAvailability>().AddRange(uaToAdd);
                await _context.SaveChangesAsync();
            }

            var unitIdsWithPricing = await _context.Set<PricingRule>()
                .AsNoTracking()
                .Select(r => r.UnitId)
                .Distinct()
                .ToListAsync();

            var pricingToAdd = new List<PricingRule>();
            var rnd = new Random();

            foreach (var unit in units)
            {
                if (unitIdsWithPricing.Contains(unit.Id)) continue;

                var basePrice = unit.BasePrice?.Amount ?? 150000m;
                var currency = unit.BasePrice?.Currency ?? "YER";

                pricingToAdd.Add(new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unit.Id,
                    PriceType = YemenBooking.Core.Enums.PriceType.Base,
                    StartDate = today.AddMonths(-1),
                    EndDate = today.AddYears(2),
                    PriceAmount = basePrice,
                    PricingTier = YemenBooking.Core.Enums.PricingTier.Standard,
                    Currency = currency,
                    Description = $"السعر الأساسي لـ {unit.Name}",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true,
                    IsDeleted = false
                });

                pricingToAdd.Add(new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unit.Id,
                    PriceType = YemenBooking.Core.Enums.PriceType.Weekend,
                    StartDate = today.AddMonths(-1),
                    EndDate = today.AddYears(2),
                    PriceAmount = basePrice * 1.2m,
                    PricingTier = YemenBooking.Core.Enums.PricingTier.Standard,
                    PercentageChange = 20,
                    Currency = currency,
                    Description = "سعر نهاية الأسبوع",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true,
                    IsDeleted = false
                });

                var currentYear = today.Year;
                pricingToAdd.Add(new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unit.Id,
                    PriceType = YemenBooking.Core.Enums.PriceType.Seasonal,
                    StartDate = new DateTime(currentYear, 6, 1, 0, 0, 0, DateTimeKind.Utc),
                    EndDate = new DateTime(currentYear, 8, 31, 0, 0, 0, DateTimeKind.Utc),
                    PriceAmount = basePrice * 1.3m,
                    PricingTier = YemenBooking.Core.Enums.PricingTier.Premium,
                    PercentageChange = 30,
                    Currency = currency,
                    Description = "سعر موسم الصيف",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true,
                    IsDeleted = false
                });

                pricingToAdd.Add(new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unit.Id,
                    PriceType = YemenBooking.Core.Enums.PriceType.Holiday,
                    StartDate = today.AddDays(30),
                    EndDate = today.AddDays(40),
                    PriceAmount = basePrice * 1.5m,
                    PricingTier = YemenBooking.Core.Enums.PricingTier.Luxury,
                    PercentageChange = 50,
                    MaxPrice = basePrice * 2m,
                    Currency = currency,
                    Description = "سعر العطلات",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true,
                    IsDeleted = false
                });

                if (rnd.Next(100) < 25)
                {
                    pricingToAdd.Add(new PricingRule
                    {
                        Id = Guid.NewGuid(),
                        UnitId = unit.Id,
                        PriceType = YemenBooking.Core.Enums.PriceType.EarlyBird,
                        StartDate = today.AddDays(60),
                        EndDate = today.AddDays(180),
                        PriceAmount = basePrice * 0.85m,
                        PricingTier = YemenBooking.Core.Enums.PricingTier.Economy,
                        PercentageChange = -15,
                        MinPrice = basePrice * 0.7m,
                        Currency = currency,
                        Description = "خصم الحجز المبكر",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        IsDeleted = false
                    });
                }
            }

            if (pricingToAdd.Count > 0)
            {
                _context.Set<PricingRule>().AddRange(pricingToAdd);
                await _context.SaveChangesAsync();
            }
        }

        private async Task SeedPropertyPoliciesAdvancedAsync()
        {
            var properties = await _context.Properties
                .AsNoTracking()
                .Select(p => new { p.Id, p.StarRating, p.Currency })
                .ToListAsync();
            if (properties.Count == 0) return;

            var existing = await _context.PropertyPolicies
                .AsNoTracking()
                .Select(pp => new { pp.PropertyId, pp.Type })
                .ToListAsync();
            var existingSet = new HashSet<string>(existing.Select(e => $"{e.PropertyId}:{e.Type}"));

            var refundsByProperty = (await (
                from pay in _context.Payments.AsNoTracking()
                where pay.Status == YemenBooking.Core.Enums.PaymentStatus.Refunded
                   || pay.Status == YemenBooking.Core.Enums.PaymentStatus.PartiallyRefunded
                join b in _context.Bookings.AsNoTracking() on pay.BookingId equals b.Id
                join u in _context.Units.AsNoTracking() on b.UnitId equals u.Id
                group pay by u.PropertyId into g
                select new { PropertyId = g.Key, Count = g.Count() }
            ).ToListAsync()).ToDictionary(x => x.PropertyId, x => x.Count);

            var toAdd = new List<PropertyPolicy>();
            var now = DateTime.UtcNow;
            var types = (YemenBooking.Core.Enums.PolicyType[])Enum.GetValues(typeof(YemenBooking.Core.Enums.PolicyType));

            foreach (var prop in properties)
            {
                var refunds = refundsByProperty.ContainsKey(prop.Id) ? refundsByProperty[prop.Id] : 0;
                var strict = ((prop.Currency ?? "YER").ToUpper() == "USD" || prop.StarRating >= 5) && refunds == 0;
                var flexible = refunds > 0;

                foreach (var t in types)
                {
                    if (existingSet.Contains($"{prop.Id}:{t}")) continue;

                    var pp = new PropertyPolicy
                    {
                        Id = Guid.NewGuid(),
                        PropertyId = prop.Id,
                        Type = t,
                        CancellationWindowDays = 0,
                        RequireFullPaymentBeforeConfirmation = false,
                        MinimumDepositPercentage = 0,
                        MinHoursBeforeCheckIn = 0,
                        Description = "",
                        Rules = "{}",
                        CreatedAt = now,
                        UpdatedAt = now,
                        IsActive = true,
                        IsDeleted = false
                    };

                    if (t == YemenBooking.Core.Enums.PolicyType.Payment)
                    {
                        if (strict)
                        {
                            pp.RequireFullPaymentBeforeConfirmation = true;
                            pp.MinimumDepositPercentage = 100;
                            pp.Description = "يتطلب الدفع الكامل عند التأكيد";
                            pp.Rules = "{\"fullPaymentRequired\":true,\"acceptedMethods\":[\"CreditCard\",\"Paypal\",\"Cash\"]}";
                        }
                        else if (flexible)
                        {
                            pp.RequireFullPaymentBeforeConfirmation = false;
                            pp.MinimumDepositPercentage = 10;
                            pp.Description = "مقدمة 10%، الباقي عند الوصول";
                            pp.Rules = "{\"depositPercentage\":10,\"acceptedMethods\":[\"Cash\",\"JwaliWallet\",\"CreditCard\"]}";
                        }
                        else
                        {
                            pp.RequireFullPaymentBeforeConfirmation = false;
                            pp.MinimumDepositPercentage = 30;
                            pp.Description = "مقدمة 30% عند الحجز";
                            pp.Rules = "{\"depositPercentage\":30,\"acceptedMethods\":[\"Cash\",\"CreditCard\"]}";
                        }
                    }
                    else if (t == YemenBooking.Core.Enums.PolicyType.Cancellation)
                    {
                        if (strict)
                        {
                            pp.CancellationWindowDays = 7;
                            pp.Description = "استرداد 50% إذا تم الإلغاء قبل 7 أيام";
                            pp.Rules = "{\"freeCancel\":false,\"refundPercentage\":50,\"daysBeforeCheckIn\":7}";
                        }
                        else if (flexible)
                        {
                            pp.CancellationWindowDays = 1;
                            pp.Description = "إلغاء مجاني حتى 24 ساعة قبل الوصول";
                            pp.Rules = "{\"freeCancel\":true,\"hoursBeforeCheckIn\":24,\"fullRefund\":true}";
                        }
                        else
                        {
                            pp.CancellationWindowDays = 5;
                            pp.Description = "إلغاء مجاني قبل 5 أيام";
                            pp.Rules = "{\"freeCancel\":true,\"daysBeforeCheckIn\":5}";
                        }
                    }
                    else if (t == YemenBooking.Core.Enums.PolicyType.CheckIn)
                    {
                        if (strict)
                        {
                            pp.MinHoursBeforeCheckIn = 48;
                            pp.Description = "تسجيل الوصول من 3 عصراً، المغادرة حتى 11 صباحاً";
                            pp.Rules = "{\"checkInTime\":\"15:00\",\"checkOutTime\":\"11:00\"}";
                        }
                        else if (flexible)
                        {
                            pp.MinHoursBeforeCheckIn = 12;
                            pp.Description = "تسجيل وصول مرن من 12 ظهراً";
                            pp.Rules = "{\"checkInFrom\":\"12:00\",\"checkOutTime\":\"12:00\",\"flexible\":true}";
                        }
                        else
                        {
                            pp.MinHoursBeforeCheckIn = 24;
                            pp.Description = "تسجيل الوصول من 2 ظهراً، المغادرة حتى 12 ظهراً";
                            pp.Rules = "{\"checkInTime\":\"14:00\",\"checkOutTime\":\"12:00\"}";
                        }
                    }
                    else if (t == YemenBooking.Core.Enums.PolicyType.Children)
                    {
                        if (strict)
                        {
                            pp.Description = "الأطفال أقل من 3 سنوات مجاناً";
                            pp.Rules = "{\"childrenAllowed\":true,\"freeUnder\":3}";
                        }
                        else if (flexible)
                        {
                            pp.Description = "مرحب بالأطفال حتى 8 سنوات مجاناً";
                            pp.Rules = "{\"childrenAllowed\":true,\"freeUnder\":8}";
                        }
                        else
                        {
                            pp.Description = "الأطفال أقل من 6 سنوات مجاناً";
                            pp.Rules = "{\"childrenAllowed\":true,\"freeUnder\":6}";
                        }
                    }
                    else if (t == YemenBooking.Core.Enums.PolicyType.Pets)
                    {
                        if (strict)
                        {
                            pp.Description = "لا يُسمح بالحيوانات الأليفة";
                            pp.Rules = "{\"petsAllowed\":false}";
                        }
                        else if (flexible)
                        {
                            pp.Description = "يُسمح بالحيوانات الأليفة بدون رسوم";
                            pp.Rules = "{\"petsAllowed\":true,\"noFees\":true}";
                        }
                        else
                        {
                            pp.Description = "يُسمح بالحيوانات الأليفة مقابل رسوم";
                            pp.Rules = "{\"petsAllowed\":true,\"fee\":5000}";
                        }
                    }
                    else if (t == YemenBooking.Core.Enums.PolicyType.Modification)
                    {
                        if (strict)
                        {
                            pp.MinHoursBeforeCheckIn = 0;
                            pp.Description = "لا يمكن تعديل الحجز بعد التأكيد";
                            pp.Rules = "{\"modificationAllowed\":false}";
                        }
                        else if (flexible)
                        {
                            pp.MinHoursBeforeCheckIn = 12;
                            pp.Description = "تعديل مجاني حتى 12 ساعة قبل الوصول";
                            pp.Rules = "{\"modificationAllowed\":true,\"freeModificationHours\":12}";
                        }
                        else
                        {
                            pp.MinHoursBeforeCheckIn = 24;
                            pp.Description = "تعديل مجاني حتى 24 ساعة قبل الوصول";
                            pp.Rules = "{\"modificationAllowed\":true,\"freeModificationHours\":24}";
                        }
                    }

                    toAdd.Add(pp);
                }
            }

            if (toAdd.Count > 0)
            {
                await _context.PropertyPolicies.AddRangeAsync(toAdd);
                await _context.SaveChangesAsync();
            }
        }
    }
}