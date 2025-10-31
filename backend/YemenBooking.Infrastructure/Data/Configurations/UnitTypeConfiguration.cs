using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان نوع الوحدة
/// Unit Type entity configuration
/// </summary>
public class UnitTypeConfiguration : IEntityTypeConfiguration<UnitType>
{
    public void Configure(EntityTypeBuilder<UnitType> builder)
    {
        builder.ToTable("UnitTypes");

        builder.HasKey(ut => ut.Id);

        builder.Property(b => b.Id).HasColumnName("UnitTypeId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");

        builder.Property(ut => ut.PropertyTypeId)
            .IsRequired()
            .HasComment("معرف نوع الكيان");

        builder.Property(ut => ut.Name)
            .IsRequired()
            .HasMaxLength(50)
            .HasComment("اسم نوع الوحدة");

        builder.Property(ut => ut.MaxCapacity)
            .IsRequired()
            .HasComment("الحد الأقصى للسعة");

        // Commission rate: store as decimal(5,2), nullable
        builder.Property(ut => ut.SystemCommissionRate)
            .HasPrecision(5, 2)
            .HasColumnType("decimal(5,2)")
            .HasComment("نسبة عمولة النظام لبوكن لهذا النوع");

        // Indexes
        builder.HasIndex(ut => new { ut.Name, ut.PropertyTypeId }).IsUnique();

        // Relationships
        builder.HasOne(ut => ut.PropertyType)
            .WithMany(pt => pt.UnitTypes)
            .HasForeignKey(ut => ut.PropertyTypeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(ut => ut.Units)
            .WithOne(u => u.UnitType)
            .HasForeignKey(u => u.UnitTypeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasQueryFilter(ut => !ut.IsDeleted);
    }
}
