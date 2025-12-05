using System.Threading.Tasks;
using WallpaperChanger.Models;
namespace WallpaperChanger.Services;

/// <summary>
/// Service responsible for managing scheduled wallpaper rotations.
/// </summary>
public interface ISchedulerService
{
    /// <summary>
    /// Starts the scheduler using the current configuration.
    /// </summary>
    void Start();

    /// <summary>
    /// Stops the scheduler.
    /// </summary>
    void Stop();

    /// <summary>
    /// Updates the scheduler configuration.
    /// </summary>
    /// <param name="intervalMinutes">The interval in minutes.</param>
    /// <param name="source">The source of the wallpaper.</param>
    Task UpdateConfigurationAsync(bool enabled, int intervalMinutes, RotationSource source);
    
    /// <summary>
    /// Forces an immediate wallpaper rotation (if valid images exist).
    /// </summary>
    Task ForceRotationAsync(RotationSource? source = null);

    /// <summary>
    /// Event raised when the next rotation time changes.
    /// </summary>
    event EventHandler<DateTime?> NextRotationChanged;
}
