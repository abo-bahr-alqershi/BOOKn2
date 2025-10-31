using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

public class PropertyInSectionImageConfiguration : IEntityTypeConfiguration<PropertyInSectionImage>
{
    public void Configure(EntityTypeBuilder<PropertyInSectionImage> builder)
    {
        builder.ToTable("PropertyInSectionImages");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.TempKey).HasMaxLength(100);
        builder.Property(x => x.Name).IsRequired().HasMaxLength(200);
        builder.Property(x => x.Url).IsRequired().HasMaxLength(500);
        builder.Property(x => x.Type).HasMaxLength(100);
        builder.Property(x => x.Caption).HasMaxLength(300);
        builder.Property(x => x.AltText).HasMaxLength(300);
        builder.Property(x => x.Tags).HasColumnType("text");
        builder.Property(x => x.Sizes).HasColumnType("text");
        builder.Property(x => x.UploadedAt).HasColumnType("timestamp with time zone");
        builder.Property(x => x.MediaType).HasMaxLength(20).HasDefaultValue("image");
        builder.Property(x => x.VideoThumbnailUrl).HasMaxLength(500);

        builder.Property(x => x.PropertyInSectionId).IsRequired(false);
        builder.HasOne(x => x.PropertyInSection)
            .WithMany(p => p.AdditionalImages)
            .HasForeignKey(x => x.PropertyInSectionId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(x => x.PropertyInSectionId);
        builder.HasIndex(x => x.TempKey);
        builder.HasQueryFilter(x => !x.IsDeleted);
    }
}

