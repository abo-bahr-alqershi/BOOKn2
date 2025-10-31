using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان خدمة الحجز
/// Booking Service entity configuration
/// </summary>
public class BookingServiceConfiguration : IEntityTypeConfiguration<BookingService>
{
    public void Configure(EntityTypeBuilder<BookingService> builder)
    {
        builder.ToTable("BookingServices");

        // تكوين الخصائص الأساسية من BaseEntity
        builder.Property(b => b.Id).HasColumnName("BookingServiceId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");
        
        // تكوين الخصائص الأخرى
        builder.Property(bs => bs.BookingId).IsRequired();
        builder.Property(bs => bs.ServiceId).IsRequired();
        builder.Property(bs => bs.Quantity).IsRequired();
        // حذف التهيئة المكررة للخاصية TotalPrice لتجنب تكرار تعريفها
        // builder.Property(bs => bs.TotalPrice).IsRequired();
        
        // تكوين المفتاح الأساسي المركب
        builder.HasKey(bs => new { bs.BookingId, bs.ServiceId });

        builder.Property(bs => bs.BookingId)
            .IsRequired()
            .HasComment("معرف الحجز");

        builder.Property(bs => bs.ServiceId)
            .IsRequired()
            .HasComment("معرف الخدمة");

        builder.Property(bs => bs.Quantity)
            .IsRequired()
            .HasComment("الكمية");

        // Money value object configuration
        builder.OwnsOne(bs => bs.TotalPrice, money =>
        {
            money.Property(m => m.Amount)
                .HasPrecision(18, 2)
                .HasColumnName("TotalPrice_Amount")
                .HasComment("مبلغ السعر الإجمالي للخدمة");

            money.Property(m => m.Currency)
                .HasMaxLength(3)
                .HasColumnName("TotalPrice_Currency")
                .HasComment("عملة السعر الإجمالي للخدمة");
        });

        // Indexes
        builder.HasIndex(bs => bs.BookingId)
            .HasDatabaseName("IX_BookingServices_BookingId");

        builder.HasIndex(bs => bs.ServiceId)
            .HasDatabaseName("IX_BookingServices_ServiceId");

        builder.HasIndex(bs => bs.IsDeleted)
            .HasDatabaseName("IX_BookingServices_IsDeleted");

        // تكوين العلاقات
        builder.HasOne(bs => bs.Booking)
            .WithMany(b => b.BookingServices)
            .HasForeignKey(bs => bs.BookingId);

        builder.HasOne(bs => bs.Service)
            .WithMany(ps => ps.BookingServices)
            .HasForeignKey(bs => bs.ServiceId);

        builder.HasQueryFilter(bs => !bs.IsDeleted);
    }
}
