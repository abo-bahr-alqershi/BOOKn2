using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.AspNetCore.Http;
using YemenBooking.Infrastructure.Data.Context;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace YemenBooking.Infrastructure.Data.Context;

/// <summary>
/// Factory for design-time DbContext creation.
/// مولد سياق قاعدة البيانات في وقت التصميم
/// </summary>
public class YemenBookingDbContextFactory : IDesignTimeDbContextFactory<YemenBookingDbContext>
{
    public YemenBookingDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<YemenBookingDbContext>();
        // تهيئة الاتصال بقاعدة بيانات PostgreSQL المحلية
        optionsBuilder.UseNpgsql("Host=localhost;Database=YemenBookingDb;Username=postgres;Password=postgres");
        // For design-time, httpContextAccessor not used, passing new HttpContextAccessor instance
        return new YemenBookingDbContext(
            optionsBuilder.Options,
            new HttpContextAccessor());
    }
} 