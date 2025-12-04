namespace WallpaperChanger.Models;

/// <summary>
/// Application settings that can be persisted and loaded.
/// </summary>
public class AppSettings
{
    /// <summary>
    /// Gets or sets the cache directory path.
    /// </summary>
    public string CacheDirectory { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the maximum cache size in megabytes.
    /// </summary>
    public long MaxCacheSizeMb { get; set; } = 500;

    /// <summary>
    /// Gets or sets a value indicating whether the application should start with Windows.
    /// </summary>
    public bool StartWithWindows { get; set; } = false;

    /// <summary>
    /// Gets or sets a value indicating whether to show balloon notifications.
    /// </summary>
    public bool ShowNotifications { get; set; } = true;

    /// <summary>
    /// Gets or sets the download timeout in seconds.
    /// </summary>
    public int DownloadTimeoutSeconds { get; set; } = 60;

    /// <summary>
    /// Gets or sets the maximum number of retry attempts for failed operations.
    /// </summary>
    public int MaxRetries { get; set; } = 3;

    /// <summary>
    /// Gets or sets the API timeout in seconds.
    /// </summary>
    public int ApiTimeoutSeconds { get; set; } = 30;
}
