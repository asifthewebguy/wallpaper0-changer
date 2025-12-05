using System.Diagnostics;
using System.IO.Pipes;
using Microsoft.Extensions.DependencyInjection;
using WallpaperChanger.Services;

namespace WallpaperChanger;

static class Program
{
    // Named pipe for inter-process communication
    private const string PipeName = "WallpaperChangerPipe";
    private static Mutex? _mutex;
    private static readonly string MutexName = "WallpaperChangerMutex";
    private static Form1? _mainForm;
    private static CancellationTokenSource? _pipeServerCts;
    private static IServiceProvider? _serviceProvider;
    private static IAppLogger? _logger;

    /// <summary>
    ///  The main entry point for the application.
    /// </summary>
    [STAThread]
    static void Main(string[] args)
    {
        // Check if another instance is already running
        _mutex = new Mutex(true, MutexName, out bool createdNew);

        if (!createdNew)
        {
            // Another instance is already running, forward arguments
            if (args.Length > 0)
            {
                ForwardArgumentsToRunningInstance(args[0]);
            }
            return;
        }

        try
        {
            // Configure dependency injection
            _serviceProvider = ServiceConfiguration.ConfigureServices();
            _logger = _serviceProvider.GetRequiredService<IAppLogger>();

            _logger?.LogInfo("Application starting", new Dictionary<string, object>
            {
                { "Version", "1.1.3" },
                { "Args", string.Join(", ", args) }
            });

            // To customize application configuration such as set high DPI settings or default font,
            // see https://aka.ms/applicationconfiguration.
            ApplicationConfiguration.Initialize();

            // Set the application to run in the system tray
            Application.SetHighDpiMode(HighDpiMode.SystemAware);
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // Create the main form using DI
            _mainForm = new Form1(
                _serviceProvider.GetRequiredService<IWallpaperService>(),
                _serviceProvider.GetRequiredService<IValidationService>(),
                _serviceProvider.GetRequiredService<IConfigurationService>(),
                _serviceProvider.GetRequiredService<ICacheManager>(),
                _serviceProvider.GetRequiredService<ISchedulerService>(),
                _serviceProvider.GetRequiredService<IAppLogger>()
            )
            {
                WindowState = FormWindowState.Normal,
                ShowInTaskbar = true
            };

            // Start the file watcher for IPC
            StartRequestWatcher();

            // Process command line arguments if any
            if (args.Length > 0)
            {
                _mainForm.ProcessCommandLineArgument(args[0]);
            }

            // Handle application exit
            Application.ApplicationExit += (sender, e) =>
            {
                _logger?.LogInfo("Application exiting");
                // _pipeServerCts?.Cancel(); // No longer needed
                _mutex?.ReleaseMutex();
                _mutex?.Dispose();

                // Dispose DI container
                if (_serviceProvider is IDisposable disposable)
                {
                    disposable.Dispose();
                }
            };

            Application.Run(_mainForm);
        }
        catch (Exception ex)
        {
            _logger?.LogError("Fatal error during application startup", ex);
            MessageBox.Show($"Fatal error: {ex.Message}", "Wallpaper Changer Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private static void StartRequestWatcher()
    {
        try
        {
            string requestDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "WallpaperChanger", "Requests");
            if (!Directory.Exists(requestDir)) Directory.CreateDirectory(requestDir);

            // Clean up old requests
            foreach (var file in Directory.GetFiles(requestDir))
            {
                try { File.Delete(file); } catch { }
            }

            var watcher = new FileSystemWatcher(requestDir, "*.req");
            watcher.NotifyFilter = NotifyFilters.FileName | NotifyFilters.LastWrite;
            watcher.Created += (s, e) => 
            {
                // Simple retry policy for reading the file (it might still be writing)
                for (int i = 0; i < 5; i++)
                {
                    try
                    {
                        if (File.Exists(e.FullPath))
                        {
                            string content = File.ReadAllText(e.FullPath);
                            try { File.Delete(e.FullPath); } catch { } // Clean up immediately

                            if (!string.IsNullOrWhiteSpace(content) && _mainForm != null && !_mainForm.IsDisposed)
                            {
                                // MessageBox.Show($"File Signal Received: {content}", "Debug IPC File");
                                _mainForm.BeginInvoke(() => _mainForm.ProcessCommandLineArgument(content));
                            }
                            break;
                        }
                    }
                    catch 
                    { 
                        Thread.Sleep(100); 
                    }
                }
            };
            watcher.EnableRaisingEvents = true;
            
            // Keep reference to prevent GC
            _requestWatcher = watcher; 
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Failed to start file watcher: {ex.Message}");
        }
    }

    private static FileSystemWatcher? _requestWatcher;

    private static void ForwardArgumentsToRunningInstance(string arg)
    {
        try
        {
            string requestDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "WallpaperChanger", "Requests");
            if (!Directory.Exists(requestDir)) Directory.CreateDirectory(requestDir);

            string filePath = Path.Combine(requestDir, $"{Guid.NewGuid()}.req");
            File.WriteAllText(filePath, arg);
            
            // MessageBox.Show("Signal written to file.", "Debug IPC");
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Failed to communicate with running instance: {ex.Message}");
        }
    }
}
