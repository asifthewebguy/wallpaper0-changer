using System.Text.RegularExpressions;

namespace WallpaperChanger.Services;

/// <summary>
/// Interface for validating user input and system data to prevent security vulnerabilities.
/// </summary>
public interface IValidationService
{
    /// <summary>
    /// Validates whether an image ID is in the correct format.
    /// </summary>
    /// <param name="imageId">The image ID to validate.</param>
    /// <returns>True if the image ID is valid; otherwise, false.</returns>
    bool IsValidImageId(string imageId);

    /// <summary>
    /// Validates whether an image URL is from an allowed domain.
    /// </summary>
    /// <param name="url">The URL to validate.</param>
    /// <returns>True if the URL is valid; otherwise, false.</returns>
    bool IsValidImageUrl(string url);

    /// <summary>
    /// Validates whether a file path is safe and doesn't contain path traversal attempts.
    /// </summary>
    /// <param name="path">The file path to validate.</param>
    /// <returns>True if the path is valid; otherwise, false.</returns>
    bool IsValidFilePath(string path);

    /// <summary>
    /// Gets the maximum allowed image size in bytes.
    /// </summary>
    long MaxImageSize { get; }
}
