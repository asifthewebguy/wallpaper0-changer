using WallpaperChanger.Exceptions;
using WallpaperChanger.Models;

namespace WallpaperChanger.Services;

/// <summary>
/// Service for managing cached wallpaper images with LRU eviction.
/// </summary>
public class CacheManager : ICacheManager
{
    private readonly string _cacheDirectory;
    private readonly IAppLogger _logger;
    private readonly IValidationService _validationService;
    private readonly Dictionary<string, DateTime> _accessTimes;
    private readonly SemaphoreSlim _cacheLock = new(1, 1);

    /// <summary>
    /// Initializes a new instance of the <see cref="CacheManager"/> class.
    /// </summary>
    /// <param name="logger">The logger instance.</param>
    /// <param name="validationService">The validation service.</param>
    /// <param name="configService">The configuration service.</param>
    public CacheManager(IAppLogger logger, IValidationService validationService, IConfigurationService configService)
    {
        _logger = logger;
        _validationService = validationService;
        _cacheDirectory = configService.Settings.CacheDirectory;
        _accessTimes = new Dictionary<string, DateTime>();

        // Create cache directory if it doesn't exist
        Directory.CreateDirectory(_cacheDirectory);
        LoadAccessTimes();
    }

    /// <summary>
    /// Gets the cached image path for a given image ID.
    /// </summary>
    public string GetCachedImagePath(string imageId, string extension)
    {
        if (!_validationService.IsValidImageId(imageId))
        {
            throw new WallpaperException(ErrorCode.InvalidImageId, $"Invalid image ID: {imageId}");
        }

        string fileName = $"{imageId}{extension}";
        string path = Path.Combine(_cacheDirectory, fileName);

        if (!_validationService.IsValidFilePath(path))
        {
            throw new WallpaperException(ErrorCode.CacheError, "Invalid cache file path");
        }

        return path;
    }

    /// <summary>
    /// Gets the existing cached image path for a given image ID (searches all extensions).
    /// </summary>
    public string? GetExistingCachedImagePath(string imageId)
    {
        try
        {
            var files = Directory.GetFiles(_cacheDirectory, $"{imageId}.*");
            return files.FirstOrDefault();
        }
        catch (Exception ex)
        {
            _logger.LogWarning($"Error finding cached image path for {imageId}", ex);
            return null;
        }
    }

    /// <summary>
    /// Checks if an image is already cached.
    /// </summary>
    public bool IsCached(string imageId)
    {
        try
        {
            var files = Directory.GetFiles(_cacheDirectory, $"{imageId}.*");
            return files.Length > 0;
        }
        catch (Exception ex)
        {
            _logger.LogWarning($"Error checking cache for image {imageId}", ex);
            return false;
        }
    }

    /// <summary>
    /// Updates the access time for a cached image (for LRU tracking).
    /// </summary>
    public void UpdateAccessTime(string imageId)
    {
        _accessTimes[imageId] = DateTime.UtcNow;
    }

    /// <summary>
    /// Cleans up the cache to stay within the size limit using LRU eviction.
    /// </summary>
    public async Task CleanupCacheAsync(long maxSizeBytes)
    {
        await _cacheLock.WaitAsync();

        try
        {
            long currentSize = GetCacheSize();

            if (currentSize <= maxSizeBytes)
            {
                _logger.LogDebug($"Cache size ({currentSize} bytes) within limit ({maxSizeBytes} bytes)");
                return;
            }

            _logger.LogInfo($"Cache cleanup needed. Current: {currentSize / 1024 / 1024} MB, Max: {maxSizeBytes / 1024 / 1024} MB");

            var cachedImages = await GetCacheHistoryAsync();

            // Sort by last access time (LRU - least recently used first)
            var sortedImages = cachedImages.OrderBy(img => img.LastAccessTime).ToList();

            long bytesToRemove = currentSize - maxSizeBytes;
            long bytesRemoved = 0;
            int filesRemoved = 0;

            foreach (var cachedImage in sortedImages)
            {
                if (bytesRemoved >= bytesToRemove)
                    break;

                try
                {
                    if (File.Exists(cachedImage.FilePath))
                    {
                        File.Delete(cachedImage.FilePath);
                        bytesRemoved += cachedImage.FileSize;
                        filesRemoved++;
                        _accessTimes.Remove(cachedImage.ImageId);

                        _logger.LogDebug($"Removed cached image: {cachedImage.ImageId}");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning($"Failed to delete cached file: {cachedImage.FilePath}", ex);
                }
            }

            _logger.LogInfo($"Cache cleanup complete. Removed {filesRemoved} files, freed {bytesRemoved / 1024 / 1024} MB");
            SaveAccessTimes();
        }
        finally
        {
            _cacheLock.Release();
        }
    }

    /// <summary>
    /// Gets the cache history with metadata.
    /// </summary>
    public async Task<List<CachedImage>> GetCacheHistoryAsync()
    {
        return await Task.Run(() =>
        {
            var cachedImages = new List<CachedImage>();

            try
            {
                var files = Directory.GetFiles(_cacheDirectory);

                foreach (string filePath in files)
                {
                    // Skip access times file
                    if (Path.GetFileName(filePath) == "access-times.json")
                        continue;

                    try
                    {
                        var fileInfo = new FileInfo(filePath);
                        string imageId = Path.GetFileNameWithoutExtension(filePath);

                        var cachedImage = new CachedImage
                        {
                            ImageId = imageId,
                            FilePath = filePath,
                            CachedAt = fileInfo.CreationTimeUtc,
                            FileSize = fileInfo.Length,
                            LastAccessTime = _accessTimes.ContainsKey(imageId)
                                ? _accessTimes[imageId]
                                : fileInfo.LastAccessTimeUtc
                        };

                        cachedImages.Add(cachedImage);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning($"Error reading cached file: {filePath}", ex);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError("Error getting cache history", ex);
            }

            return cachedImages;
        });
    }

    /// <summary>
    /// Gets the total cache size in bytes.
    /// </summary>
    public long GetCacheSize()
    {
        try
        {
            var files = Directory.GetFiles(_cacheDirectory);
            long totalSize = 0;

            foreach (string file in files)
            {
                // Skip access times file
                if (Path.GetFileName(file) == "access-times.json")
                    continue;

                try
                {
                    totalSize += new FileInfo(file).Length;
                }
                catch
                {
                    // Skip files that can't be read
                }
            }

            return totalSize;
        }
        catch (Exception ex)
        {
            _logger.LogWarning("Error calculating cache size", ex);
            return 0;
        }
    }

    /// <summary>
    /// Clears all cached images.
    /// </summary>
    public async Task ClearCacheAsync()
    {
        await _cacheLock.WaitAsync();

        try
        {
            var files = Directory.GetFiles(_cacheDirectory);
            int deletedCount = 0;

            foreach (string file in files)
            {
                try
                {
                    File.Delete(file);
                    deletedCount++;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning($"Failed to delete file: {file}", ex);
                }
            }

            _accessTimes.Clear();
            _logger.LogInfo($"Cache cleared. Deleted {deletedCount} files");
        }
        finally
        {
            _cacheLock.Release();
        }
    }

    private void LoadAccessTimes()
    {
        try
        {
            string accessTimesPath = Path.Combine(_cacheDirectory, "access-times.json");
            if (File.Exists(accessTimesPath))
            {
                string json = File.ReadAllText(accessTimesPath);
                var loadedTimes = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, DateTime>>(json);

                if (loadedTimes != null)
                {
                    foreach (var kvp in loadedTimes)
                    {
                        _accessTimes[kvp.Key] = kvp.Value;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning("Failed to load access times", ex);
        }
    }

    private void SaveAccessTimes()
    {
        try
        {
            string accessTimesPath = Path.Combine(_cacheDirectory, "access-times.json");
            string json = System.Text.Json.JsonSerializer.Serialize(_accessTimes);
            File.WriteAllText(accessTimesPath, json);
        }
        catch (Exception ex)
        {
            _logger.LogWarning("Failed to save access times", ex);
        }
    }
}
