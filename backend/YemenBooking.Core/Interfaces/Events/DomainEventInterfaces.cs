using System;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Core.Interfaces.Events
{
    #region Property Image Events
    public interface IPropertyImageAssignedToUnitEvent : IDomainEvent { }
    public interface IPropertyImageAssignedToPropertyEvent : IDomainEvent { }
    public interface IPropertyImageCreatedEvent : IDomainEvent { }
    public interface IPropertyImageDeletedEvent : IDomainEvent { }
    public interface IPropertyImageUpdatedEvent : IDomainEvent { }
    #endregion

    #region Payment Events
    public interface IPaymentProcessedEvent : IDomainEvent { }
    public interface IPaymentRefundedEvent : IDomainEvent { }
    public interface IPaymentStatusUpdatedEvent : IDomainEvent { }
    public interface IPaymentFailedEvent : IDomainEvent { }
    #endregion

    #region Booking Events
    public interface IBookingCreatedEvent : IDomainEvent { }
    public interface IBookingCancelledEvent : IDomainEvent { }
    public interface IBookingConfirmedEvent : IDomainEvent { }
    public interface IBookingCompletedEvent : IDomainEvent { }
    public interface IBookingCheckedInEvent : IDomainEvent { }
    public interface IBookingCheckedOutEvent : IDomainEvent { }
    public interface IBookingUpdatedEvent : IDomainEvent { }
    #endregion

    #region Unit and Dynamic Field Events
    public interface IUnitCreatedEvent : IDomainEvent { }
    public interface IUnitUpdatedEvent : IDomainEvent { }
    public interface IUnitDeletedEvent : IDomainEvent { }
    public interface IUnitAvailabilityUpdatedEvent : IDomainEvent { }
    
    public interface IUnitTypeFieldCreatedEvent : IDomainEvent { }
    public interface IUnitTypeFieldUpdatedEvent : IDomainEvent { }
    public interface IUnitTypeFieldDeletedEvent : IDomainEvent { }
    public interface IUnitFieldValueUpdatedEvent : IDomainEvent { }
    #endregion
} 