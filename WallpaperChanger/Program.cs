using System.Diagnostics;
using System.IO.Pipes;

namespace WallpaperChanger;

static class Program
{
    // Named pipe for inter-process communication
    private const string PipeName = "WallpaperChangerPipe";
    private static Mutex? _mutex;
    private static readonly string MutexName = "WallpaperChangerMutex";
    private static Form1? _mainForm;
    private static CancellationTokenSource? _pipeServerCts;

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

        // To customize application configuration such as set high DPI settings or default font,
        // see https://aka.ms/applicationconfiguration.
        ApplicationConfiguration.Initialize();

        // Set the application to run in the system tray
        Application.SetHighDpiMode(HighDpiMode.SystemAware);
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        // Create and run the main form
        _mainForm = new Form1
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
            _pipeServerCts?.Cancel();
            _mutex?.ReleaseMutex();
            _mutex?.Dispose();
        };

        Application.Run(_mainForm);
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
                Debug.WriteLine($"Named pipe server error: {ex.Message}");
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