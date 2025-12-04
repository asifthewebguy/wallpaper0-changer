using System.Text.RegularExpressions;

namespace WallpaperChanger.Services;

/// <summary>
/// Service for validating user input and system data to prevent security vulnerabilities.
/// </summary>
/// <remarks>
/// This service provides validation for image IDs, URLs, and file paths
/// to prevent security vulnerabilities such as path traversal, SSRF, and command injection.
/// </remarks>
public class ValidationService : IValidationService
{
    private readonly string[] _allowedDomains = { "aiwp.me" };
    private static readonly Regex ImageIdRegex = new(@"^[0-9]+$", RegexOptions.Compiled);
    private static readonly Regex PathTraversalRegex = new(@"\.\.[/\\]", RegexOptions.Compiled);

    /// <summary>
    /// Gets the maximum allowed image size in bytes (50 MB).
    /// </summary>
    public long MaxImageSize => 52_428_800; // 50 MB

    /// <summary>
    /// Validates whether an image ID is in the correct format.
    /// </summary>
    /// <param name="imageId">The image ID to validate.</param>
    /// <returns>True if the image ID is valid; otherwise, false.</returns>
    /// <remarks>
    /// Valid image IDs must be:
    /// - Non-null and non-whitespace
    /// - Between 1 and 10 characters long
    /// - Contain only numeric digits
    /// </remarks>
    public bool IsValidImageId(string imageId)
    {
        if (string.IsNullOrWhiteSpace(imageId))
            return false;

        if (imageId.Length > 10 || imageId.Length == 0)
            return false;

        return ImageIdRegex.IsMatch(imageId);
    }

    /// <summary>
    /// Validates whether an image URL is from an allowed domain.
    /// </summary>
    /// <param name="url">The URL to validate.</param>
    /// <returns>True if the URL is valid; otherwise, false.</returns>
    /// <remarks>
    /// Valid URLs must:
    /// - Be a valid absolute URL
    /// - Use HTTP or HTTPS scheme
    /// - Be from an allowed domain (aiwp.me)
    /// </remarks>
    public bool IsValidImageUrl(string url)
    {
        if (string.IsNullOrWhiteSpace(url))
            return false;

        if (!Uri.TryCreate(url, UriKind.Absolute, out Uri? uri))
            return false;

        if (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps)
            return false;

        // Check if the host is in the allowed domains list
        foreach (string allowedDomain in _allowedDomains)
        {
            if (uri.Host.Equals(allowedDomain, StringComparison.OrdinalIgnoreCase) ||
                uri.Host.EndsWith($".{allowedDomain}", StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }

    /// <summary>
    /// Validates whether a file path is safe and doesn't contain path traversal attempts.
    /// </summary>
    /// <param name="path">The file path to validate.</param>
    /// <returns>True if the path is valid; otherwise, false.</returns>
    /// <remarks>
    /// This method checks for:
    /// - Null or empty paths
    /// - Path traversal attempts (../ or ..\)
    /// - Invalid path characters
    /// </remarks>
    public bool IsValidFilePath(string path)
    {
        if (string.IsNullOrWhiteSpace(path))
            return false;

        // Check for path traversal attempts
        if (PathTraversalRegex.IsMatch(path))
            return false;

        // Check for invalid path characters
        try
        {
            string? fullPath = Path.GetFullPath(path);
            return !string.IsNullOrEmpty(fullPath);
        }
        catch
        {
            return false;
        }
    }
}
