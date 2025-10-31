using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان خدمة الكيان
/// Property Service entity configuration
/// </summary>
public class PropertyServiceConfiguration : IEntityTypeConfiguration<PropertyService>
{
    public void Configure(EntityTypeBuilder<PropertyService> builder)
    {
        builder.ToTable("PropertyServices");

        builder.HasKey(ps => ps.Id);

        builder.Property(ps => ps.Id)
            .IsRequired()
            .HasComment("معرف الخدمة الفريد");

        builder.Property(ps => ps.PropertyId)
            .IsRequired()
            .HasComment("معرف الكيان");

        builder.Property(ps => ps.Name)
            .IsRequired()
            .HasMaxLength(200)
            .HasComment("اسم الخدمة");

        builder.Property(ps => ps.Description)
            .HasMaxLength(1000)
            .IsRequired(false)
            .HasComment("وصف الخدمة");

        // Money value object configuration
        builder.OwnsOne(ps => ps.Price, money =>
        {
            money.Property(m => m.Amount)
                .HasPrecision(18, 2)
                .HasColumnName("Price_Amount")
                .HasComment("مبلغ سعر الخدمة");

            money.Property(m => m.Currency)
                .HasMaxLength(3)
                .HasColumnName("Price_Currency")
                .HasComment("عملة سعر الخدمة");
        });

        builder.Property(ps => ps.PricingModel)
            .IsRequired()
            .HasComment("نموذج التسعير");

        // تكوين الخصائص الأساسية من BaseEntity
        builder.Property(ps => ps.Id).HasColumnName("ServiceId").IsRequired();
        builder.Property(ps => ps.IsDeleted).HasDefaultValue(false);
        builder.Property(ps => ps.DeletedAt).HasColumnType("timestamp with time zone");
        builder.Property(ps => ps.CreatedAt).HasColumnType("timestamp with time zone").IsRequired();
        builder.Property(ps => ps.UpdatedAt).HasColumnType("timestamp with time zone").IsRequired();

        // Indexes
        builder.HasIndex(ps => ps.PropertyId)
            .HasDatabaseName("IX_PropertyServices_PropertyId");

        builder.HasIndex(ps => ps.Name)
            .HasDatabaseName("IX_PropertyServices_Name");

        builder.HasIndex(ps => ps.IsDeleted)
            .HasDatabaseName("IX_PropertyServices_IsDeleted");

        // Relationships
        builder.HasOne(ps => ps.Property)
            .WithMany(p => p.Services)
            .HasForeignKey(ps => ps.PropertyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(ps => ps.BookingServices)
            .WithOne(bs => bs.Service)
            .HasForeignKey(bs => bs.ServiceId)
            .OnDelete(DeleteBehavior.Restrict);

        // Query filters
        builder.HasQueryFilter(ps => !ps.IsDeleted);
    }
}
