using WallpaperChanger.Models;

namespace WallpaperChanger.Services;

/// <summary>
/// Interface for the main wallpaper service that orchestrates all operations.
/// </summary>
public interface IWallpaperService
{
    /// <summary>
    /// Sets the desktop wallpaper from an image ID.
    /// </summary>
    /// <param name="imageId">The image ID to set as wallpaper.</param>
    /// <param name="progress">Progress reporter for download progress.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>True if the wallpaper was set successfully; otherwise, false.</returns>
    Task<bool> SetWallpaperFromIdAsync(
        string imageId,
        IProgress<DownloadProgress>? progress = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Sets the desktop wallpaper from a local file path.
    /// </summary>
    /// <param name="imagePath">The local file path to the image.</param>
    /// <returns>True if the wallpaper was set successfully; otherwise, false.</returns>
    bool SetWallpaper(string imagePath);
}
