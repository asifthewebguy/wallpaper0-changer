using System.Text.Json;
using WallpaperChanger.Exceptions;
using WallpaperChanger.Models;

namespace WallpaperChanger.Services;

/// <summary>
/// Service for managing application configuration with JSON persistence.
/// </summary>
public class ConfigurationService : IConfigurationService
{
    private readonly string _configFilePath;
    private readonly IAppLogger _logger;
    private AppSettings _settings;

    /// <summary>
    /// Initializes a new instance of the <see cref="ConfigurationService"/> class.
    /// </summary>
    /// <param name="logger">The logger instance.</param>
    public ConfigurationService(IAppLogger logger)
    {
        _logger = logger;
        _settings = GetDefaultSettings();

        string configDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "WallpaperChanger"
        );

        Directory.CreateDirectory(configDirectory);
        _configFilePath = Path.Combine(configDirectory, "appsettings.json");
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="ConfigurationService"/> class with a custom config path.
    /// </summary>
    /// <param name="logger">The logger instance.</param>
    /// <param name="configFilePath">The custom configuration file path.</param>
    protected ConfigurationService(IAppLogger logger, string configFilePath)
    {
        _logger = logger;
        _settings = GetDefaultSettings();
        _configFilePath = configFilePath;

        string? configDirectory = Path.GetDirectoryName(configFilePath);
        if (!string.IsNullOrEmpty(configDirectory))
        {
            Directory.CreateDirectory(configDirectory);
        }
    }

    /// <summary>
    /// Gets the current application settings.
    /// </summary>
    public AppSettings Settings => _settings;

    /// <summary>
    /// Saves the current settings to persistent storage.
    /// </summary>
    public async Task SaveSettingsAsync()
    {
        try
        {
            var options = new JsonSerializerOptions
            {
                WriteIndented = true
            };

            string json = JsonSerializer.Serialize(_settings, options);
            await File.WriteAllTextAsync(_configFilePath, json);

            _logger.LogInfo("Settings saved successfully", new Dictionary<string, object>
            {
                { "ConfigPath", _configFilePath }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError("Failed to save settings", ex);
            throw new WallpaperException(ErrorCode.ConfigurationError, "Failed to save application settings", ex);
        }
    }

    /// <summary>
    /// Loads settings from persistent storage.
    /// </summary>
    public async Task LoadSettingsAsync()
    {
        try
        {
            if (!File.Exists(_configFilePath))
            {
                _logger.LogInfo("Config file not found, using default settings");
                _settings = GetDefaultSettings();
                await SaveSettingsAsync();
                return;
            }

            string json = await File.ReadAllTextAsync(_configFilePath);
            var loadedSettings = JsonSerializer.Deserialize<AppSettings>(json);

            if (loadedSettings == null)
            {
                _logger.LogWarning("Failed to deserialize settings, using defaults");
                _settings = GetDefaultSettings();
                return;
            }

            // Validate loaded settings
            ValidateSettings(loadedSettings);
            _settings = loadedSettings;

            _logger.LogInfo("Settings loaded successfully");
        }
        catch (JsonException ex)
        {
            _logger.LogError("Invalid JSON in config file, using defaults", ex);
            _settings = GetDefaultSettings();
            await SaveSettingsAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError("Failed to load settings", ex);
            throw new WallpaperException(ErrorCode.ConfigurationError, "Failed to load application settings", ex);
        }
    }

    private static AppSettings GetDefaultSettings()
    {
        return new AppSettings
        {
            CacheDirectory = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "WallpaperChanger",
                "Cache"
            ),
            MaxCacheSizeMb = 500,
            StartWithWindows = false,
            ShowNotifications = true,
            DownloadTimeoutSeconds = 60,
            MaxRetries = 3,
            ApiTimeoutSeconds = 30
        };
    }

    private void ValidateSettings(AppSettings settings)
    {
        // Validate and fix invalid values
        if (settings.MaxCacheSizeMb < 10)
        {
            _logger.LogWarning("MaxCacheSizeMb too small, setting to default (500 MB)");
            settings.MaxCacheSizeMb = 500;
        }

        if (settings.DownloadTimeoutSeconds < 10 || settings.DownloadTimeoutSeconds > 300)
        {
            _logger.LogWarning("DownloadTimeoutSeconds out of range, setting to default (60s)");
            settings.DownloadTimeoutSeconds = 60;
        }

        if (settings.ApiTimeoutSeconds < 5 || settings.ApiTimeoutSeconds > 120)
        {
            _logger.LogWarning("ApiTimeoutSeconds out of range, setting to default (30s)");
            settings.ApiTimeoutSeconds = 30;
        }

        if (settings.MaxRetries < 0 || settings.MaxRetries > 10)
        {
            _logger.LogWarning("MaxRetries out of range, setting to default (3)");
            settings.MaxRetries = 3;
        }

        if (string.IsNullOrWhiteSpace(settings.CacheDirectory))
        {
            _logger.LogWarning("CacheDirectory empty, setting to default");
            settings.CacheDirectory = GetDefaultSettings().CacheDirectory;
        }
    }
}
