using System.Windows;

namespace ClaudeRTL;

public sealed class ApplicationCoordinator : IDisposable
{
    private readonly ClipboardMonitor _clipboardMonitor = new();
    private readonly BubbleWindow _bubbleWindow;
    private DateTime _suppressClipboardUntil = DateTime.MinValue;

    public ApplicationCoordinator()
    {
        _bubbleWindow = new BubbleWindow(this);
    }

    public void Start()
    {
        _clipboardMonitor.ClipboardChanged += OnClipboardChanged;
        _clipboardMonitor.Start();
    }

    private void OnClipboardChanged()
    {
        if (!Settings.Instance.IsEnabled)
            return;

        if (DateTime.UtcNow < _suppressClipboardUntil)
            return;

        if (!ForegroundAppWatcher.ShouldShowForForegroundApp())
            return;

        string text;
        try
        {
            text = System.Windows.Clipboard.GetText();
        }
        catch
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(text) || !ArabicDetector.ContainsArabic(text))
            return;

        var app = ForegroundAppWatcher.GetForegroundApp();
        var appName = app?.DisplayName ?? string.Empty;
        var processName = app?.ProcessName ?? string.Empty;
        var cursor = Win32Interop.GetCursorPosition();
        System.Windows.Application.Current.Dispatcher.Invoke(() =>
            _bubbleWindow.ShowAt(cursor, text, appName, processName));
    }

    public void SuppressClipboard(TimeSpan duration) =>
        _suppressClipboardUntil = DateTime.UtcNow.Add(duration);

    public void NoteAppClipboardWrite() => SuppressClipboard(TimeSpan.FromSeconds(1.3));

    public void Dispose()
    {
        _clipboardMonitor.ClipboardChanged -= OnClipboardChanged;
        _clipboardMonitor.Dispose();
        _bubbleWindow.Close();
    }
}
