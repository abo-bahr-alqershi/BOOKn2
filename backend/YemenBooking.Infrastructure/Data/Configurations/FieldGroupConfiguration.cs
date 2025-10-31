using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان مجموعات الحقول
/// FieldGroup entity configuration
/// </summary>
public class FieldGroupConfiguration : IEntityTypeConfiguration<FieldGroup>
{
    public void Configure(EntityTypeBuilder<FieldGroup> builder)
    {
        builder.ToTable("FieldGroups");

        builder.Property(fg => fg.Id)
            .HasColumnName("GroupId")
            .IsRequired();

        builder.Property(fg => fg.IsDeleted)
            .HasDefaultValue(false);

        builder.Property(fg => fg.DeletedAt)
            .HasColumnType("timestamp with time zone");

        builder.Property(fg => fg.UnitTypeId)
            .IsRequired();

        builder.Property(fg => fg.GroupName)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(fg => fg.DisplayName)
            .HasMaxLength(100);

        builder.Property(fg => fg.Description)
            .HasMaxLength(500);

        builder.Property(fg => fg.SortOrder)
            .HasDefaultValue(0);

        builder.Property(fg => fg.IsCollapsible)
            .HasDefaultValue(false);

        builder.Property(fg => fg.IsExpandedByDefault)
            .HasDefaultValue(true);

        builder.HasIndex(fg => new { fg.UnitTypeId, fg.SortOrder })
            .HasDatabaseName("IX_FieldGroups_PropertyTypeId_SortOrder");

        builder.HasOne(fg => fg.UnitType)
            .WithMany(pt => pt.FieldGroups)
            .HasForeignKey(fg => fg.UnitTypeId);

        builder.HasMany(fg => fg.FieldGroupFields)
            .WithOne(fgf => fgf.FieldGroup)
            .HasForeignKey(fgf => fgf.GroupId);

        builder.HasQueryFilter(fg => !fg.IsDeleted);
    }
} 