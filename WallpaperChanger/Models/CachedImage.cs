namespace WallpaperChanger.Models;

/// <summary>
/// Represents a cached image file.
/// </summary>
public class CachedImage
{
    /// <summary>
    /// Gets or sets the image ID.
    /// </summary>
    public string ImageId { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the full file path to the cached image.
    /// </summary>
    public string FilePath { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the date and time when the image was cached.
    /// </summary>
    public DateTime CachedAt { get; set; }

    /// <summary>
    /// Gets or sets the file size in bytes.
    /// </summary>
    public long FileSize { get; set; }

    /// <summary>
    /// Gets or sets the last access time for LRU cache management.
    /// </summary>
    public DateTime LastAccessTime { get; set; }
}
