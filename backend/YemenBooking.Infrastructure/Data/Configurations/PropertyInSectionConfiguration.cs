using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations
{
    public class PropertyInSectionConfiguration : IEntityTypeConfiguration<PropertyInSection>
    {
        public void Configure(EntityTypeBuilder<PropertyInSection> builder)
        {
            builder.ToTable("PropertyInSections");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.BasePrice).HasColumnType("decimal(18,2)");
            builder.Property(x => x.AverageRating).HasColumnType("decimal(5,2)");
            builder.Property(x => x.ConversionRate).HasColumnType("decimal(5,2)");

            builder.Property(x => x.PropertyName).HasMaxLength(200);
            builder.Property(x => x.Address).HasMaxLength(500);
            builder.Property(x => x.City).HasMaxLength(100);
            builder.Property(x => x.PropertyType).HasMaxLength(100);
            builder.Property(x => x.Currency).HasMaxLength(10);
            builder.Property(x => x.MainImage).HasMaxLength(500);
            builder.Property(x => x.ShortDescription).HasMaxLength(500);
            builder.Property(x => x.PromotionalText).HasMaxLength(300);
            builder.Property(x => x.BadgeColor).HasMaxLength(50);
            builder.Property(x => x.Metadata).HasColumnType("text");

            builder.HasOne(x => x.Section)
                .WithMany(s => s.PropertyItems)
                .HasForeignKey(x => x.SectionId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.Property)
                .WithMany(p => p.PropertyInSections)
                .HasForeignKey(x => x.PropertyId)
                .OnDelete(DeleteBehavior.Restrict);

            // Allow additional images to be linked via PropertyImages table
            // using the PropertyInSectionId FK configured in PropertyImageConfiguration

            builder.HasIndex(x => new { x.SectionId, x.PropertyId }).IsUnique();
        }
    }
}

