using System.Net;
using System.Runtime.InteropServices;
using System.Text.Json;

namespace WallpaperChanger;

public partial class Form1 : Form
{
    // Constants for the Windows API
    private const int SPI_SETDESKWALLPAPER = 0x0014;
    private const int SPIF_UPDATEINIFILE = 0x01;
    private const int SPIF_SENDCHANGE = 0x02;

    // Import the Windows API function
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    // API endpoints
    private const string API_BASE_URL = "https://aiwp.me/api/";
    private const string IMAGES_DATA_URL = API_BASE_URL + "images-data.json";
    private const string IMAGE_DETAILS_URL = API_BASE_URL + "images/{0}.json";

    // Debug settings
    private const bool SHOW_DEBUG_NOTIFICATIONS = false;

    // Cache directory
    private readonly string _cacheDir;

    // Notification icon
    private NotifyIcon _notifyIcon = null!;

    public Form1()
    {
        InitializeComponent();

        // Create cache directory
        _cacheDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "WallpaperChanger",
            "Cache"
        );
        Directory.CreateDirectory(_cacheDir);

        // Set up notification icon
        SetupNotifyIcon();
    }

    /// <summary>
    /// Process a command line argument received from another instance
    /// </summary>
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
            }
            catch (Exception)
            {
                // Fallback to system icon if there's an error loading the custom icon
                customIcon = SystemIcons.Application;
            }
        }
        else
        {
            // Fallback to system icon if the file doesn't exist
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
            // Parse the URL (format: wallpaper0-changer:image_id)
            if (url.StartsWith("wallpaper0-changer:"))
            {
                string imageId = url.Substring("wallpaper0-changer:".Length);
                DownloadAndSetWallpaper(imageId);
            }
            // Handle URL with protocol prefix that might come from browsers
            else if (url.Contains("wallpaper0-changer:"))
            {
                int index = url.IndexOf("wallpaper0-changer:");
                string imageId = url.Substring(index + "wallpaper0-changer:".Length);

                // Clean up the image ID (remove any trailing characters)
                imageId = imageId.Split('&', '?', '#', ' ')[0];

                DownloadAndSetWallpaper(imageId);
            }
            else
            {
                ShowNotification("Error", $"Invalid URL format: {url}");
            }
        }
        catch (Exception ex)
        {
            ShowNotification("Error", $"Failed to process URL: {ex.Message}");
        }
    }

    private async void DownloadAndSetWallpaper(string imageId)
    {
        try
        {
            ShowNotification("Downloading", $"Downloading wallpaper {imageId}...");

            // Get image details
            string imageUrl = await GetImageUrl(imageId);
            if (string.IsNullOrEmpty(imageUrl))
            {
                ShowNotification("Error", $"Failed to get image URL for ID: {imageId}");
                return;
            }

            // Download the image
            string localPath = await DownloadImage(imageUrl, imageId);

            // Set as wallpaper
            if (SetWallpaper(localPath))
            {
                ShowNotification("Success", "Wallpaper set successfully!");
            }
            else
            {
                ShowNotification("Error", "Failed to set wallpaper");
            }
        }
        catch (Exception ex)
        {
            ShowNotification("Error", $"Failed to set wallpaper: {ex.Message}");
        }
    }

    private async Task<string> GetImageUrl(string imageId)
    {
        using (HttpClient client = new HttpClient())
        {
            string detailsUrl = string.Format(IMAGE_DETAILS_URL, imageId);
            string json = await client.GetStringAsync(detailsUrl);

            using (JsonDocument doc = JsonDocument.Parse(json))
            {
                JsonElement root = doc.RootElement;

                // Try to get the URL from different possible properties
                if (root.TryGetProperty("path", out JsonElement pathElement))
                {
                    return pathElement.GetString() ?? string.Empty;
                }
                else if (root.TryGetProperty("url", out JsonElement urlElement))
                {
                    return urlElement.GetString() ?? string.Empty;
                }
                else if (root.TryGetProperty("thumbnailUrl", out JsonElement thumbnailUrlElement))
                {
                    return thumbnailUrlElement.GetString() ?? string.Empty;
                }

                // If none of the above properties exist, we'll return an empty string
                // No debug notification needed
            }
        }

        return string.Empty;
    }

    private async Task<string> DownloadImage(string imageUrl, string imageId)
    {
        // Create a unique filename
        string extension = Path.GetExtension(imageUrl);
        if (string.IsNullOrEmpty(extension))
        {
            extension = ".jpg"; // Default extension
        }

        string localPath = Path.Combine(_cacheDir, $"{imageId}{extension}");

        // Download the image
        using (HttpClient client = new HttpClient())
        {
            byte[] imageData = await client.GetByteArrayAsync(imageUrl);
            await File.WriteAllBytesAsync(localPath, imageData);
        }

        return localPath;
    }

    private bool SetWallpaper(string path)
    {
        int result = SystemParametersInfo(
            SPI_SETDESKWALLPAPER,
            0,
            path,
            SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
        );

        return result != 0;
    }

    private void ShowNotification(string title, string message)
    {
        // Skip debug notifications unless debug is enabled
        if (title == "Debug" && !SHOW_DEBUG_NOTIFICATIONS)
            return;

        _notifyIcon.BalloonTipTitle = title;
        _notifyIcon.BalloonTipText = message;
        _notifyIcon.ShowBalloonTip(3000);
    }
}
