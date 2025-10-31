using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان المفضلة
/// Favorite entity configuration
/// </summary>
public class FavoriteConfiguration : IEntityTypeConfiguration<Favorite>
{
    public void Configure(EntityTypeBuilder<Favorite> builder)
    {
        builder.ToTable("Favorites");

        builder.HasKey(f => f.Id);

        builder.Property(f => f.Id)
            .IsRequired();

        builder.Property(f => f.UserId)
            .IsRequired()
            .HasComment("معرف المستخدم");

        builder.Property(f => f.PropertyId)
            .IsRequired()
            .HasComment("معرف العقار");

        builder.Property(f => f.DateAdded)
            .IsRequired()
            .HasColumnType("timestamp with time zone")
            .HasComment("تاريخ الإضافة إلى المفضلة");

        // BaseEntity common columns
        builder.Property(f => f.CreatedAt)
            .HasColumnType("timestamp with time zone");

        builder.Property(f => f.UpdatedAt)
            .HasColumnType("timestamp with time zone");

        builder.Property(f => f.IsDeleted)
            .HasDefaultValue(false);

        // Relationships (no back-collection on User/Property side)
        builder.HasOne(f => f.User)
            .WithMany()
            .HasForeignKey(f => f.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(f => f.Property)
            .WithMany()
            .HasForeignKey(f => f.PropertyId)
            .OnDelete(DeleteBehavior.Cascade);

        // Unique constraint per user-property
        builder.HasIndex(f => new { f.UserId, f.PropertyId })
            .IsUnique()
            .HasDatabaseName("IX_Favorites_User_Property");

        builder.HasIndex(f => f.UserId)
            .HasDatabaseName("IX_Favorites_UserId");

        builder.HasIndex(f => f.PropertyId)
            .HasDatabaseName("IX_Favorites_PropertyId");

        // Global query filter for soft delete
        builder.HasQueryFilter(f => !f.IsDeleted);
    }
}
