using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان وسيلة نوع الكيان
/// Property Type Amenity entity configuration
/// </summary>
public class PropertyTypeAmenityConfiguration : IEntityTypeConfiguration<PropertyTypeAmenity>
{
    public void Configure(EntityTypeBuilder<PropertyTypeAmenity> builder)
    {
        builder.ToTable("PropertyTypeAmenities");

        // تكوين الخصائص الأساسية من BaseEntity
        builder.Property(b => b.Id).HasColumnName("PtaId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");
        
        // تكوين الخصائص الأخرى
        builder.Property(pta => pta.PropertyTypeId).IsRequired();
        builder.Property(pta => pta.AmenityId).IsRequired();
        builder.Property(pta => pta.IsDefault).HasDefaultValue(false);
        
        // تحديد المفتاح الأساسي باستخدام Id الموروث من BaseEntity
        builder.HasKey(pta => pta.Id);
        
        // تكوين العلاقات
        builder.HasOne(pta => pta.PropertyType)
               .WithMany(pt => pt.PropertyTypeAmenities)
               .HasForeignKey(pta => pta.PropertyTypeId);
        
        builder.HasOne(pta => pta.Amenity)
               .WithMany(a => a.PropertyTypeAmenities)
               .HasForeignKey(pta => pta.AmenityId);
        
        builder.HasMany(pta => pta.PropertyAmenities)
               .WithOne(pa => pa.PropertyTypeAmenity)
               .HasForeignKey(pa => pa.PtaId);

        // Indexes
        builder.HasIndex(pta => pta.PropertyTypeId)
            .HasDatabaseName("IX_PropertyTypeAmenities_PropertyTypeId");

        builder.HasIndex(pta => pta.AmenityId)
            .HasDatabaseName("IX_PropertyTypeAmenities_AmenityId");

        builder.HasIndex(pta => new { pta.PropertyTypeId, pta.AmenityId })
            .IsUnique()
            .HasDatabaseName("IX_PropertyTypeAmenities_PropertyTypeId_AmenityId");

        builder.HasIndex(pta => pta.IsDeleted)
            .HasDatabaseName("IX_PropertyTypeAmenities_IsDeleted");

        builder.HasQueryFilter(pta => !pta.IsDeleted);
    }
}
