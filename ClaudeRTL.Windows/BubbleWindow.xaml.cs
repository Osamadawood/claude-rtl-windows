using System.IO;
using System.Windows;
using Microsoft.Web.WebView2.Core;

namespace ClaudeRTL;

public partial class BubbleWindow : Window
{
    private readonly ApplicationCoordinator _coordinator;
    private readonly SpeechService _speech = new();
    private WebBridge? _bridge;
    private bool _isReady;
    private string? _pendingText;

    public BubbleWindow(ApplicationCoordinator coordinator)
    {
        _coordinator = coordinator;
        InitializeComponent();
        Loaded += async (_, _) => await InitializeWebViewAsync();
        Closed += (_, _) => _speech.Dispose();

        _speech.SpeakingChanged += async speaking =>
        {
            if (_bridge is not null)
                await _bridge.SetSpeakingAsync(speaking);
        };

        _speech.SpeakProgress += async (location, length) =>
        {
            if (_bridge is not null)
                await _bridge.HighlightRangeAsync(location, length);
        };
    }

    private async Task InitializeWebViewAsync()
    {
        var resourcesDir = Path.Combine(AppContext.BaseDirectory, "Resources");
        Directory.CreateDirectory(resourcesDir);

        await WebView.EnsureCoreWebView2Async();
        WebView.DefaultBackgroundColor = System.Drawing.Color.Transparent;

        _bridge = new WebBridge(WebView);
        _bridge.MessageReceived += OnBridgeMessage;
        _bridge.Attach();

        var bubblePath = Path.Combine(resourcesDir, "bubble.html");
        WebView.CoreWebView2.Navigate(new Uri(bubblePath).AbsoluteUri);
        WebView.CoreWebView2.NavigationCompleted += async (_, e) =>
        {
            if (!e.IsSuccess)
                return;

            _isReady = true;
            if (_pendingText is not null)
            {
                await _bridge.ShowBubbleAsync(_pendingText, Settings.Instance.FontSize, false);
                _pendingText = null;
            }
        };
    }

    public void ShowAt(System.Drawing.Point cursor, string text)
    {
        Left = cursor.X + 12;
        Top = cursor.Y + 12;

        if (!_isReady || _bridge is null)
        {
            _pendingText = text;
            Show();
            Activate();
            return;
        }

        Show();
        Activate();
        _speech.Stop();
        _ = _bridge.ShowBubbleAsync(text, Settings.Instance.FontSize, false);
    }

    public void HideBubble()
    {
        _speech.Stop();
        Hide();
    }

    private void OnBridgeMessage(BridgeMessage message)
    {
        switch (message.Action)
        {
            case "copy":
                if (!string.IsNullOrEmpty(message.Text))
                {
                    Clipboard.SetText(message.Text);
                    _coordinator.NoteAppClipboardWrite();
                }
                break;
            case "speak":
                _speech.Toggle(message.Text ?? string.Empty);
                break;
            case "close":
                HideBubble();
                break;
            case "resize":
                if (message.W is > 0 && message.H is > 0)
                {
                    Width = Math.Max(message.W.Value, 120);
                    Height = Math.Max(message.H.Value, 80);
                }
                break;
        }
    }
}
