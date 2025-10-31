using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations
{
    /// <summary>
    /// تكوين كيان تفاعل الرسالة
    /// Configuration for MessageReaction entity
    /// </summary>
    public class MessageReactionConfiguration : IEntityTypeConfiguration<MessageReaction>
    {
        public void Configure(EntityTypeBuilder<MessageReaction> builder)
        {
            builder.ToTable("MessageReactions");

            builder.HasKey(r => r.Id);

            builder.Property(r => r.MessageId)
                .IsRequired()
                .HasComment("معرف الرسالة");

            builder.Property(r => r.UserId)
                .IsRequired()
                .HasComment("معرف المستخدم");

            builder.Property(r => r.ReactionType)
                .IsRequired()
                .HasMaxLength(20)
                .HasComment("نوع التفاعل");

            builder.Property(r => r.CreatedAt).IsRequired();
            builder.Property(r => r.UpdatedAt).IsRequired();

            // العلاقة مع الرسالة
            builder.HasOne<ChatMessage>()
                .WithMany(m => m.Reactions)
                .HasForeignKey(r => r.MessageId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
} 