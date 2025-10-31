using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان الوحدة
/// Unit entity configuration
/// </summary>
public class UnitConfiguration : IEntityTypeConfiguration<Unit>
{
    public void Configure(EntityTypeBuilder<Unit> builder)
    {
        builder.ToTable("Units");

        builder.HasKey(u => u.Id);

        builder.Property(b => b.Id).HasColumnName("UnitId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");

        builder.Property(u => u.PropertyId).IsRequired();
        builder.Property(u => u.UnitTypeId).IsRequired();
        builder.Property(u => u.Name).IsRequired().HasMaxLength(100);
        // حذف التهيئة المكررة للخاصية BasePrice لتجنب تكرار تعريفها
        // builder.Property(u => u.BasePrice).IsRequired();
        builder.Property(u => u.CustomFeatures).HasColumnType("text");
        builder.Property(u => u.IsAvailable).HasDefaultValue(true);
        builder.Property(u => u.AllowsCancellation)
            .HasDefaultValue(true)
            .HasComment("هل تقبل الوحدة إلغاء الحجز");
        builder.Property(u => u.CancellationWindowDays)
            .HasComment("عدد أيام نافذة الإلغاء قبل الوصول");

        // طريقة حساب السعر
        builder.Property(u => u.PricingMethod)
            .IsRequired()
            .HasComment("طريقة حساب السعر");

        builder.HasIndex(u => u.PricingMethod)
            .HasDatabaseName("IX_Units_PricingMethod");

        builder.HasOne(u => u.Property)
            .WithMany(p => p.Units)
            .HasForeignKey(u => u.PropertyId);

        builder.HasOne(u => u.UnitType)
            .WithMany(ut => ut.Units)
            .HasForeignKey(u => u.UnitTypeId);

        builder.HasMany(u => u.Bookings)
            .WithOne(b => b.Unit)
            .HasForeignKey(b => b.UnitId);

        builder.HasMany(u => u.UnitAvailabilities)
            .WithOne(ua => ua.Unit)
            .HasForeignKey(ua => ua.UnitId);

        builder.HasMany(u => u.Images)
            .WithOne(i => i.Unit)
            .HasForeignKey(i => i.UnitId);

        builder.HasIndex(u => new { u.PropertyId, u.Name }).IsUnique();

        // Money value object configuration
        builder.OwnsOne(u => u.BasePrice, money =>
        {
            money.Property(m => m.Amount)
                .HasPrecision(18, 2)
                .HasColumnName("BasePrice_Amount")
                .HasComment("مبلغ السعر الأساسي");

            money.Property(m => m.Currency)
                .HasMaxLength(3)
                .HasColumnName("BasePrice_Currency")
                .HasComment("عملة السعر الأساسي");
        });

        // Indexes
        builder.HasIndex(u => u.PropertyId)
            .HasDatabaseName("IX_Units_PropertyId");

        builder.HasIndex(u => u.UnitTypeId)
            .HasDatabaseName("IX_Units_UnitTypeId");

        builder.HasIndex(u => u.IsAvailable)
            .HasDatabaseName("IX_Units_IsAvailable");

        builder.HasIndex(u => u.IsDeleted)
            .HasDatabaseName("IX_Units_IsDeleted");

        builder.HasIndex(u => u.AllowsCancellation)
            .HasDatabaseName("IX_Units_AllowsCancellation");

        builder.HasQueryFilter(u => !u.IsDeleted);
    }
}
