using Microsoft.Extensions.DependencyInjection;

namespace WallpaperChanger.Services;

/// <summary>
/// Configures dependency injection for all application services.
/// </summary>
public static class ServiceConfiguration
{
    /// <summary>
    /// Configures and registers all services with the dependency injection container.
    /// </summary>
    /// <returns>A configured service provider.</returns>
    public static IServiceProvider ConfigureServices()
    {
        var services = new ServiceCollection();

        // Register core services as singletons (one instance for app lifetime)
        services.AddSingleton<IAppLogger, FileLogger>();
        services.AddSingleton<IValidationService, ValidationService>();
        services.AddSingleton<IConfigurationService, ConfigurationService>();
        services.AddSingleton<ICacheManager, CacheManager>();

        // Register business logic services
        services.AddSingleton<IWallpaperService, WallpaperService>();
        services.AddSingleton<ISchedulerService, SchedulerService>();

        // Register HTTP client services
        // ApiClient and ImageDownloader use HttpClient, so we register them with HttpClientFactory
        services.AddHttpClient<IApiClient, ApiClient>();
        services.AddHttpClient<IImageDownloader, ImageDownloader>();

        // Build and return the service provider
        var serviceProvider = services.BuildServiceProvider();

        // Initialize configuration on startup
        var configService = serviceProvider.GetRequiredService<IConfigurationService>();
        var logger = serviceProvider.GetRequiredService<IAppLogger>();

        try
        {
            // Load configuration asynchronously but wait for it to complete
            configService.LoadSettingsAsync().GetAwaiter().GetResult();
            logger.LogInfo("Services configured successfully");
        }
        catch (Exception ex)
        {
            logger.LogError("Failed to load configuration during startup", ex);
            // Continue with default settings
        }

        return serviceProvider;
    }

    /// <summary>
    /// Gets a service from the service provider.
    /// </summary>
    /// <typeparam name="T">The service type to retrieve.</typeparam>
    /// <param name="serviceProvider">The service provider.</param>
    /// <returns>The requested service instance.</returns>
    public static T GetService<T>(this IServiceProvider serviceProvider) where T : notnull
    {
        return serviceProvider.GetRequiredService<T>();
    }
}
