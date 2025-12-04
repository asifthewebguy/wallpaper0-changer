using WallpaperChanger.Exceptions;

namespace WallpaperChanger.Services;

/// <summary>
/// Service for generating user-friendly error messages from exceptions.
/// </summary>
public static class ErrorMessageService
{
    /// <summary>
    /// Gets a user-friendly error message for a <see cref="WallpaperException"/>.
    /// </summary>
    /// <param name="ex">The exception to get a message for.</param>
    /// <returns>A user-friendly error message.</returns>
    public static string GetUserFriendlyMessage(WallpaperException ex)
    {
        return ex.ErrorCode switch
        {
            ErrorCode.InvalidImageId => "The wallpaper ID is invalid. Please check the link and try again.",
            ErrorCode.NetworkError => "Unable to connect to the internet. Please check your connection and try again.",
            ErrorCode.ApiError => "The wallpaper service is currently unavailable. Please try again later.",
            ErrorCode.DownloadFailed => "Failed to download the wallpaper. Please try again.",
            ErrorCode.InvalidImage => "The wallpaper file is invalid or corrupted. Please try a different image.",
            ErrorCode.FileTooLarge => "The wallpaper file is too large. Maximum size is 50 MB.",
            ErrorCode.Timeout => "The operation timed out. Please check your internet connection and try again.",
            ErrorCode.CacheError => "Failed to save the wallpaper to cache. Please check available disk space.",
            ErrorCode.ConfigurationError => "Configuration error. Please check application settings.",
            ErrorCode.SystemApiError => "Failed to set the wallpaper. This may be a Windows permissions issue.",
            _ => $"An unexpected error occurred: {ex.Message}"
        };
    }

    /// <summary>
    /// Gets a user-friendly error message with recovery suggestions.
    /// </summary>
    /// <param name="ex">The exception to get a message for.</param>
    /// <returns>A detailed user-friendly error message with suggestions.</returns>
    public static string GetDetailedMessage(WallpaperException ex)
    {
        string baseMessage = GetUserFriendlyMessage(ex);
        string suggestion = GetRecoverySuggestion(ex.ErrorCode);

        return string.IsNullOrEmpty(suggestion)
            ? baseMessage
            : $"{baseMessage}\n\nSuggestion: {suggestion}";
    }

    private static string GetRecoverySuggestion(ErrorCode errorCode)
    {
        return errorCode switch
        {
            ErrorCode.NetworkError => "Check your internet connection and firewall settings.",
            ErrorCode.ApiError => "Wait a few minutes and try again. If the problem persists, the service may be down.",
            ErrorCode.DownloadFailed => "Try a different wallpaper or check your internet connection.",
            ErrorCode.FileTooLarge => "Contact the wallpaper provider about file size limits.",
            ErrorCode.Timeout => "Try again with a faster internet connection or a smaller image.",
            ErrorCode.CacheError => "Free up disk space or change the cache location in settings.",
            ErrorCode.SystemApiError => "Try running the application as administrator or check Windows permissions.",
            _ => string.Empty
        };
    }
}
