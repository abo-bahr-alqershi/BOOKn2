using System;
using System.Linq;
using System.Reflection;
using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Core.Interfaces.Events;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.Sections.Services;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Infrastructure.Repositories;
using YemenBooking.Infrastructure.Services;
using YemenBooking.Infrastructure.UnitOfWork;
using YemenBooking.Core.Interfaces;
using FluentValidation;
using MediatR;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Infrastructure.Persistence.Repositories;

namespace YemenBooking.Api.Extensions
{
    /// <summary>
    /// امتدادات حقن التبعيات لمشروع YemenBooking
    /// </summary>
    public static class ServiceCollectionExtensions
    {
        /// <summary>
        /// يضيف كافة التبعيات: مستودعات البيانات، خدمات البنية التحتية، ومعالجات أحداث المجال
        /// </summary>
        public static IServiceCollection AddYemenBookingServices(this IServiceCollection services)
        {
            // تسجيل وحدة العمل
            services.AddScoped<IUnitOfWork, UnitOfWork>();

            services.AddScoped(typeof(IRepository<>), typeof(BaseRepository<>));  // Register generic repository for all entities

            // تسجيل المستودعات
            RegisterRepositories(services);

            // تسجيل خدمات البنية التحتية
            RegisterInfrastructureServices(services);
            
            // Register media metadata service only (thumbnail generation handled in client)
            services.AddScoped<IMediaMetadataService, MediaMetadataService>();
            // Configure FFMpegCore global options (optional: set custom binaries path from env)
            // Remove ffmpeg binaries configuration as server-side thumbnailing is disabled
            // Register currency ensure service
            services.AddScoped<ICurrencyEnsureService, CurrencyEnsureService>();
            services.AddScoped<ISectionService, SectionService>();
            services.AddScoped<ISectionContentService, SectionContentService>();
            
            // Register Financial Accounting Services
            services.AddScoped<IFinancialAccountingService, FinancialAccountingService>();
            services.AddScoped<IChartOfAccountRepository, ChartOfAccountRepository>();
            services.AddScoped<IFinancialTransactionRepository, FinancialTransactionRepository>();

            // Explicitly map interfaces that don't follow the "I" + ImplementationName convention
            // IEventPublisher is implemented by EventPublisherService (not IEventPublisherService)
            services.AddScoped<IEventPublisher, EventPublisherService>();
            
            // Register FluentValidation validators from Application assembly
            RegisterValidators(services);
            
            return services;
        }

        /// <summary>
        /// يبحث ويسجل جميع الأصناف المنتهية بـ Repository كواجهاتها المطابقة
        /// </summary>
        private static void RegisterRepositories(IServiceCollection services)
        {
            var repoAssembly = Assembly.GetAssembly(typeof(BookingRepository));
            var repoTypes = repoAssembly != null
                ? repoAssembly.GetTypes().Where(t => t.IsClass && !t.IsAbstract && t.Name.EndsWith("Repository"))
                : Enumerable.Empty<Type>();

            foreach (var impl in repoTypes)
            {
                var iface = impl.GetInterfaces()
                    .FirstOrDefault(i => i.Name == "I" + impl.Name);
                if (iface != null)
                {
                    services.AddScoped(iface, impl);
                }
            }
        }

        /// <summary>
        /// يبحث ويسجل جميع الأصناف المنتهية بـ Service كواجهاتها المطابقة
        /// </summary>
        private static void RegisterInfrastructureServices(IServiceCollection services)
        {
            var svcAssembly = Assembly.GetAssembly(typeof(FileStorageService));
            var svcTypes = svcAssembly != null
                ? svcAssembly.GetTypes().Where(t => t.IsClass && !t.IsAbstract && t.Name.EndsWith("Service"))
                : Enumerable.Empty<Type>();

            foreach (var impl in svcTypes)
            {
                var iface = impl.GetInterfaces()
                    .FirstOrDefault(i => i.Name == "I" + impl.Name);
                if (iface != null)
                {
                    services.AddScoped(iface, impl);
                }
            }
            services.AddScoped<IPropertyImageRepository, PropertyImageRepository>();
            services.AddScoped<ISectionImageRepository, SectionImageRepository>();
            services.AddScoped<IPropertyInSectionImageRepository, PropertyInSectionImageRepository>();
            services.AddScoped<IUnitInSectionImageRepository, UnitInSectionImageRepository>();
            services.AddScoped<IUnitRepository, UnitRepository>();
            
            // تسجيل UrlHelper (يستخدم IUrlHelper من YemenBooking.Application.Common.Interfaces)
            services.AddScoped<IUrlHelper, YemenBooking.Infrastructure.Services.UrlHelper>();

            // FIX: Explicitly register WebSocketConnectionManager because it does not end with "Service" but
            // is a constructor dependency of WebSocketService which the reflection scan registers.
            // Using singleton lifetime so all WebSocket operations share the same connection map.
            services.AddSingleton<WebSocketConnectionManager>();
        }

        /// <summary>
        /// Registers all FluentValidation validators from the Application assembly
        /// </summary>
        private static void RegisterValidators(IServiceCollection services)
        {
            // Leverage a known type from the Application assembly to get its Assembly
            var appAssembly = Assembly.GetAssembly(typeof(ICurrentUserService));
            if (appAssembly == null)
            {
                return;
            }

            var registrations = appAssembly
                .GetTypes()
                .Where(t => t.IsClass && !t.IsAbstract)
                .SelectMany(t => t.GetInterfaces()
                    .Where(i => i.IsGenericType && i.GetGenericTypeDefinition() == typeof(FluentValidation.IValidator<>))
                    .Select(i => new { Service = i, Implementation = t }))
                .ToList();

            foreach (var reg in registrations)
            {
                services.AddScoped(reg.Service, reg.Implementation);
            }
        }
    }
}