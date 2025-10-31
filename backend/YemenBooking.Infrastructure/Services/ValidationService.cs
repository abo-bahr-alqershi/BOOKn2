using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Reflection;
using FluentValidation;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.RegularExpressions;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة التحقق من صحة البيانات باستخدام FluentValidation
    /// </summary>
    public class ValidationService : IValidationService
    {
        private readonly IServiceProvider _serviceProvider;

        public ValidationService(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        public Task<ValidationResult> ValidateBookingAsync(object bookingData, CancellationToken cancellationToken = default)
            => ValidateAsyncCore(bookingData, cancellationToken);

        public Task<ValidationResult> ValidateUnitAsync(object unitData, CancellationToken cancellationToken = default)
            => ValidateAsyncCore(unitData, cancellationToken);

        public Task<ValidationResult> ValidateUserAsync(object userData, CancellationToken cancellationToken = default)
            => ValidateAsyncCore(userData, cancellationToken);

        public Task<ValidationResult> ValidatePropertyAsync(object propertyData, CancellationToken cancellationToken = default)
            => ValidateAsyncCore(propertyData, cancellationToken);

        public Task<ValidationResult> ValidatePaymentAsync(object paymentData, CancellationToken cancellationToken = default)
            => ValidateAsyncCore(paymentData, cancellationToken);

        private async Task<ValidationResult> ValidateAsyncCore(object data, CancellationToken cancellationToken)
        {
            if (data == null)
            {
                return ValidationResult.Failure("البيانات غير موجودة", "DataNull");
            }
            var dataType = data.GetType();
            var validatorType = typeof(IValidator<>).MakeGenericType(dataType);
            dynamic? validator = _serviceProvider.GetService(validatorType);
            if (validator != null)
            {
                var result = await validator.ValidateAsync((dynamic)data, cancellationToken);
                return MapValidationResult(result);
            }
            return ValidationResult.Success();
        }

        public Task<bool> IsValidEmailAsync(string email, CancellationToken cancellationToken = default)
        {
            var isValid = !string.IsNullOrWhiteSpace(email) &&
                          Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$");
            return Task.FromResult(isValid);
        }

        public Task<bool> IsValidPhoneAsync(string phone, string? countryCode = null, CancellationToken cancellationToken = default)
        {
            var isValid = !string.IsNullOrWhiteSpace(phone) &&
                          Regex.IsMatch(phone, @"^\d{7,15}$");
            return Task.FromResult(isValid);
        }

        public Task<PasswordValidationResult> ValidatePasswordAsync(string password, CancellationToken cancellationToken = default)
        {
            var result = new PasswordValidationResult();
            if (string.IsNullOrEmpty(password))
            {
                result.IsValid = false;
                result.Score = 0;
                result.Strength = PasswordStrength.VERY_WEAK;
                result.Requirements.Add("كلمة المرور لا يمكن أن تكون فارغة");
            }
            else
            {
                var score = password.Length * 5;
                if (Regex.IsMatch(password, "[A-Z]")) score += 10;
                if (Regex.IsMatch(password, "[a-z]")) score += 10;
                if (Regex.IsMatch(password, "[0-9]")) score += 10;
                if (Regex.IsMatch(password, "[^a-zA-Z0-9]")) score += 10;
                score = Math.Min(100, score);
                result.Score = score;
                result.IsValid = score >= 50;
                result.Strength = score switch
                {
                    <= 20 => PasswordStrength.VERY_WEAK,
                    <= 40 => PasswordStrength.WEAK,
                    <= 60 => PasswordStrength.FAIR,
                    <= 80 => PasswordStrength.GOOD,
                    _ => PasswordStrength.EXCELLENT
                };
                if (password.Length < 8)
                    result.Requirements.Add("كلمة المرور يجب أن تكون 8 أحرف على الأقل");
            }
            return Task.FromResult(result);
        }

        public Task<bool> IsValidNationalIdAsync(string nationalId, string? country = null, CancellationToken cancellationToken = default)
        {
            var isValid = !string.IsNullOrWhiteSpace(nationalId) &&
                          nationalId.Length >= 6 && nationalId.Length <= 20;
            return Task.FromResult(isValid);
        }

        private ValidationResult MapValidationResult(FluentValidation.Results.ValidationResult result)
        {
            var vr = new ValidationResult
            {
                IsValid = result.IsValid,
                Errors = result.Errors.Select(e => new ValidationError
                {
                    Code = e.ErrorCode ?? string.Empty,
                    Message = e.ErrorMessage,
                    Field = e.PropertyName,
                    Value = e.AttemptedValue
                }).ToList()
            };
            return vr;
        }
    }
} 