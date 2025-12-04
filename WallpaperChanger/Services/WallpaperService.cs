using System.Runtime.InteropServices;
using WallpaperChanger.Exceptions;
using WallpaperChanger.Models;

namespace WallpaperChanger.Services;

/// <summary>
/// Main service for setting desktop wallpapers, orchestrating API, download, and system operations.
/// </summary>
public class WallpaperService : IWallpaperService
{
    // Windows API constants
    private const int SPI_SETDESKWALLPAPER = 0x0014;
    private const int SPIF_UPDATEINIFILE = 0x01;
    private const int SPIF_SENDCHANGE = 0x02;

    // Import the Windows API function
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    private readonly IApiClient _apiClient;
    private readonly IImageDownloader _imageDownloader;
    private readonly ICacheManager _cacheManager;
    private readonly IAppLogger _logger;
    private readonly IConfigurationService _configService;

    /// <summary>
    /// Initializes a new instance of the <see cref="WallpaperService"/> class.
    /// </summary>
    public WallpaperService(
        IApiClient apiClient,
        IImageDownloader imageDownloader,
        ICacheManager cacheManager,
        IAppLogger logger,
        IConfigurationService configService)
    {
        _apiClient = apiClient;
        _imageDownloader = imageDownloader;
        _cacheManager = cacheManager;
        _logger = logger;
        _configService = configService;
    }

    /// <summary>
    /// Sets the desktop wallpaper from an image ID.
    /// </summary>
    public async Task<bool> SetWallpaperFromIdAsync(
        string imageId,
        IProgress<DownloadProgress>? progress = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInfo("Starting wallpaper set operation", new Dictionary<string, object>
            {
                { "ImageId", imageId }
            });

            // Step 1: Get image details from API
            ImageDetails imageDetails = await _apiClient.GetImageDetailsAsync(imageId, cancellationToken);

            // Step 2: Download the image
            string localPath = await _imageDownloader.DownloadImageAsync(
                imageDetails.ImageUrl,
                imageId,
                progress,
                cancellationToken);

            // Step 3: Set as wallpaper
            bool success = SetWallpaper(localPath);

            if (success)
            {
                _logger.LogInfo("Wallpaper set successfully", new Dictionary<string, object>
                {
                    { "ImageId", imageId },
                    { "LocalPath", localPath }
                });

                // Step 4: Cleanup cache if needed
                long maxCacheSize = _configService.Settings.MaxCacheSizeMb * 1024 * 1024;
                await _cacheManager.CleanupCacheAsync(maxCacheSize);
            }

            return success;
        }
        catch (WallpaperException)
        {
            throw; // Re-throw WallpaperException as-is
        }
        catch (Exception ex)
        {
            _logger.LogError("Unexpected error in SetWallpaperFromIdAsync", ex);
            throw new WallpaperException(ErrorCode.Unknown, "An unexpected error occurred while setting wallpaper", ex)
                .WithContext("ImageId", imageId);
        }
    }

    /// <summary>
    /// Sets the desktop wallpaper from a local file path.
    /// </summary>
    public bool SetWallpaper(string imagePath)
    {
        try
        {
            if (!File.Exists(imagePath))
            {
                throw new WallpaperException(ErrorCode.InvalidImage, $"Image file not found: {imagePath}")
                    .WithContext("ImagePath", imagePath);
            }

            _logger.LogInfo("Setting wallpaper via Windows API", new Dictionary<string, object>
            {
                { "ImagePath", imagePath }
            });

            // Call Windows API to set wallpaper
            int result = SystemParametersInfo(
                SPI_SETDESKWALLPAPER,
                0,
                imagePath,
                SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
            );

            if (result == 0)
            {
                throw new WallpaperException(ErrorCode.SystemApiError, "Windows API call to set wallpaper failed")
                    .WithContext("ImagePath", imagePath)
                    .WithContext("SystemResult", result);
            }

            _logger.LogInfo("Wallpaper set successfully via Windows API");
            return true;
        }
        catch (WallpaperException)
        {
            throw; // Re-throw WallpaperException as-is
        }
        catch (Exception ex)
        {
            _logger.LogError("Error setting wallpaper", ex);
            throw new WallpaperException(ErrorCode.SystemApiError, "Failed to set wallpaper", ex)
                .WithContext("ImagePath", imagePath);
        }
    }
}
