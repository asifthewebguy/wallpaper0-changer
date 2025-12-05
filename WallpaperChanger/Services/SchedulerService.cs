using System.Threading.Tasks;
using System.Timers;
using WallpaperChanger.Models;
using Timer = System.Timers.Timer;

namespace WallpaperChanger.Services;

/// <summary>
/// Validates and executes scheduled wallpaper rotations.
/// </summary>
public class SchedulerService : ISchedulerService, IDisposable
{
    private readonly IConfigurationService _configService;
    private readonly ICacheManager _cacheManager;
    private readonly IWallpaperService _wallpaperService;
    private readonly IApiClient _apiClient;
    private readonly IAppLogger _logger;
    private Timer? _timer;
    private DateTime? _nextRotationTime;
    private readonly Random _random = new();

    public event EventHandler<DateTime?>? NextRotationChanged;

    public SchedulerService(
        IConfigurationService configService,
        ICacheManager cacheManager,
        IWallpaperService wallpaperService,
        IApiClient apiClient,
        IAppLogger logger)
    {
        _configService = configService;
        _cacheManager = cacheManager;
        _wallpaperService = wallpaperService;
        _apiClient = apiClient;
        _logger = logger;
    }

    public void Start()
    {
        Stop(); // Ensure no duplicates

        if (!_configService.Settings.IsSchedulerEnabled)
        {
            _logger.LogInfo("Scheduler is disabled in settings, not starting.");
            return;
        }

        int intervalMinutes = _configService.Settings.SchedulerIntervalMinutes;
        if (intervalMinutes < 1) intervalMinutes = 1; // Minimum safety

        double intervalMs = TimeSpan.FromMinutes(intervalMinutes).TotalMilliseconds;
        
        _timer = new Timer(intervalMs);
        _timer.Elapsed += OnTimerElapsed;
        _timer.AutoReset = true;
        _timer.Start();

        _nextRotationTime = DateTime.Now.AddMinutes(intervalMinutes);
        NextRotationChanged?.Invoke(this, _nextRotationTime);

        _logger.LogInfo($"Scheduler started. Next rotation at: {_nextRotationTime}");
    }

    public void Stop()
    {
        _timer?.Stop();
        _timer?.Dispose();
        _timer = null;
        _nextRotationTime = null;
        NextRotationChanged?.Invoke(this, null);
    }

    public async Task UpdateConfigurationAsync(bool enabled, int intervalMinutes, RotationSource source)
    {
        _configService.Settings.IsSchedulerEnabled = enabled;
        _configService.Settings.SchedulerIntervalMinutes = intervalMinutes;
        _configService.Settings.RotationSource = source;
        await _configService.SaveSettingsAsync();

        if (enabled)
        {
            Start();
        }
        else
        {
            Stop();
        }
    }

    private async void OnTimerElapsed(object? sender, ElapsedEventArgs e)
    {
        try
        {
            _logger.LogInfo("Scheduler triggered. Attempting rotation.");
            await RotateWallpaperAsync();
            
            // Re-calculate next rotation for UI display (approximate)
            if (_timer != null)
            {
                _nextRotationTime = DateTime.Now.AddMilliseconds(_timer.Interval);
                NextRotationChanged?.Invoke(this, _nextRotationTime);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError("Error during scheduled rotation", ex);
        }
    }

    private async Task RotateWallpaperAsync(RotationSource? overrideSource = null)
    {
        var source = overrideSource ?? _configService.Settings.RotationSource;
        string? targetImageId = null;

        if (source == RotationSource.History)
        {
            var history = await _cacheManager.GetCacheHistoryAsync();
            // Filter for valid files
            var validImages = history.Where(x => File.Exists(x.FilePath)).ToList();

            if (validImages.Count == 0)
            {
                _logger.LogWarning("No valid images in history to rotate.");
                return;
            }

            int index = _random.Next(validImages.Count);
            targetImageId = validImages[index].ImageId;
            _logger.LogInfo($"Rotating to random history image: {targetImageId}");
        }
        else // API Source (defaulting to API if not history)
        {
            try 
            {
                _logger.LogInfo("Fetching random image ID from API...");
                targetImageId = await _apiClient.GetRandomImageIdAsync();
                _logger.LogInfo($"Fetched random API image ID: {targetImageId}");
            }
            catch (Exception ex)
            {
                _logger.LogError("Failed to get random image from API during rotation", ex);
                return; 
            }
        }

        if (!string.IsNullOrEmpty(targetImageId))
        {
            await _wallpaperService.SetWallpaperFromIdAsync(targetImageId);
        }
    }

    public async Task ForceRotationAsync(RotationSource? source = null)
    {
        _logger.LogInfo($"Manual rotation triggered. Override Source: {source?.ToString() ?? "None"}");
        await RotateWallpaperAsync(source);
    }

    public void Dispose()
    {
        Stop();
    }
}
