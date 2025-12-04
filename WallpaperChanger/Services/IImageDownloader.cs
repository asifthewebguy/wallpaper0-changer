using WallpaperChanger.Models;

namespace WallpaperChanger.Services;

/// <summary>
/// Interface for downloading images from URLs.
/// </summary>
public interface IImageDownloader
{
    /// <summary>
    /// Downloads an image from a URL and saves it to the cache.
    /// </summary>
    /// <param name="imageUrl">The URL of the image to download.</param>
    /// <param name="imageId">The image ID for cache naming.</param>
    /// <param name="progress">Progress reporter for download progress.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The local file path where the image was saved.</returns>
    Task<string> DownloadImageAsync(
        string imageUrl,
        string imageId,
        IProgress<DownloadProgress>? progress = null,
        CancellationToken cancellationToken = default);
}
