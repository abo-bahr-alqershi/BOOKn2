using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان صورة التقييم
/// Review Image entity configuration
/// </summary>
public class ReviewImageConfiguration : IEntityTypeConfiguration<ReviewImage>
{
    public void Configure(EntityTypeBuilder<ReviewImage> builder)
    {
        builder.ToTable("ReviewImages");

        builder.HasKey(ri => ri.Id);

        builder.Property(ri => ri.Id)
            .IsRequired()
            .HasComment("معرف الصورة الفريدة");

        builder.Property(ri => ri.ReviewId)
            .IsRequired()
            .HasComment("معرف التقييم المرتبط");

        builder.Property(ri => ri.Url)
            .IsRequired()
            .HasMaxLength(500)
            .HasComment("مسار الصورة");

        builder.Property(ri => ri.Name)
            .HasMaxLength(200)
            .HasComment("اسم الملف");

        builder.Property(ri => ri.SizeBytes)
            .IsRequired()
            .HasComment("حجم الملف بالبايت");

        builder.Property(ri => ri.Type)
            .HasMaxLength(100)
            .HasComment("نوع المحتوى");

        builder.Property(ri => ri.Category)
            .IsRequired()
            .HasComment("فئة الصورة");

        builder.Property(ri => ri.Caption)
            .HasMaxLength(200)
            .HasComment("تعليق توضيحي للصورة");

        builder.Property(ri => ri.AltText)
            .HasMaxLength(200)
            .HasComment("نص بديل للصورة");

        builder.Property(ri => ri.Tags)
            .HasColumnType("text")
            .HasComment("وسوم الصورة");

        builder.Property(ri => ri.IsMain)
            .IsRequired()
            .HasDefaultValue(false)
            .HasComment("هل هي الصورة الرئيسية");

        builder.Property(ri => ri.DisplayOrder)
            .HasDefaultValue(0)
            .HasComment("ترتيب العرض");

        builder.Property(ri => ri.UploadedAt)
            .IsRequired()
            .HasColumnType("timestamp with time zone")
            .HasComment("تاريخ الرفع");

        builder.Property(ri => ri.Status)
            .IsRequired()
            .HasComment("حالة الموافقة للصورة");

        builder.Property(ri => ri.IsDeleted)
            .IsRequired()
            .HasDefaultValue(false)
            .HasComment("حالة الحذف الناعم");

        builder.Property(ri => ri.DeletedAt)
            .HasComment("تاريخ الحذف");

        // Relationships
        builder.HasOne(ri => ri.Review)
            .WithMany(r => r.Images)
            .HasForeignKey(ri => ri.ReviewId)
            .OnDelete(DeleteBehavior.Cascade);

        // Indexes
        builder.HasIndex(ri => ri.ReviewId);

        // Query filter
        builder.HasQueryFilter(ri => !ri.IsDeleted);
    }
} 