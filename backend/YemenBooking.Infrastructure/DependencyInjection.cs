using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Application.Features.Payments.Services;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Infrastructure.Services;
using YemenBooking.Infrastructure.Settings;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure;

/// <summary>
/// إعداد حقن التبعيات للبنية التحتية
/// Infrastructure dependency injection setup
/// </summary>
public static class DependencyInjection
{
	/// <summary>
	/// إضافة خدمات البنية التحتية
	/// Add infrastructure services
	/// </summary>
	public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
	{
        // Email settings configuration
        services.Configure<EmailSettings>(configuration.GetSection("EmailSettings"));

        // إضافة خدمات أخرى
		services.AddHttpClient<ICurrencyExchangeService, CurrencyExchangeService>();
		services.AddScoped<ICurrencySettingsService, CurrencySettingsService>();
		services.AddScoped<ICitySettingsService, CitySettingsService>();
        services.AddScoped<IEmailService, EmailService>();
		services.AddScoped<IEmailVerificationService, EmailVerificationService>();
		services.AddScoped<IFileUploadService, FileUploadService>();
		services.AddScoped<IPasswordResetService, PasswordResetService>();
		services.AddScoped<IPaymentService, PaymentService>();
		
		// Availability services
		services.AddScoped<IAvailabilityService, AvailabilityService>();
		services.AddScoped<IAvailabilityConflictService, AvailabilityConflictService>();

		return services;
	}
}