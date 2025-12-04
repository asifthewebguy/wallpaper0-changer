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
                _serviceProvider.GetRequiredService<IAppLogger>()
            )
            {
                WindowState = FormWindowState.Minimized,
                ShowInTaskbar = false
            };

            // Start the named pipe server
            _pipeServerCts = new CancellationTokenSource();
            Task.Run(() => StartNamedPipeServer(_pipeServerCts.Token));

            // Process command line arguments if any
            if (args.Length > 0)
            {
                _mainForm.ProcessCommandLineArgument(args[0]);
            }

            // Handle application exit
            Application.ApplicationExit += (sender, e) =>
            {
                _logger?.LogInfo("Application exiting");
                _pipeServerCts?.Cancel();
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

    private static async Task StartNamedPipeServer(CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            try
            {
                using (var pipeServer = new NamedPipeServerStream(PipeName, PipeDirection.In, 1, PipeTransmissionMode.Message))
                {
                    // Wait for a client to connect
                    await pipeServer.WaitForConnectionAsync(cancellationToken);

                    // Read the message
                    using (var reader = new StreamReader(pipeServer))
                    {
                        string? message = await reader.ReadLineAsync(cancellationToken);
                        if (!string.IsNullOrEmpty(message))
                        {
                            // Process the message on the UI thread
                            if (_mainForm != null && !_mainForm.IsDisposed)
                            {
                                _mainForm.Invoke(() => _mainForm.ProcessCommandLineArgument(message));
                            }
                        }
                    }
                }
            }
            catch (OperationCanceledException)
            {
                // Cancellation requested, exit the loop
                break;
            }
            catch (Exception ex)
            {
                // Log the error and continue
                _logger?.LogWarning("Named pipe server error", ex);
                await Task.Delay(1000, cancellationToken); // Wait a bit before retrying
            }
        }
    }

    private static void ForwardArgumentsToRunningInstance(string arg)
    {
        try
        {
            using (var pipeClient = new NamedPipeClientStream(".", PipeName, PipeDirection.Out))
            {
                // Connect to the server with a timeout
                pipeClient.Connect(5000); // 5 second timeout

                // Send the message
                using (var writer = new StreamWriter(pipeClient) { AutoFlush = true })
                {
                    writer.WriteLine(arg);
                }
            }
        }
        catch (Exception ex)
        {
            // If we can't connect to the pipe, show an error message
            MessageBox.Show($"Failed to communicate with the running instance: {ex.Message}",
                "Wallpaper Changer", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
