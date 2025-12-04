namespace WallpaperChanger.Exceptions;

/// <summary>
/// Exception thrown when a wallpaper operation fails.
/// </summary>
public class WallpaperException : Exception
{
    /// <summary>
    /// Gets the error code for this exception.
    /// </summary>
    public ErrorCode ErrorCode { get; }

    /// <summary>
    /// Gets additional context information about the error.
    /// </summary>
    public Dictionary<string, object> Context { get; }

    /// <summary>
    /// Initializes a new instance of the <see cref="WallpaperException"/> class.
    /// </summary>
    /// <param name="code">The error code.</param>
    /// <param name="message">The error message.</param>
    /// <param name="innerException">The inner exception, if any.</param>
    public WallpaperException(ErrorCode code, string message, Exception? innerException = null)
        : base(message, innerException)
    {
        ErrorCode = code;
        Context = new Dictionary<string, object>();
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="WallpaperException"/> class with context.
    /// </summary>
    /// <param name="code">The error code.</param>
    /// <param name="message">The error message.</param>
    /// <param name="context">Additional context information.</param>
    /// <param name="innerException">The inner exception, if any.</param>
    public WallpaperException(ErrorCode code, string message, Dictionary<string, object> context, Exception? innerException = null)
        : base(message, innerException)
    {
        ErrorCode = code;
        Context = context;
    }

    /// <summary>
    /// Adds a context value to the exception.
    /// </summary>
    /// <param name="key">The context key.</param>
    /// <param name="value">The context value.</param>
    /// <returns>This exception instance for method chaining.</returns>
    public WallpaperException WithContext(string key, object value)
    {
        Context[key] = value;
        return this;
    }
}
