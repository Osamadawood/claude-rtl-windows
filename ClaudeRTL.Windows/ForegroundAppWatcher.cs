using System.Diagnostics;

namespace ClaudeRTL;

public readonly record struct ForegroundAppInfo(string ProcessName, string DisplayName);

internal static class ForegroundAppWatcher
{
    public static ForegroundAppInfo? GetForegroundApp()
    {
        var hwnd = Win32Interop.GetForegroundWindow();
        if (hwnd == IntPtr.Zero)
            return null;

        Win32Interop.GetWindowThreadProcessId(hwnd, out var processId);
        if (processId == 0)
            return null;

        try
        {
            using var process = Process.GetProcessById((int)processId);
            var processName = process.ProcessName.ToLowerInvariant();
            var displayName = string.IsNullOrWhiteSpace(process.MainWindowTitle)
                ? process.ProcessName
                : process.ProcessName;

            try
            {
                var fileName = process.MainModule?.FileName;
                if (!string.IsNullOrEmpty(fileName))
                {
                    var description = System.Diagnostics.FileVersionInfo.GetVersionInfo(fileName).FileDescription;
                    if (!string.IsNullOrWhiteSpace(description))
                        displayName = description;
                }
            }
            catch
            {
                // Access denied for some system processes.
            }

            return new ForegroundAppInfo(processName, displayName);
        }
        catch
        {
            return null;
        }
    }

    public static bool ShouldShowForForegroundApp()
    {
        var app = GetForegroundApp();
        if (app is null)
            return false;

        var processName = app.Value.ProcessName;

        if (Settings.Instance.ExcludedProcessesSession.Contains(processName))
            return false;

        if (Settings.Instance.ExcludedProcessesAlways.Any(p =>
                string.Equals(p, processName, StringComparison.OrdinalIgnoreCase)))
            return false;

        return Settings.Instance.TriggerMode switch
        {
            TriggerMode.AllApps => true,
            TriggerMode.ClaudeOnly => Settings.IsClaudeProcess(processName, app.Value.DisplayName),
            TriggerMode.CustomList => Settings.Instance.IncludedProcesses.Any(p =>
                string.Equals(p, processName, StringComparison.OrdinalIgnoreCase)),
            _ => true
        };
    }
}
