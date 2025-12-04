using WallpaperChanger.Models;

namespace WallpaperChanger.Services;

/// <summary>
/// Interface for managing cached wallpaper images.
/// </summary>
public interface ICacheManager
{
    /// <summary>
    /// Gets the cached image path for a given image ID.
    /// </summary>
    /// <param name="imageId">The image ID.</param>
    /// <param name="extension">The file extension (e.g., .jpg).</param>
    /// <returns>The full path to the cached image.</returns>
    string GetCachedImagePath(string imageId, string extension);

    /// <summary>
    /// Checks if an image is already cached.
    /// </summary>
    /// <param name="imageId">The image ID to check.</param>
    /// <returns>True if the image is cached; otherwise, false.</returns>
    bool IsCached(string imageId);

    /// <summary>
    /// Updates the access time for a cached image (for LRU tracking).
    /// </summary>
    /// <param name="imageId">The image ID.</param>
    void UpdateAccessTime(string imageId);

    /// <summary>
    /// Cleans up the cache to stay within the size limit using LRU eviction.
    /// </summary>
    /// <param name="maxSizeBytes">The maximum cache size in bytes.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    Task CleanupCacheAsync(long maxSizeBytes);

    /// <summary>
    /// Gets the cache history with metadata.
    /// </summary>
    /// <returns>A list of cached images with metadata.</returns>
    Task<List<CachedImage>> GetCacheHistoryAsync();

    /// <summary>
    /// Gets the total cache size in bytes.
    /// </summary>
    /// <returns>The total size of all cached files.</returns>
    long GetCacheSize();

    /// <summary>
    /// Clears all cached images.
    /// </summary>
    /// <returns>A task representing the asynchronous operation.</returns>
    Task ClearCacheAsync();
}
