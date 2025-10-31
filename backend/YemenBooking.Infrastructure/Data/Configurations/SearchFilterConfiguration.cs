using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان فلاتر البحث
/// SearchFilter entity configuration
/// </summary>
public class SearchFilterConfiguration : IEntityTypeConfiguration<SearchFilter>
{
    public void Configure(EntityTypeBuilder<SearchFilter> builder)
    {
        builder.ToTable("SearchFilters");

        builder.Property(sf => sf.Id)
            .HasColumnName("FilterId")
            .IsRequired();

        builder.Property(sf => sf.IsDeleted)
            .HasDefaultValue(false);

        builder.Property(sf => sf.DeletedAt)
            .HasColumnType("timestamp with time zone");

        builder.Property(sf => sf.FieldId)
            .IsRequired();

        builder.Property(sf => sf.FilterType)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(sf => sf.DisplayName)
            .HasMaxLength(100);

        builder.Property(sf => sf.FilterOptions)
            .HasColumnType("text");

        builder.Property(sf => sf.SortOrder)
            .HasDefaultValue(0);

        builder.Property(sf => sf.IsActive)
            .HasDefaultValue(true);

        builder.HasIndex(sf => sf.FieldId)
            .HasDatabaseName("IX_SearchFilters_FieldId");

        builder.HasOne(sf => sf.UnitTypeField)
            .WithMany(ptf => ptf.SearchFilters)
            .HasForeignKey(sf => sf.FieldId);

        builder.HasQueryFilter(sf => !sf.IsDeleted);
    }
} 