using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations
{
    /// <summary>
    /// تكوين كيان مرفق المحادثة
    /// Configuration for ChatAttachment entity
    /// </summary>
    public class ChatAttachmentConfiguration : IEntityTypeConfiguration<ChatAttachment>
    {
        public void Configure(EntityTypeBuilder<ChatAttachment> builder)
        {
            builder.ToTable("ChatAttachments");

            builder.HasKey(a => a.Id);

            builder.Property(a => a.ConversationId)
                .IsRequired()
                .HasComment("معرف المحادثة");

            builder.Property(a => a.FileName)
                .IsRequired()
                .HasMaxLength(200)
                .HasComment("اسم الملف الأصلي");

            builder.Property(a => a.ContentType)
                .IsRequired()
                .HasMaxLength(100)
                .HasComment("نوع المحتوى");

            builder.Property(a => a.FileSize)
                .IsRequired()
                .HasComment("حجم الملف بالبايت");

            builder.Property(a => a.FilePath)
                .IsRequired()
                .HasMaxLength(500)
                .HasComment("مسار الملف على الخادم");

            // New optional fields
            builder.Property(a => a.ThumbnailUrl)
                .HasMaxLength(500)
                .HasComment("URL of the thumbnail image (optional)");

            builder.Property(a => a.Metadata)
                .HasColumnType("text")
                .HasComment("Additional metadata as JSON string (optional)");

            builder.Property(a => a.DurationSeconds)
                .HasComment("Attachment duration in seconds (audio/video)");

            builder.Property(a => a.UploadedBy)
                .IsRequired()
                .HasComment("المستخدم الذي رفع الملف");

            builder.Property(a => a.CreatedAt).IsRequired();

            // العلاقة مع المحادثة
            builder.HasOne<ChatConversation>()
                .WithMany(c => c.Attachments)
                .HasForeignKey(a => a.ConversationId)
                .OnDelete(DeleteBehavior.Cascade);

            // العلاقة الاختيارية مع الرسالة
            builder.HasOne(a => a.Message)
                .WithMany(m => m.Attachments)
                .HasForeignKey(a => a.MessageId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}