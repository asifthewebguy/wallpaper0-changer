using WallpaperChanger.Controls;
using WallpaperChanger.Exceptions;
using WallpaperChanger.Models;
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
    private readonly ICacheManager _cacheManager;
    private readonly IAppLogger _logger;
    private NotifyIcon _notifyIcon = null!;
    private readonly ISchedulerService _schedulerService;

    /// <summary>
    /// Initializes a new instance of the <see cref="Form1"/> class.
    /// </summary>
    public Form1(
        IWallpaperService wallpaperService,
        IValidationService validationService,
        IConfigurationService configService,
        ICacheManager cacheManager,
        ISchedulerService schedulerService,
        IAppLogger logger)
    {
        _wallpaperService = wallpaperService;
        _validationService = validationService;
        _configService = configService;
        _cacheManager = cacheManager;
        _schedulerService = schedulerService;
        _logger = logger;

        InitializeComponent();
        SetupNotifyIcon();
        SetupUI();

        // Start scheduler if enabled in settings
        if (_configService.Settings.IsSchedulerEnabled)
        {
            _schedulerService.Start();
        }

        _logger.LogInfo("Form1 initialized successfully");
    }

    private void SetupUI()
    {
        // Resize form for better gallery viewing
        this.ClientSize = new Size(950, 650);
        this.Text = "Wallpaper Changer";

        // Create TabControl
        var tabControl = new TabControl
        {
            Dock = DockStyle.Fill,
            Padding = new Point(10, 5)
        };

        // Tab 1: Home
        var homeTab = new TabPage("Home");
        homeTab.BackColor = Color.White;
        
        var homeLabel = new Label
        {
            Text = "Wallpaper Changer is running.\n\n" +
                   "Use 'wallpaper0-changer:IMAGE_ID' links to set wallpapers.\n" +
                   "Minimize to send to system tray.",
            AutoSize = false,
            TextAlign = ContentAlignment.MiddleCenter,
            Dock = DockStyle.Fill,
            Font = new Font("Segoe UI", 12)
        };
        homeTab.Controls.Add(homeLabel);

        // Tab 2: History
        var historyTab = new TabPage("History");
        historyTab.BackColor = Color.White;

        var historyControl = new HistoryControl(_cacheManager, _logger)
        {
            Dock = DockStyle.Fill
        };
        
        historyControl.WallpaperRequested += (s, imageId) =>
        {
             _ = SetWallpaperFromHistoryAsync(imageId);
        };

        historyTab.Controls.Add(historyControl);

        // Tab 3: Schedule
        var scheduleTab = new TabPage("Schedule");
        scheduleTab.BackColor = Color.White;

        var scheduleControl = new ScheduleControl(_schedulerService, _configService)
        {
            Dock = DockStyle.Fill
        };

        scheduleTab.Controls.Add(scheduleControl);
        
        // Refresh history when tab is selected
        tabControl.SelectedIndexChanged += async (s, e) =>
        {
            if (tabControl.SelectedTab == historyTab)
            {
                await historyControl.RefreshHistoryAsync();
            }
        };

        tabControl.Controls.Add(homeTab);
        tabControl.Controls.Add(historyTab);
        tabControl.Controls.Add(scheduleTab);

        this.Controls.Add(tabControl);
    }

    private async Task SetWallpaperFromHistoryAsync(string imageId)
    {
        try
        {
            ShowNotification("Setting Wallpaper", $"Applying wallpaper {imageId}...");
            // Use existing logic
            // Since it's in history, it should be cached, so download will be instant/skipped
            bool success = await _wallpaperService.SetWallpaperFromIdAsync(imageId);
            
            if (success)
            {
                ShowNotification("Success", "Wallpaper set successfully!");
            }
        }
        catch (Exception ex)
        {
             _logger.LogError("Error setting wallpaper from history", ex);
            ShowNotification("Error", "Failed to set wallpaper");
        }
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

    /// <summary>
    /// Raises the <see cref="E:System.Windows.Forms.Form.FormClosing" /> event.
    /// </summary>
    /// <param name="e">A <see cref="T:System.Windows.Forms.FormClosingEventArgs" /> that contains the event data.</param>
    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        if (e.CloseReason == CloseReason.UserClosing)
        {
            e.Cancel = true;
            this.Hide();
            ShowNotification("Minimized", "Wallpaper Changer is still running in the tray.");
        }
        else
        {
            base.OnFormClosing(e);
        }
    }

    private void ShowWindow()
    {
        this.Show();
        this.WindowState = FormWindowState.Normal;
        this.Activate();
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
        
        _notifyIcon.DoubleClick += (s, e) => ShowWindow();

        // Create context menu
        var contextMenu = new ContextMenuStrip();
        contextMenu.Items.Add("Rotate Now (API)", null, async (s, e) => {
            ShowNotification("Rotating", "Fetching random wallpaper from API...");
            await _schedulerService.ForceRotationAsync(RotationSource.Api);
        });
        contextMenu.Items.Add("Open Wallpaper Changer", null, (s, e) => ShowWindow());
        contextMenu.Items.Add("-"); // Separator
        contextMenu.Items.Add("Exit", null, (s, e) => {
            _notifyIcon.Visible = false; // Cleanup icon
            Application.Exit();
        });
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

            // Ensure window is visible if handling a URL manually from command line (optional, maybe just notify)
            // ShowWindow(); 

            string imageId = string.Empty;



            // Parse the URL (format: wallpaper0-changer:image_id or wallpaper0-changer:image_id.jpg)
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
                
                // Handle protocol slashes (e.g., wallpaper0-changer://ID)
                imageId = imageId.TrimStart('/');
            }
            else
            {
                ShowNotification("Error", $"Invalid URL format: {url}");
                _logger.LogWarning("Invalid URL format received", null);
                return;
            }

            // Strip file extension if present (handles .jpg, .png, .jpeg, etc.)
            // Extension stripping removed to support IDs like FC17THT7U5.jpg
            // if (imageId.Contains('.')) ...

            // Handle protocol slashes (e.g., wallpaper0-changer://ID) and whitespace
            imageId = imageId.TrimStart('/').Trim();

            // Validate the image ID before processing
            if (!_validationService.IsValidImageId(imageId))
            {
                string debugInfo = $"ID: '{imageId}'\nLength: {imageId.Length}\nMatches Regex: {System.Text.RegularExpressions.Regex.IsMatch(imageId, @"^[a-zA-Z0-9_.-]+$")}";
                MessageBox.Show($"Validation Failed!\n{debugInfo}", "Debug Validation");
                
                ShowNotification("Error", $"Invalid wallpaper ID: {imageId}. Please check the link and try again.");
                _logger.LogWarning($"Invalid image ID after parsing: {imageId}", null);
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
