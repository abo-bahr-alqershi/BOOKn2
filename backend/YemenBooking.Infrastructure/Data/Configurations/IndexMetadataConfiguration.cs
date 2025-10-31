using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations
{
    /// <summary>
    /// إعدادات Entity Framework لجدول IndexMetadata
    /// Entity Framework configuration for IndexMetadata table
    /// </summary>
    public class IndexMetadataConfiguration : IEntityTypeConfiguration<IndexMetadata>
    {
        public void Configure(EntityTypeBuilder<IndexMetadata> builder)
        {
            // الجدول والمفتاح الأساسي
            builder.ToTable("IndexMetadata");
            builder.HasKey(x => x.IndexType);

            // خصائص الحقول
            builder.Property(x => x.IndexType)
                .IsRequired()
                .HasMaxLength(100)
                .HasComment("نوع الفهرس - Index type identifier");

            builder.Property(x => x.LastUpdateTime)
                .IsRequired()
                .HasDefaultValueSql("NOW()")
                .HasComment("آخر وقت تحديث للفهرس - Last index update time");

            builder.Property(x => x.TotalRecords)
                .IsRequired()
                .HasDefaultValue(0)
                .HasComment("عدد السجلات في الفهرس - Total records in index");

            builder.Property(x => x.LastProcessedId)
                .IsRequired(false)
                .HasComment("آخر معرف تم معالجته - Last processed entity ID");

            builder.Property(x => x.Status)
                .IsRequired()
                .HasMaxLength(50)
                .HasDefaultValue("Active")
                .HasComment("حالة الفهرس - Index status");

            builder.Property(x => x.Version)
                .IsRequired()
                .HasDefaultValue(1)
                .IsConcurrencyToken()
                .HasComment("رقم الإصدار للتحكم في التزامن - Version for concurrency control");

            builder.Property(x => x.FileSizeBytes)
                .IsRequired()
                .HasDefaultValue(0)
                .HasComment("حجم ملف الفهرس بالبايت - Index file size in bytes");

            builder.Property(x => x.OperationsSinceOptimization)
                .IsRequired()
                .HasDefaultValue(0)
                .HasComment("عدد العمليات منذ آخر تحسين - Operations since last optimization");

            builder.Property(x => x.LastOptimizationTime)
                .IsRequired(false)
                .HasComment("آخر وقت تحسين - Last optimization time");

            builder.Property(x => x.Metadata)
                .IsRequired(false)
                .HasMaxLength(2000)
                .HasComment("معلومات إضافية بصيغة JSON - Additional metadata in JSON");

            builder.Property(x => x.LastErrorMessage)
                .IsRequired(false)
                .HasMaxLength(1000)
                .HasComment("رسالة الخطأ الأخيرة - Last error message");

            builder.Property(x => x.RebuildAttempts)
                .IsRequired()
                .HasDefaultValue(0)
                .HasComment("عدد محاولات إعادة البناء - Rebuild attempts count");

            builder.Property(x => x.CreatedAt)
                .IsRequired()
                .HasDefaultValueSql("NOW()")
                .HasComment("تاريخ الإنشاء - Creation timestamp");

            builder.Property(x => x.UpdatedAt)
                .IsRequired()
                .HasDefaultValueSql("NOW()")
                .HasComment("تاريخ آخر تعديل - Last update timestamp");

            // الفهارس للأداء - PostgreSQL partial indexes
            builder.HasIndex(x => x.Status)
                .HasDatabaseName("IX_IndexMetadata_Status")
                .HasFilter("\"Status\" = 'Active'");

            builder.HasIndex(x => x.LastUpdateTime)
                .HasDatabaseName("IX_IndexMetadata_LastUpdateTime");

            builder.HasIndex(x => new { x.Status, x.LastUpdateTime })
                .HasDatabaseName("IX_IndexMetadata_Status_LastUpdate")
                .HasFilter("\"Status\" = 'Active'");
            
            // Check constraints removed for PostgreSQL compatibility
        }
    }
}