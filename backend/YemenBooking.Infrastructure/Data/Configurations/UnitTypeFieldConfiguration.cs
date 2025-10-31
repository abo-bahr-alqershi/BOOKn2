using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان حقول نوع الكيان
/// UnitTypeField entity configuration
/// </summary>
public class UnitTypeFieldConfiguration : IEntityTypeConfiguration<UnitTypeField>
{
    public void Configure(EntityTypeBuilder<UnitTypeField> builder)
    {
        builder.ToTable("UnitTypeFields");

        builder.Property(ptf => ptf.Id)
            .HasColumnName("FieldId")
            .IsRequired();

        builder.Property(ptf => ptf.IsDeleted)
            .HasDefaultValue(false);

        builder.Property(ptf => ptf.DeletedAt)
            .HasColumnType("timestamp with time zone");

        builder.Property(ptf => ptf.UnitTypeId)
            .IsRequired();

        builder.Property(ptf => ptf.FieldTypeId)
            .IsRequired();

        builder.Property(ptf => ptf.FieldName)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(ptf => ptf.DisplayName)
            .HasMaxLength(100);

        builder.Property(ptf => ptf.Description)
            .HasMaxLength(500);

        builder.Property(ptf => ptf.FieldOptions)
            .HasColumnType("text");

        builder.Property(ptf => ptf.ValidationRules)
            .HasColumnType("text");

        builder.Property(ptf => ptf.IsRequired)
            .HasDefaultValue(false);

        builder.Property(ptf => ptf.IsSearchable)
            .HasDefaultValue(false);

        builder.Property(ptf => ptf.IsPublic)
            .HasDefaultValue(false);

        builder.Property(ptf => ptf.SortOrder)
            .HasDefaultValue(0);

        builder.Property(ptf => ptf.Category)
            .HasMaxLength(50);

        builder.Property(ptf => ptf.IsForUnits)
            .HasDefaultValue(false);

        builder.Property(ptf => ptf.ShowInCards)
            .HasDefaultValue(false);

        builder.Property(ptf => ptf.IsPrimaryFilter)
            .HasDefaultValue(false);

        builder.Property(ptf => ptf.Priority)
            .HasDefaultValue(0);

        builder.HasIndex(ptf => new { ptf.UnitTypeId, ptf.FieldName })
            .IsUnique()
            .HasDatabaseName("IX_UnitTypeFields_PropertyTypeId_FieldName");

        builder.HasOne(ptf => ptf.UnitType)
            .WithMany(pt => pt.UnitTypeFields)
            .HasForeignKey(ptf => ptf.UnitTypeId);

        builder.HasMany(ptf => ptf.UnitFieldValues)
            .WithOne(ufv => ufv.UnitTypeField)
            .HasForeignKey(ufv => ufv.UnitTypeFieldId);

        builder.HasMany(ptf => ptf.FieldGroupFields)
            .WithOne(fgf => fgf.UnitTypeField)
            .HasForeignKey(fgf => fgf.FieldId);

        builder.HasMany(ptf => ptf.SearchFilters)
            .WithOne(sf => sf.UnitTypeField)
            .HasForeignKey(sf => sf.FieldId);

        builder.HasQueryFilter(ptf => !ptf.IsDeleted);
    }
} 