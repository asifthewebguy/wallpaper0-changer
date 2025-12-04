using Polly;
using Polly.Retry;
using WallpaperChanger.Exceptions;
using WallpaperChanger.Models;

namespace WallpaperChanger.Services;

/// <summary>
/// Service for downloading images with validation, progress reporting, and retry logic.
/// </summary>
public class ImageDownloader : IImageDownloader
{
    private readonly HttpClient _httpClient;
    private readonly IValidationService _validationService;
    private readonly ICacheManager _cacheManager;
    private readonly IAppLogger _logger;
    private readonly AsyncRetryPolicy _retryPolicy;

    /// <summary>
    /// Initializes a new instance of the <see cref="ImageDownloader"/> class.
    /// </summary>
    public ImageDownloader(
        HttpClient httpClient,
        IValidationService validationService,
        ICacheManager cacheManager,
        IAppLogger logger,
        IConfigurationService configService)
    {
        _httpClient = httpClient;
        _validationService = validationService;
        _cacheManager = cacheManager;
        _logger = logger;

        // Configure timeout
        _httpClient.Timeout = TimeSpan.FromSeconds(configService.Settings.DownloadTimeoutSeconds);

        // Configure retry policy
        _retryPolicy = Policy
            .Handle<HttpRequestException>()
            .Or<TaskCanceledException>()
            .WaitAndRetryAsync(
                configService.Settings.MaxRetries,
                retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (exception, timespan, retryCount, context) =>
                {
                    _logger.LogWarning($"Download retry {retryCount} after {timespan.TotalSeconds}s delay", exception);
                });
    }

    /// <summary>
    /// Downloads an image from a URL and saves it to the cache.
    /// </summary>
    public async Task<string> DownloadImageAsync(
        string imageUrl,
        string imageId,
        IProgress<DownloadProgress>? progress = null,
        CancellationToken cancellationToken = default)
    {
        // Validate inputs
        if (!_validationService.IsValidImageUrl(imageUrl))
        {
            throw new WallpaperException(ErrorCode.InvalidImage, "Invalid or untrusted image URL")
                .WithContext("Url", imageUrl);
        }

        if (!_validationService.IsValidImageId(imageId))
        {
            throw new WallpaperException(ErrorCode.InvalidImageId, $"Invalid image ID: {imageId}")
                .WithContext("ImageId", imageId);
        }

        // Check if already cached
        if (_cacheManager.IsCached(imageId))
        {
            string extension = Path.GetExtension(imageUrl);
            if (string.IsNullOrEmpty(extension))
            {
                extension = ".jpg";
            }

            string cachedPath = _cacheManager.GetCachedImagePath(imageId, extension);

            if (File.Exists(cachedPath))
            {
                _logger.LogInfo("Using cached image", new Dictionary<string, object>
                {
                    { "ImageId", imageId },
                    { "CachedPath", cachedPath }
                });

                _cacheManager.UpdateAccessTime(imageId);
                return cachedPath;
            }
        }

        try
        {
            _logger.LogInfo("Downloading image", new Dictionary<string, object>
            {
                { "ImageId", imageId },
                { "Url", imageUrl }
            });

            // Download with retry policy
            byte[] imageData = await _retryPolicy.ExecuteAsync(async () =>
            {
                return await DownloadWithProgressAsync(imageUrl, progress, cancellationToken);
            });

            // Validate downloaded size
            if (imageData.Length > _validationService.MaxImageSize)
            {
                throw new WallpaperException(ErrorCode.FileTooLarge,
                    $"Downloaded image size ({imageData.Length / 1024 / 1024} MB) exceeds maximum allowed size ({_validationService.MaxImageSize / 1024 / 1024} MB)")
                    .WithContext("ImageId", imageId)
                    .WithContext("FileSize", imageData.Length);
            }

            // Get file extension
            string extension = Path.GetExtension(imageUrl);
            if (string.IsNullOrEmpty(extension))
            {
                extension = ".jpg"; // Default extension
            }

            // Save to cache
            string localPath = _cacheManager.GetCachedImagePath(imageId, extension);
            await File.WriteAllBytesAsync(localPath, imageData, cancellationToken);

            _cacheManager.UpdateAccessTime(imageId);

            _logger.LogInfo("Image downloaded successfully", new Dictionary<string, object>
            {
                { "ImageId", imageId },
                { "LocalPath", localPath },
                { "FileSize", imageData.Length }
            });

            return localPath;
        }
        catch (TaskCanceledException ex) when (ex.CancellationToken == cancellationToken)
        {
            _logger.LogInfo("Download cancelled by user");
            throw new WallpaperException(ErrorCode.DownloadFailed, "Download was cancelled", ex)
                .WithContext("ImageId", imageId);
        }
        catch (TaskCanceledException ex)
        {
            throw new WallpaperException(ErrorCode.Timeout, "Download timed out", ex)
                .WithContext("ImageId", imageId)
                .WithContext("Url", imageUrl);
        }
        catch (HttpRequestException ex)
        {
            throw new WallpaperException(ErrorCode.NetworkError, "Network error during download", ex)
                .WithContext("ImageId", imageId)
                .WithContext("Url", imageUrl);
        }
        catch (WallpaperException)
        {
            throw; // Re-throw WallpaperException as-is
        }
        catch (Exception ex)
        {
            _logger.LogError("Unexpected error during download", ex);
            throw new WallpaperException(ErrorCode.DownloadFailed, "Failed to download image", ex)
                .WithContext("ImageId", imageId)
                .WithContext("Url", imageUrl);
        }
    }

    private async Task<byte[]> DownloadWithProgressAsync(
        string url,
        IProgress<DownloadProgress>? progress,
        CancellationToken cancellationToken)
    {
        using (HttpResponseMessage response = await _httpClient.GetAsync(url, HttpCompletionOption.ResponseHeadersRead, cancellationToken))
        {
            response.EnsureSuccessStatusCode();

            // Check file size before downloading
            long? contentLength = response.Content.Headers.ContentLength;

            if (contentLength.HasValue && contentLength.Value > _validationService.MaxImageSize)
            {
                throw new WallpaperException(ErrorCode.FileTooLarge,
                    $"Image size ({contentLength.Value / 1024 / 1024} MB) exceeds maximum allowed size ({_validationService.MaxImageSize / 1024 / 1024} MB)")
                    .WithContext("ContentLength", contentLength.Value);
            }

            using (Stream contentStream = await response.Content.ReadAsStreamAsync(cancellationToken))
            {
                var buffer = new byte[8192];
                var memoryStream = new MemoryStream();
                long totalBytesRead = 0;
                int bytesRead;

                while ((bytesRead = await contentStream.ReadAsync(buffer, 0, buffer.Length, cancellationToken)) > 0)
                {
                    await memoryStream.WriteAsync(buffer, 0, bytesRead, cancellationToken);
                    totalBytesRead += bytesRead;

                    // Report progress
                    if (progress != null && contentLength.HasValue)
                    {
                        progress.Report(new DownloadProgress
                        {
                            BytesReceived = totalBytesRead,
                            TotalBytes = contentLength.Value
                        });
                    }

                    // Check size limit during download
                    if (totalBytesRead > _validationService.MaxImageSize)
                    {
                        throw new WallpaperException(ErrorCode.FileTooLarge,
                            "Download exceeded maximum file size limit")
                            .WithContext("BytesRead", totalBytesRead);
                    }
                }

                return memoryStream.ToArray();
            }
        }
    }
}
