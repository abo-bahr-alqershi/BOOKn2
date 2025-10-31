using FluentValidation;
using YemenBooking.Application.Features.Payments;
using YemenBooking.Application.Features.Bookings;
using YemenBooking.Application.Features.Services;
using YemenBooking.Application.Features.Bookings.Commands.CreateBooking;

namespace YemenBooking.Application.Validators
{
    internal static class DecimalRules
    {
        public static bool HasMaxTwoDecimals(decimal value) => decimal.Round(value, 2) == value;
    }

    public class RegisterBookingPaymentCommandValidator : AbstractValidator<YemenBooking.Application.Features.Payments.Commands.RegisterBookingPayment.RegisterBookingPaymentCommand>
    {
        public RegisterBookingPaymentCommandValidator()
        {
            RuleFor(x => x.BookingId).NotEmpty();
            RuleFor(x => x.Amount).NotNull();
            RuleFor(x => x.Amount.Amount)
                .GreaterThan(0)
                .Must(DecimalRules.HasMaxTwoDecimals)
                .WithMessage("Amount must have at most 2 decimal places");
            RuleFor(x => x.Amount.Currency)
                .NotEmpty()
                .Length(3, 3);
            RuleFor(x => x.PaymentMethod)
                .IsInEnum();
        }
    }

    public class ProcessPaymentCommandValidator : AbstractValidator<YemenBooking.Application.Features.Payments.Commands.ProcessPayment.ProcessPaymentCommand>
    {
        public ProcessPaymentCommandValidator()
        {
            RuleFor(x => x.BookingId).NotEmpty();
            RuleFor(x => x.Amount).NotNull();
            RuleFor(x => x.Amount.Amount)
                .GreaterThan(0)
                .Must(DecimalRules.HasMaxTwoDecimals)
                .WithMessage("Amount must have at most 2 decimal places");
            RuleFor(x => x.Amount.Currency)
                .NotEmpty()
                .Length(3, 3);
            RuleFor(x => x.PaymentMethod).IsInEnum();
        }
    }

    public class RefundPaymentCommandValidator : AbstractValidator<YemenBooking.Application.Features.Payments.Commands.RefundPayment.RefundPaymentCommand>
    {
        public RefundPaymentCommandValidator()
        {
            RuleFor(x => x.PaymentId).NotEmpty();
            RuleFor(x => x.RefundAmount).NotNull();
            RuleFor(x => x.RefundAmount.Amount)
                .GreaterThan(0)
                .Must(DecimalRules.HasMaxTwoDecimals)
                .WithMessage("Amount must have at most 2 decimal places");
            RuleFor(x => x.RefundAmount.Currency)
                .NotEmpty()
                .Length(3, 3);
            RuleFor(x => x.RefundReason)
                .NotEmpty();
        }
    }

    public class VoidPaymentCommandValidator : AbstractValidator<YemenBooking.Application.Features.Payments.Commands.VoidPayment.VoidPaymentCommand>
    {
        public VoidPaymentCommandValidator()
        {
            RuleFor(x => x.PaymentId).NotEmpty();
        }
    }

    public class UpdatePaymentStatusCommandValidator : AbstractValidator<YemenBooking.Application.Features.Payments.Commands.PaymentStatus.UpdatePaymentStatusCommand>
    {
        public UpdatePaymentStatusCommandValidator()
        {
            RuleFor(x => x.PaymentId).NotEmpty();
            RuleFor(x => x.NewStatus).IsInEnum();
        }
    }

    public class AddServiceToBookingCommandValidator : AbstractValidator<YemenBooking.Application.Features.Bookings.Commands.AddServices.AddServicesToBookingCommand>
    {
        public AddServiceToBookingCommandValidator()
        {
            RuleFor(x => x.BookingId).NotEmpty();
            RuleFor(x => x.ServiceId).NotEmpty();
            RuleFor(x => x.Quantity).GreaterThan(0);
        }
    }

    public class CreatePropertyServiceCommandValidator : AbstractValidator<YemenBooking.Application.Features.Services.Commands.CreateProperty.CreatePropertyServiceCommand>
    {
        public CreatePropertyServiceCommandValidator()
        {
            RuleFor(x => x.PropertyId).NotEmpty();
            RuleFor(x => x.Name).NotEmpty();
            RuleFor(x => x.Price).NotNull();
            RuleFor(x => x.Price.Amount)
                .GreaterThanOrEqualTo(0)
                .Must(DecimalRules.HasMaxTwoDecimals)
                .WithMessage("Price must have at most 2 decimal places");
            RuleFor(x => x.Price.Currency)
                .NotEmpty()
                .Length(3, 3);
        }
    }

    public class CreateBookingCommandValidator : AbstractValidator<CreateBookingCommand>
    {
        public CreateBookingCommandValidator()
        {
            RuleFor(x => x.UserId).NotEmpty();
            RuleFor(x => x.UnitId).NotEmpty();
            RuleFor(x => x.CheckIn).NotEmpty();
            RuleFor(x => x.CheckOut).NotEmpty();
            RuleFor(x => x).Must(x => x.CheckIn < x.CheckOut)
                .WithMessage("Check-out must be after check-in");
            RuleFor(x => x.GuestsCount).GreaterThan(0);
        }
    }
}
