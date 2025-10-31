using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان نوع الكيان
/// Property Type entity configuration
/// </summary>
public class PropertyTypeConfiguration : IEntityTypeConfiguration<PropertyType>
{
    public void Configure(EntityTypeBuilder<PropertyType> builder)
    {
        // تعيين اسم الجدول
        // Set table name
        builder.ToTable("PropertyTypes");

        // تعيين المفتاح الأساسي
        // Set primary key
        builder.HasKey(pt => pt.Id);

        // تكوين الخصائص الأساسية من BaseEntity
        builder.Property(b => b.Id).HasColumnName("TypeId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");
        
        // تكوين الخصائص الأخرى
        builder.Property(pt => pt.Name).IsRequired().HasMaxLength(50);
        builder.Property(pt => pt.Description).HasMaxLength(500);
        builder.Property(pt => pt.DefaultAmenities).HasColumnType("text");
        
        // تكوين الفهرس
        builder.HasIndex(pt => pt.Name).IsUnique();

        // إعداد العلاقات
        // Configure relationships
        builder.HasMany(pt => pt.Properties)
            .WithOne(p => p.PropertyType)
            .HasForeignKey(p => p.TypeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(pt => pt.UnitTypes)
            .WithOne(ut => ut.PropertyType)
            .HasForeignKey(ut => ut.PropertyTypeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(pt => pt.PropertyTypeAmenities)
            .WithOne(pta => pta.PropertyType)
            .HasForeignKey(pta => pta.PropertyTypeId)
            .OnDelete(DeleteBehavior.Cascade);

        // Seed data moved to DataSeedingService to avoid duplicates in migrations
        // تم نقل البيانات الأولية إلى DataSeedingService لتجنب التكرار

        // تطبيق مرشح الحذف الناعم
        // Apply soft delete filter
        builder.HasQueryFilter(pt => !pt.IsDeleted);
    }
}
