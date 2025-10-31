using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations
{
    public class UnitInSectionConfiguration : IEntityTypeConfiguration<UnitInSection>
    {
        public void Configure(EntityTypeBuilder<UnitInSection> builder)
        {
            builder.ToTable("UnitInSections");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.BasePrice).HasColumnType("decimal(18,2)");
            builder.Property(x => x.DiscountedPrice).HasColumnType("decimal(18,2)");
            builder.Property(x => x.PropertyAverageRating).HasColumnType("decimal(5,2)");
            builder.Property(x => x.ConversionRate).HasColumnType("decimal(5,2)");

            builder.Property(x => x.UnitName).HasMaxLength(200);
            builder.Property(x => x.PropertyName).HasMaxLength(200);
            builder.Property(x => x.UnitTypeName).HasMaxLength(100);
            builder.Property(x => x.UnitTypeIcon).HasMaxLength(100);
            builder.Property(x => x.Currency).HasMaxLength(10);
            builder.Property(x => x.MainImage).HasMaxLength(500);
            builder.Property(x => x.PrimaryFieldValues).HasColumnType("text");
            builder.Property(x => x.PropertyAddress).HasMaxLength(500);
            builder.Property(x => x.PropertyCity).HasMaxLength(100);
            builder.Property(x => x.MainAmenities).HasColumnType("text");
            builder.Property(x => x.CustomFeatures).HasColumnType("text");
            builder.Property(x => x.PromotionalText).HasMaxLength(300);
            builder.Property(x => x.BadgeColor).HasMaxLength(50);
            builder.Property(x => x.NextAvailableDates).HasColumnType("text");
            builder.Property(x => x.AvailabilityMessage).HasMaxLength(300);
            builder.Property(x => x.Metadata).HasColumnType("text");

            builder.HasOne(x => x.Section)
                .WithMany(s => s.UnitItems)
                .HasForeignKey(x => x.SectionId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.Unit)
                .WithMany(u => u.UnitInSections)
                .HasForeignKey(x => x.UnitId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(x => x.Property)
                .WithMany(p => p.UnitInSections)
                .HasForeignKey(x => x.PropertyId)
                .OnDelete(DeleteBehavior.Cascade);

            // Additional images linked through PropertyImage.UnitInSectionId (configured elsewhere)

            builder.HasIndex(x => new { x.SectionId, x.UnitId }).IsUnique();
        }
    }
}

