using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;

namespace ClaudeRTL;

/// <summary>
/// Hides the bubble on left-click outside its window — parity with Mac globalClickMonitor.
/// </summary>
internal sealed class BubbleDismissMonitor : IDisposable
{
    private const int WhMouseLl = 14;
    private const int WmLButtonDown = 0x0201;

    private readonly BubbleWindow _window;
    private Win32Interop.LowLevelMouseProc? _hookProc;
    private IntPtr _hookHandle = IntPtr.Zero;
    private bool _started;

    public BubbleDismissMonitor(BubbleWindow window) => _window = window;

    public void Start()
    {
        if (_started)
            return;

        _hookProc = OnMouseHook;
        _hookHandle = Win32Interop.SetWindowsHookEx(WhMouseLl, _hookProc, Win32Interop.GetModuleHandle(null), 0);
        _started = _hookHandle != IntPtr.Zero;
    }

    public void Stop()
    {
        if (_hookHandle != IntPtr.Zero)
        {
            Win32Interop.UnhookWindowsHookEx(_hookHandle);
            _hookHandle = IntPtr.Zero;
        }

        _hookProc = null;
        _started = false;
    }

    private IntPtr OnMouseHook(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && wParam == (IntPtr)WmLButtonDown)
        {
            var info = Marshal.PtrToStructure<Win32Interop.MSLLHOOKSTRUCT>(lParam);
            var screenPoint = new System.Drawing.Point(info.pt.X, info.pt.Y);

            System.Windows.Application.Current?.Dispatcher.BeginInvoke(() =>
            {
                if (!_window.IsVisible)
                    return;

                if (!IsPointInsideWindow(_window, screenPoint))
                    _window.HideBubble();
            });
        }

        return Win32Interop.CallNextHookEx(_hookHandle, nCode, wParam, lParam);
    }

    private static bool IsPointInsideWindow(Window window, System.Drawing.Point screenPoint)
    {
        var hwnd = new WindowInteropHelper(window).Handle;
        if (hwnd == IntPtr.Zero)
            return false;

        if (!Win32Interop.GetWindowRect(hwnd, out var rect))
            return false;

        return screenPoint.X >= rect.Left && screenPoint.X < rect.Right &&
               screenPoint.Y >= rect.Top && screenPoint.Y < rect.Bottom;
    }

    public void Dispose() => Stop();
}
