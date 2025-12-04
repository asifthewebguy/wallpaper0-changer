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
}
