using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان إتاحة الوحدة
/// Unit availability entity configuration
/// </summary>
public class UnitAvailabilityConfiguration : IEntityTypeConfiguration<UnitAvailability>
{
    public void Configure(EntityTypeBuilder<UnitAvailability> builder)
    {
        // Map to singular table name to match existing SQLite table
        builder.ToTable("UnitAvailability");

        builder.HasKey(u => u.Id);

        builder.Property(u => u.Id)
            .IsRequired();
        builder.Property(u => u.IsDeleted)
            .HasDefaultValue(false);
        builder.Property(u => u.DeletedAt)
            .HasColumnType("timestamp with time zone");

        builder.Property(u => u.UnitId)
            .IsRequired();
        builder.Property(u => u.StartDate)
            .HasColumnType("timestamp with time zone")
            .IsRequired();
        builder.Property(u => u.EndDate)
            .HasColumnType("timestamp with time zone")
            .IsRequired();
        builder.Property(u => u.Status)
            .IsRequired()
            .HasMaxLength(20);
        builder.Property(u => u.Reason)
            .HasMaxLength(50);
        builder.Property(u => u.Notes)
            .HasMaxLength(500);

        builder.HasIndex(u => new { u.UnitId, u.StartDate, u.EndDate });

        // تكوين العلاقة مع الوحدة - علاقة واحدة فقط
        builder.HasOne(u => u.Unit)
            .WithMany(u => u.UnitAvailabilities)
            .HasForeignKey(u => u.UnitId)
            .OnDelete(DeleteBehavior.Cascade)
            .IsRequired();
        
        // تكوين العلاقة مع كيان الحجز - علاقة واحدة فقط
        builder.HasOne(u => u.Booking)
            .WithMany(b => b.Availabilities)
            .HasForeignKey(u => u.BookingId)
            .OnDelete(DeleteBehavior.SetNull)
            .IsRequired(false);

        // لا نحتاج Query Filter هنا لأن الكود يطبق شرط IsDeleted يدوياً
        // builder.HasQueryFilter(u => !u.IsDeleted);
    }
} 