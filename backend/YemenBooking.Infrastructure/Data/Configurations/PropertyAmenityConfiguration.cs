using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان وسيلة الكيان
/// Property Amenity entity configuration
/// </summary>
public class PropertyAmenityConfiguration : IEntityTypeConfiguration<PropertyAmenity>
{
    public void Configure(EntityTypeBuilder<PropertyAmenity> builder)
    {
        builder.ToTable("PropertyAmenities");

        builder.HasKey(pa => pa.Id);

        builder.Property(b => b.Id).HasColumnName("PaId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");

        builder.Property(pa => pa.PropertyId)
            .IsRequired()
            .HasComment("معرف الكيان");

        builder.Property(pa => pa.PtaId)
            .IsRequired()
            .HasComment("معرف مرفق نوع الكيان");

        builder.Property(pa => pa.IsAvailable)
            .IsRequired()
            .HasDefaultValue(true)
            .HasComment("هل المرفق متاح");

        // حذف التهيئة المكررة للخاصية ExtraCost لتجنب تكرار تعريفها
        // builder.Property(pa => pa.ExtraCost).IsRequired();

        // Money value object configuration
        builder.OwnsOne(pa => pa.ExtraCost, money =>
        {
            money.Property(m => m.Amount)
                .HasPrecision(18, 2)
                .HasColumnName("ExtraCost_Amount")
                .HasComment("مبلغ التكلفة الإضافية");

            money.Property(m => m.Currency)
                .HasMaxLength(3)
                .HasColumnName("ExtraCost_Currency")
                .HasComment("عملة التكلفة الإضافية");
        });

        // Indexes
        builder.HasIndex(pa => pa.PropertyId)
            .HasDatabaseName("IX_PropertyAmenities_PropertyId");

        builder.HasIndex(pa => pa.PtaId)
            .HasDatabaseName("IX_PropertyAmenities_PtaId");

        builder.HasIndex(pa => new { pa.PropertyId, pa.PtaId })
            .IsUnique()
            .HasDatabaseName("IX_PropertyAmenities_PropertyId_PtaId");

        builder.HasIndex(pa => pa.IsDeleted)
            .HasDatabaseName("IX_PropertyAmenities_IsDeleted");

        // Relationships
        builder.HasOne(pa => pa.Property)
            .WithMany(p => p.Amenities)
            .HasForeignKey(pa => pa.PropertyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(pa => pa.PropertyTypeAmenity)
            .WithMany(pta => pta.PropertyAmenities)
            .HasForeignKey(pa => pa.PtaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasQueryFilter(pa => !pa.IsDeleted);
    }
}
