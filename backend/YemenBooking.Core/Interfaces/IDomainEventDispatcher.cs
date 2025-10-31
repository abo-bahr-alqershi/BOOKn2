using System.Threading.Tasks;

namespace YemenBooking.Core.Interfaces
{
    public interface IDomainEventDispatcher
    {
        void AddEvent(IDomainEvent @event);
        Task DispatchAsync();
    }
}
