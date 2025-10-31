using Microsoft.AspNetCore.Mvc.ModelBinding;
using System;
using System.Globalization;
using System.Threading.Tasks;

namespace YemenBooking.Api.Infrastructure.ModelBinders
{
    /// <summary>
    /// Model binder that automatically converts DateTime parameters to UTC
    /// to ensure PostgreSQL compatibility
    /// </summary>
    public class UtcDateTimeModelBinder : IModelBinder
    {
        public Task BindModelAsync(ModelBindingContext bindingContext)
        {
            if (bindingContext == null)
                throw new ArgumentNullException(nameof(bindingContext));

            var modelName = bindingContext.ModelName;
            var valueProviderResult = bindingContext.ValueProvider.GetValue(modelName);

            if (valueProviderResult == ValueProviderResult.None)
                return Task.CompletedTask;

            bindingContext.ModelState.SetModelValue(modelName, valueProviderResult);

            var value = valueProviderResult.FirstValue;
            
            // Handle nullable DateTime
            if (string.IsNullOrEmpty(value))
            {
                if (bindingContext.ModelType == typeof(DateTime?))
                {
                    bindingContext.Result = ModelBindingResult.Success(null);
                }
                return Task.CompletedTask;
            }

            // Try to parse the DateTime
            if (DateTime.TryParse(value, CultureInfo.InvariantCulture, 
                DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal, 
                out var dateTime))
            {
                // Ensure the DateTime is UTC
                var utcDateTime = DateTime.SpecifyKind(dateTime, DateTimeKind.Utc);
                bindingContext.Result = ModelBindingResult.Success(utcDateTime);
            }
            else
            {
                bindingContext.ModelState.TryAddModelError(
                    modelName,
                    $"The value '{value}' is not valid for {modelName}.");
            }

            return Task.CompletedTask;
        }
    }

    /// <summary>
    /// Provider for UtcDateTimeModelBinder
    /// </summary>
    public class UtcDateTimeModelBinderProvider : IModelBinderProvider
    {
        public IModelBinder? GetBinder(ModelBinderProviderContext context)
        {
            if (context == null)
                throw new ArgumentNullException(nameof(context));

            if (context.Metadata.ModelType == typeof(DateTime) || 
                context.Metadata.ModelType == typeof(DateTime?))
            {
                return new UtcDateTimeModelBinder();
            }

            return null;
        }
    }
}
