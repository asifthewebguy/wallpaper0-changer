using WallpaperChanger.Models;

namespace WallpaperChanger.Services;

/// <summary>
/// Interface for managing application configuration.
/// </summary>
public interface IConfigurationService
{
    /// <summary>
    /// Gets the current application settings.
    /// </summary>
    AppSettings Settings { get; }

    /// <summary>
    /// Saves the current settings to persistent storage.
    /// </summary>
    /// <returns>A task representing the asynchronous operation.</returns>
    Task SaveSettingsAsync();

    /// <summary>
    /// Loads settings from persistent storage.
    /// </summary>
    /// <returns>A task representing the asynchronous operation.</returns>
    Task LoadSettingsAsync();
}
