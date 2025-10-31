namespace YemenBooking.Core.Interfaces
{
    using System.Threading.Tasks;

    /// <summary>
    /// واجهة معالج أحداث مجال
    /// </summary>
    public interface IDomainEventHandler<TEvent>
    {
        Task Handle(TEvent domainEvent);
    }
} 