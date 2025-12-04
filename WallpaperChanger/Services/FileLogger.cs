using System.Text.Json;

namespace WallpaperChanger.Services;

/// <summary>
/// File-based logger with JSON structured logging and automatic log rotation.
/// </summary>
public class FileLogger : IAppLogger, IDisposable
{
    private readonly string _logDirectory;
    private readonly SemaphoreSlim _writeLock = new(1, 1);
    private bool _disposed;

    /// <summary>
    /// Initializes a new instance of the <see cref="FileLogger"/> class.
    /// </summary>
    public FileLogger()
    {
        _logDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "WallpaperChanger",
            "Logs"
        );

        Directory.CreateDirectory(_logDirectory);
        CleanupOldLogs();
    }

    /// <summary>
    /// Logs an informational message.
    /// </summary>
    public void LogInfo(string message, Dictionary<string, object>? properties = null)
    {
        WriteLog("INFO", message, null, properties);
    }

    /// <summary>
    /// Logs a warning message.
    /// </summary>
    public void LogWarning(string message, Exception? exception = null)
    {
        WriteLog("WARN", message, exception, null);
    }

    /// <summary>
    /// Logs an error message.
    /// </summary>
    public void LogError(string message, Exception exception)
    {
        var properties = new Dictionary<string, object>
        {
            { "ExceptionType", exception.GetType().Name },
            { "StackTrace", exception.StackTrace ?? "N/A" }
        };

        WriteLog("ERROR", message, exception, properties);
    }

    /// <summary>
    /// Logs a debug message.
    /// </summary>
    public void LogDebug(string message)
    {
#if DEBUG
        WriteLog("DEBUG", message, null, null);
#endif
    }

    private void WriteLog(string level, string message, Exception? exception, Dictionary<string, object>? properties)
    {
        if (_disposed) return;

        try
        {
            _writeLock.Wait();

            try
            {
                string logFilePath = GetLogFilePath();
                var logEntry = new
                {
                    Timestamp = DateTime.UtcNow.ToString("O"),
                    Level = level,
                    Message = message,
                    Exception = exception?.Message,
                    Properties = properties
                };

                string jsonLog = JsonSerializer.Serialize(logEntry);
                File.AppendAllText(logFilePath, jsonLog + Environment.NewLine);
            }
            finally
            {
                _writeLock.Release();
            }
        }
        catch
        {
            // Silently fail to avoid crashing the application due to logging errors
        }
    }

    private string GetLogFilePath()
    {
        string fileName = $"app-{DateTime.UtcNow:yyyy-MM-dd}.log";
        return Path.Combine(_logDirectory, fileName);
    }

    private void CleanupOldLogs()
    {
        try
        {
            var logFiles = Directory.GetFiles(_logDirectory, "app-*.log");
            var cutoffDate = DateTime.UtcNow.AddDays(-7);

            foreach (string logFile in logFiles)
            {
                var fileInfo = new FileInfo(logFile);
                if (fileInfo.LastWriteTimeUtc < cutoffDate)
                {
                    File.Delete(logFile);
                }
            }
        }
        catch
        {
            // Silently fail if cleanup fails
        }
    }

    /// <summary>
    /// Disposes the logger and releases resources.
    /// </summary>
    public void Dispose()
    {
        if (_disposed) return;

        _disposed = true;
        _writeLock.Dispose();
        GC.SuppressFinalize(this);
    }
}
