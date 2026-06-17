using System.IO;
using System.Text;
using System.Windows.Threading;

namespace ClaudeRTL;

internal static class CrashLogger
{
    private static readonly object Sync = new();
    private static bool _initialized;

    private static string LogDirectory =>
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "ClaudeRTL");

    private static string LogPath => Path.Combine(LogDirectory, "crash.log");

    public static void Initialize()
    {
        if (_initialized)
            return;

        _initialized = true;
        Directory.CreateDirectory(LogDirectory);

        AppDomain.CurrentDomain.UnhandledException += (_, e) =>
        {
            if (e.ExceptionObject is Exception ex)
                Log("AppDomain.UnhandledException", ex);
            else
                Log("AppDomain.UnhandledException", e.ExceptionObject?.ToString() ?? "unknown");
        };

        TaskScheduler.UnobservedTaskException += (_, e) =>
        {
            Log("TaskScheduler.UnobservedTaskException", e.Exception);
            e.SetObserved();
        };
    }

    public static void AttachDispatcher(Dispatcher dispatcher)
    {
        dispatcher.UnhandledException += (_, e) =>
        {
            Log("DispatcherUnhandledException", e.Exception);
            e.Handled = true;
        };
    }

    public static void Log(string source, Exception ex)
    {
        var builder = new StringBuilder();
        builder.AppendLine($"[{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}] {source}");
        builder.AppendLine(ex.Message);
        builder.AppendLine(ex.StackTrace);

        if (ex.InnerException is not null)
        {
            builder.AppendLine("--- Inner ---");
            builder.AppendLine(ex.InnerException.Message);
            builder.AppendLine(ex.InnerException.StackTrace);
        }

        Append(builder.ToString());
    }

    public static void Log(string source, string message)
    {
        Append($"[{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}] {source}{Environment.NewLine}{message}{Environment.NewLine}");
    }

    private static void Append(string entry)
    {
        lock (Sync)
        {
            try
            {
                File.AppendAllText(LogPath, entry + Environment.NewLine, Encoding.UTF8);
            }
            catch
            {
                // Last resort: avoid recursive failures while logging.
            }
        }
    }
}
