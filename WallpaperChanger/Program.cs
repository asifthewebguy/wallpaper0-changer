using System.Diagnostics;

namespace WallpaperChanger;

static class Program
{
    /// <summary>
    ///  The main entry point for the application.
    /// </summary>
    [STAThread]
    static void Main(string[] args)
    {
        // Check if another instance is already running
        if (IsApplicationAlreadyRunning())
        {
            // If we have arguments, forward them to the running instance
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
        var mainForm = new Form1();
        mainForm.WindowState = FormWindowState.Minimized;
        mainForm.ShowInTaskbar = false;

        Application.Run(mainForm);
    }

    private static bool IsApplicationAlreadyRunning()
    {
        Process currentProcess = Process.GetCurrentProcess();
        Process[] processes = Process.GetProcessesByName(currentProcess.ProcessName);

        return processes.Length > 1;
    }

    private static void ForwardArgumentsToRunningInstance(string arg)
    {
        // In a real implementation, you would use IPC (Inter-Process Communication)
        // to send the arguments to the running instance.
        // For simplicity, we'll just restart the application with the arguments
        // and let the running instance handle it.

        // This is a simplified approach and not ideal for production use
        Process.Start(Application.ExecutablePath, arg);
    }
}