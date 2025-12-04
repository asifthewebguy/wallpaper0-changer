namespace WallpaperChanger.Models;

/// <summary>
/// Represents the download progress of an image.
/// </summary>
public class DownloadProgress
{
    /// <summary>
    /// Gets or sets the number of bytes received so far.
    /// </summary>
    public long BytesReceived { get; set; }

    /// <summary>
    /// Gets or sets the total number of bytes to receive.
    /// </summary>
    public long TotalBytes { get; set; }

    /// <summary>
    /// Gets the download progress as a percentage (0-100).
    /// </summary>
    public int ProgressPercentage => TotalBytes > 0 ? (int)((BytesReceived * 100) / TotalBytes) : 0;

    /// <summary>
    /// Gets a value indicating whether the download is complete.
    /// </summary>
    public bool IsComplete => BytesReceived >= TotalBytes && TotalBytes > 0;
}
