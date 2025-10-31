using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations
{
    /// <summary>
    /// تكوين كيان سجل البحث
    /// Configuration for SearchLog entity
    /// </summary>
    public class SearchLogConfiguration : IEntityTypeConfiguration<SearchLog>
    {
        public void Configure(EntityTypeBuilder<SearchLog> builder)
        {
            builder.ToTable("SearchLogs");
            builder.HasKey(sl => sl.Id);
            builder.Property(sl => sl.UserId).IsRequired();
            builder.Property(sl => sl.SearchType).HasMaxLength(50).IsRequired();
            builder.Property(sl => sl.CriteriaJson).IsRequired();
            builder.Property(sl => sl.ResultCount).IsRequired();
            builder.Property(sl => sl.PageNumber).IsRequired();
            builder.Property(sl => sl.PageSize).IsRequired();
        }
    }
} 