using System.Windows;
using System.Windows.Interop;

namespace ClaudeRTL;

internal sealed class ClipboardMonitor : IDisposable
{
    private HwndSource? _hwndSource;
    private bool _started;

    public event Action? ClipboardChanged;

    public void Start()
    {
        if (_started)
            return;

        var parameters = new HwndSourceParameters("ClaudeRTL.ClipboardMonitor")
        {
            Width = 0,
            Height = 0,
            WindowStyle = 0,
            ParentWindow = new IntPtr(-3) // HWND_MESSAGE
        };

        _hwndSource = new HwndSource(parameters);
        _hwndSource.AddHook(WndProc);

        if (!Win32Interop.AddClipboardFormatListener(_hwndSource.Handle))
            throw new InvalidOperationException("Failed to register clipboard listener.");

        _started = true;
    }

    private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (msg == Win32Interop.WM_CLIPBOARDUPDATE)
        {
            Application.Current.Dispatcher.BeginInvoke(() => ClipboardChanged?.Invoke());
            handled = true;
        }

        return IntPtr.Zero;
    }

    public void Dispose()
    {
        if (_hwndSource is not null)
        {
            Win32Interop.RemoveClipboardFormatListener(_hwndSource.Handle);
            _hwndSource.RemoveHook(WndProc);
            _hwndSource.Dispose();
            _hwndSource = null;
        }

        _started = false;
    }
}
