namespace WallpaperChanger.Services;

/// <summary>
/// Interface for application logging.
/// </summary>
public interface IAppLogger
{
    /// <summary>
    /// Logs an informational message.
    /// </summary>
    /// <param name="message">The message to log.</param>
    /// <param name="properties">Additional properties to include in the log entry.</param>
    void LogInfo(string message, Dictionary<string, object>? properties = null);

    /// <summary>
    /// Logs a warning message.
    /// </summary>
    /// <param name="message">The warning message to log.</param>
    /// <param name="exception">The exception, if any.</param>
    void LogWarning(string message, Exception? exception = null);

    /// <summary>
    /// Logs an error message.
    /// </summary>
    /// <param name="message">The error message to log.</param>
    /// <param name="exception">The exception associated with the error.</param>
    void LogError(string message, Exception exception);

    /// <summary>
    /// Logs a debug message.
    /// </summary>
    /// <param name="message">The debug message to log.</param>
    void LogDebug(string message);
}
