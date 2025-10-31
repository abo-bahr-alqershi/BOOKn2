using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان قيم الحقول للوحدات
/// UnitFieldValue entity configuration
/// </summary>
public class UnitFieldValueConfiguration : IEntityTypeConfiguration<UnitFieldValue>
{
    public void Configure(EntityTypeBuilder<UnitFieldValue> builder)
    {
        builder.ToTable("UnitFieldValues");

        builder.Property(ufv => ufv.Id)
            .HasColumnName("ValueId")
            .IsRequired();

        builder.Property(ufv => ufv.IsDeleted)
            .HasDefaultValue(false);

        builder.Property(ufv => ufv.DeletedAt)
            .HasColumnType("timestamp with time zone");

        builder.Property(ufv => ufv.UnitId)
            .IsRequired();

        builder.Property(ufv => ufv.UnitTypeFieldId)
            .IsRequired();

        builder.Property(ufv => ufv.FieldValue)
            .HasColumnType("text");

        builder.HasIndex(ufv => ufv.UnitId)
            .HasDatabaseName("IX_UnitFieldValues_UnitId");

        builder.HasIndex(ufv => ufv.UnitTypeFieldId)
            .HasDatabaseName("IX_UnitFieldValues_FieldId");

        builder.HasOne(ufv => ufv.Unit)
            .WithMany(u => u.FieldValues)
            .HasForeignKey(ufv => ufv.UnitId);

        builder.HasOne(ufv => ufv.UnitTypeField)
            .WithMany(ptf => ptf.UnitFieldValues)
            .HasForeignKey(ufv => ufv.UnitTypeFieldId);

        builder.HasQueryFilter(ufv => !ufv.IsDeleted);
    }
} 