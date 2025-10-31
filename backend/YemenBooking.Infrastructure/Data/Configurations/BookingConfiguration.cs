using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;
using Npgsql.EntityFrameworkCore.PostgreSQL;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان الحجز
/// Booking entity configuration
/// </summary>
public class BookingConfiguration : IEntityTypeConfiguration<Booking>
{
    public void Configure(EntityTypeBuilder<Booking> builder)
    {
        builder.ToTable("Bookings");

        builder.HasKey(b => b.Id);

        builder.Property(b => b.Id)
            .IsRequired()
            .HasComment("معرف الحجز الفريد");

        builder.Property(b => b.UserId)
            .IsRequired()
            .HasComment("معرف المستخدم");

        builder.Property(b => b.UnitId)
            .IsRequired()
            .HasComment("معرف الوحدة");

        builder.Property(b => b.CheckIn)
            .IsRequired()
            .HasComment("تاريخ الوصول");

        builder.Property(b => b.CheckOut)
            .IsRequired()
            .HasComment("تاريخ المغادرة");

        builder.Property(b => b.GuestsCount)
            .IsRequired()
            .HasComment("عدد الضيوف");

        // Money value object configuration
        builder.OwnsOne(b => b.TotalPrice, money =>
        {
            money.Property(m => m.Amount)
                .HasPrecision(18, 2)
                .HasColumnName("TotalPrice_Amount")
                .HasComment("مبلغ السعر الإجمالي");

            money.Property(m => m.Currency)
                .HasMaxLength(3)
                .HasColumnName("TotalPrice_Currency")
                .HasComment("عملة السعر الإجمالي");
        });

        // Link booking total price currency to Currency entity via shadow FK column
        builder.HasOne<Currency>()
            .WithMany()
            .HasForeignKey("TotalPrice_Currency")
            .HasPrincipalKey(c => c.Code)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Property(b => b.Status)
            .IsRequired()
            .HasMaxLength(50)
            .HasComment("حالة الحجز");

        builder.Property(b => b.BookedAt)
            .IsRequired()
            .HasDefaultValueSql("CURRENT_TIMESTAMP")
            .HasComment("تاريخ الحجز");

        builder.Property(b => b.IsDeleted)
            .IsRequired()
            .HasDefaultValue(false)
            .HasComment("حالة الحذف الناعم");

        builder.Property(b => b.DeletedAt)
            .HasComment("تاريخ الحذف");

        // Policy snapshot mapping
        builder.Property(b => b.PolicySnapshot)
            .HasColumnType("text")
            .HasComment("لقطة السياسات وقت إنشاء الحجز (JSON)");
        builder.Property(b => b.PolicySnapshotAt)
            .HasColumnType("timestamp with time zone")
            .HasComment("تاريخ حفظ لقطة السياسات");

        // Indexes
        builder.HasIndex(b => b.UserId)
            .HasDatabaseName("IX_Bookings_UserId");

        builder.HasIndex(b => b.UnitId)
            .HasDatabaseName("IX_Bookings_UnitId");

        builder.HasIndex(b => b.Status)
            .HasDatabaseName("IX_Bookings_Status");

        builder.HasIndex(b => new { b.CheckIn, b.CheckOut })
            .HasDatabaseName("IX_Bookings_CheckInOut");

        builder.HasIndex(b => b.IsDeleted)
            .HasDatabaseName("IX_Bookings_IsDeleted");

        builder.HasIndex(b => new { b.UserId, b.BookedAt });
        builder.HasIndex(b => new { b.UnitId, b.CheckIn, b.CheckOut });

        builder.HasIndex(b => b.BookedAt)
            .HasDatabaseName("IX_Bookings_BookedAt");

        builder.HasIndex(b => b.UnitId)
            .HasDatabaseName("IX_Bookings_Unit_Confirmed")
            .HasFilter("\"Status\" = 0");

        builder.HasIndex(b => new { b.UnitId, b.CheckIn, b.CheckOut })
            .HasDatabaseName("IX_Bookings_Unit_CheckIn_CheckOut_gist")
            .HasMethod("gist");

        // Relationships
        builder.HasOne(b => b.User)
            .WithMany(u => u.Bookings)
            .HasForeignKey(b => b.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(b => b.Unit)
            .WithMany(u => u.Bookings)
            .HasForeignKey(b => b.UnitId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(b => b.Payments)
            .WithOne(p => p.Booking)
            .HasForeignKey(p => p.BookingId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(b => b.BookingServices)
            .WithOne(bs => bs.Booking)
            .HasForeignKey(bs => bs.BookingId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(b => b.Reviews)
            .WithOne(r => r.Booking)
            .HasForeignKey(r => r.BookingId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(b => b.Availabilities)
            .WithOne(ua => ua.Booking)
            .HasForeignKey(ua => ua.BookingId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasQueryFilter(b => !b.IsDeleted);

        // تكوين الخصائص الأساسية من BaseEntity
        builder.Property(b => b.Id).HasColumnName("BookingId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");

        // تكوين الخصائص الأخرى
        builder.Property(b => b.UserId).IsRequired();
        builder.Property(b => b.UnitId).IsRequired();
        builder.Property(b => b.CheckIn).HasColumnType("timestamp with time zone").IsRequired();
        builder.Property(b => b.CheckOut).HasColumnType("timestamp with time zone").IsRequired();
        builder.Property(b => b.GuestsCount).IsRequired();
        builder.Property(b => b.Status).IsRequired();
        builder.Property(b => b.BookedAt).HasColumnType("timestamp with time zone").IsRequired();
    }
}
