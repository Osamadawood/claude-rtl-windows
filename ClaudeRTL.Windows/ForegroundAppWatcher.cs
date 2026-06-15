using System.Diagnostics;

namespace ClaudeRTL;

internal static class ForegroundAppWatcher
{
    public static bool IsClaudeForeground()
    {
        var hwnd = Win32Interop.GetForegroundWindow();
        if (hwnd == IntPtr.Zero)
            return false;

        Win32Interop.GetWindowThreadProcessId(hwnd, out var processId);
        if (processId == 0)
            return false;

        try
        {
            using var process = Process.GetProcessById((int)processId);
            var name = process.ProcessName.ToLowerInvariant();
            return name.Contains("claude") || name.Contains("anthropic");
        }
        catch
        {
            return false;
        }
    }
}
