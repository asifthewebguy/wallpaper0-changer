namespace WallpaperChanger.Exceptions;

/// <summary>
/// Error codes for different types of failures in the application.
/// </summary>
public enum ErrorCode
{
    /// <summary>
    /// The image ID provided is invalid.
    /// </summary>
    InvalidImageId,

    /// <summary>
    /// A network error occurred.
    /// </summary>
    NetworkError,

    /// <summary>
    /// The API returned an error.
    /// </summary>
    ApiError,

    /// <summary>
    /// The image download failed.
    /// </summary>
    DownloadFailed,

    /// <summary>
    /// The image file is invalid or corrupted.
    /// </summary>
    InvalidImage,

    /// <summary>
    /// A cache operation failed.
    /// </summary>
    CacheError,

    /// <summary>
    /// A configuration error occurred.
    /// </summary>
    ConfigurationError,

    /// <summary>
    /// A Windows system API call failed.
    /// </summary>
    SystemApiError,

    /// <summary>
    /// The image file is too large.
    /// </summary>
    FileTooLarge,

    /// <summary>
    /// The operation timed out.
    /// </summary>
    Timeout,

    /// <summary>
    /// An unknown error occurred.
    /// </summary>
    Unknown
}
