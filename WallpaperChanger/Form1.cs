using WallpaperChanger.Exceptions;
using WallpaperChanger.Services;

namespace WallpaperChanger;

/// <summary>
/// Main form for the Wallpaper Changer application.
/// Runs in the system tray and handles protocol URL processing.
/// </summary>
public partial class Form1 : Form
{
    private readonly IWallpaperService _wallpaperService;
    private readonly IValidationService _validationService;
    private readonly IConfigurationService _configService;
    private readonly IAppLogger _logger;
    private NotifyIcon _notifyIcon = null!;

    /// <summary>
    /// Initializes a new instance of the <see cref="Form1"/> class.
    /// </summary>
    /// <param name="wallpaperService">The wallpaper service.</param>
    /// <param name="validationService">The validation service.</param>
    /// <param name="configService">The configuration service.</param>
    /// <param name="logger">The logger instance.</param>
    public Form1(
        IWallpaperService wallpaperService,
        IValidationService validationService,
        IConfigurationService configService,
        IAppLogger logger)
    {
        _wallpaperService = wallpaperService;
        _validationService = validationService;
        _configService = configService;
        _logger = logger;

        InitializeComponent();
        SetupNotifyIcon();

        _logger.LogInfo("Form1 initialized successfully");
    }

    /// <summary>
    /// Process a command line argument received from another instance.
    /// </summary>
    /// <param name="arg">The command line argument (protocol URL).</param>
    public void ProcessCommandLineArgument(string arg)
    {
        if (!string.IsNullOrEmpty(arg))
        {
            ProcessProtocolUrl(arg);
        }
    }

    private void SetupNotifyIcon()
    {
        // Load the custom icon
        var iconPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Resources", "wallpaper_icon.ico");
        Icon customIcon;

        if (File.Exists(iconPath))
        {
            try
            {
                customIcon = new Icon(iconPath);
                _logger.LogDebug("Loaded custom icon successfully");
            }
            catch (Exception ex)
            {
                _logger.LogWarning("Failed to load custom icon, using default", ex);
                customIcon = SystemIcons.Application;
            }
        }
        else
        {
            _logger.LogWarning("Custom icon file not found, using default");
            customIcon = SystemIcons.Application;
        }

        _notifyIcon = new NotifyIcon
        {
            Icon = customIcon,
            Visible = true,
            Text = "Wallpaper Changer"
        };

        // Create context menu
        var contextMenu = new ContextMenuStrip();
        contextMenu.Items.Add("Exit", null, (s, e) => Application.Exit());
        _notifyIcon.ContextMenuStrip = contextMenu;
    }

    private void ProcessProtocolUrl(string url)
    {
        try
        {
            _logger.LogInfo("Processing protocol URL", new Dictionary<string, object>
            {
                { "Url", url }
            });

            string imageId = string.Empty;

            // Parse the URL (format: wallpaper0-changer:image_id)
            if (url.StartsWith("wallpaper0-changer:"))
            {
                imageId = url.Substring("wallpaper0-changer:".Length);
            }
            // Handle URL with protocol prefix that might come from browsers
            else if (url.Contains("wallpaper0-changer:"))
            {
                int index = url.IndexOf("wallpaper0-changer:");
                imageId = url.Substring(index + "wallpaper0-changer:".Length);

                // Clean up the image ID (remove any trailing characters)
                imageId = imageId.Split('&', '?', '#', ' ')[0];
            }
            else
            {
                ShowNotification("Error", $"Invalid URL format: {url}");
                _logger.LogWarning("Invalid URL format received", null);
                return;
            }

            // Validate the image ID before processing
            if (!_validationService.IsValidImageId(imageId))
            {
                ShowNotification("Error", $"Invalid wallpaper ID: {imageId}. Please check the link and try again.");
                _logger.LogWarning("Invalid image ID", null);
                return;
            }

            SetWallpaperAsync(imageId);
        }
        catch (Exception ex)
        {
            _logger.LogError("Error processing protocol URL", ex);
            ShowNotification("Error", $"Failed to process URL: {ex.Message}");
        }
    }

    private async void SetWallpaperAsync(string imageId)
    {
        try
        {
            ShowNotification("Downloading", $"Downloading wallpaper {imageId}...");

            // Use the wallpaper service to handle everything
            bool success = await _wallpaperService.SetWallpaperFromIdAsync(imageId);

            if (success)
            {
                ShowNotification("Success", "Wallpaper set successfully!");
            }
            else
            {
                ShowNotification("Error", "Failed to set wallpaper");
            }
        }
        catch (WallpaperException ex)
        {
            _logger.LogError("WallpaperException caught in SetWallpaperAsync", ex);

            // Get user-friendly error message
            string userMessage = ErrorMessageService.GetUserFriendlyMessage(ex);
            ShowNotification("Error", userMessage);
        }
        catch (Exception ex)
        {
            _logger.LogError("Unexpected error in SetWallpaperAsync", ex);
            ShowNotification("Error", $"An unexpected error occurred: {ex.Message}");
        }
    }

    private void ShowNotification(string title, string message)
    {
        // Check settings to see if notifications are enabled
        if (!_configService.Settings.ShowNotifications && title != "Error")
            return;

        _notifyIcon.BalloonTipTitle = title;
        _notifyIcon.BalloonTipText = message;
        _notifyIcon.ShowBalloonTip(3000);
    }
}
