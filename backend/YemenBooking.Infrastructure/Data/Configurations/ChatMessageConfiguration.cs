using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations
{
    /// <summary>
    /// تكوين كيان رسالة المحادثة
    /// Configuration for ChatMessage entity
    /// </summary>
    public class ChatMessageConfiguration : IEntityTypeConfiguration<ChatMessage>
    {
        public void Configure(EntityTypeBuilder<ChatMessage> builder)
        {
            builder.ToTable("ChatMessages");

            builder.HasKey(cm => cm.Id);

            builder.Property(cm => cm.ConversationId)
                .IsRequired()
                .HasComment("معرف المحادثة");

            builder.Property(cm => cm.SenderId)
                .IsRequired()
                .HasComment("معرف المستخدم المرسل");

            builder.Property(cm => cm.MessageType)
                .IsRequired()
                .HasMaxLength(20)
                .HasComment("نوع الرسالة");

            builder.Property(cm => cm.Content)
                .HasMaxLength(2000)
                .HasComment("محتوى الرسالة");

            builder.Property(cm => cm.LocationJson)
                .HasColumnName("Location")
                .HasComment("بيانات الموقع بصيغة JSON");

            builder.Property(cm => cm.ReplyToMessageId)
                .HasComment("معرف الرسالة المرد عليها");

            builder.Property(cm => cm.CreatedAt).IsRequired();
            builder.Property(cm => cm.UpdatedAt).IsRequired();

            // العلاقات
            builder.HasOne<ChatConversation>()
                .WithMany(c => c.Messages)
                .HasForeignKey(cm => cm.ConversationId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasMany(cm => cm.Reactions)
                .WithOne()
                .HasForeignKey(r => r.MessageId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
} 