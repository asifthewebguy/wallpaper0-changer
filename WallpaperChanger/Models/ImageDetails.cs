namespace WallpaperChanger.Models;

/// <summary>
/// Represents details about an image from the API.
/// </summary>
public class ImageDetails
{
    /// <summary>
    /// Gets or sets the unique identifier for the image.
    /// </summary>
    public string ImageId { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the full URL to the image.
    /// </summary>
    public string ImageUrl { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the URL to the thumbnail image.
    /// </summary>
    public string ThumbnailUrl { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the file size in bytes.
    /// </summary>
    public long FileSize { get; set; }

    /// <summary>
    /// Gets or sets the image format (e.g., jpg, png).
    /// </summary>
    public string Format { get; set; } = string.Empty;
}
