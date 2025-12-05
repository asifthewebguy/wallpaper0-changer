using WallpaperChanger.Models;

namespace WallpaperChanger.Services;

/// <summary>
/// Interface for communicating with the wallpaper API.
/// </summary>
public interface IApiClient
{
    /// <summary>
    /// Gets image details from the API.
    /// </summary>
    /// <param name="imageId">The image ID to retrieve details for.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The image details.</returns>
    Task<ImageDetails> GetImageDetailsAsync(string imageId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets a random image ID from the API.
    /// </summary>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A random image ID string.</returns>
    Task<string> GetRandomImageIdAsync(CancellationToken cancellationToken = default);
}
