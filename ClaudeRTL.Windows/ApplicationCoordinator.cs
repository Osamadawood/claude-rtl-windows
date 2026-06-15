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

        if (!ForegroundAppWatcher.IsClaudeForeground())
            return;

        string text;
        try
        {
            text = Clipboard.GetText();
        }
        catch
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(text) || !ArabicDetector.ContainsArabic(text))
            return;

        var cursor = Win32Interop.GetCursorPosition();
        Application.Current.Dispatcher.Invoke(() => _bubbleWindow.ShowAt(cursor, text));
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
