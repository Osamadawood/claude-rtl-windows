using System.IO;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Media;
using Microsoft.Web.WebView2.Core;

namespace ClaudeRTL;

public partial class BubbleWindow : Window
{
    private const double EdgeMargin = 12;
    private const double OffsetX = 20;
    private const double OffsetY = 14;

    private readonly ApplicationCoordinator _coordinator;
    private readonly SpeechService _speech = new();
    private WebBridge? _bridge;
    private System.Drawing.Point _anchorPoint;
    private bool _arrowBelow;
    private bool _isReady;
    private string? _pendingText;
    private string _pendingAppName = string.Empty;
    private string _pendingProcessName = string.Empty;
    private bool _isHiding;

    public BubbleWindow(ApplicationCoordinator coordinator)
    {
        _coordinator = coordinator;
        InitializeComponent();
        Deactivated += (_, _) => HideBubble();
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

        var environment = await CoreWebView2Environment.CreateAsync(
            userDataFolder: Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "ClaudeRTL",
                "WebView2"));

        await WebView.EnsureCoreWebView2Async(environment);
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
                await ShowBubbleContentAsync(_pendingText, _pendingAppName, _pendingProcessName);
                _pendingText = null;
            }
        };
    }

    public void ShowAt(System.Drawing.Point cursor, string text, string appName, string processName)
    {
        _anchorPoint = cursor;
        _arrowBelow = false;
        _isHiding = false;
        _pendingAppName = appName;
        _pendingProcessName = processName;

        var preliminary = new System.Windows.Size(440, 420);
        SetWindowPosition(preliminary);

        if (!_isReady || _bridge is null)
        {
            _pendingText = text;
            Show();
            Activate();
            return;
        }

        Show();
        Activate();
        _ = ShowBubbleContentAsync(text, appName, processName);
    }

    private async Task ShowBubbleContentAsync(string text, string appName, string processName)
    {
        if (_bridge is null)
            return;

        _speech.Stop();
        await _bridge.ShowBubbleAsync(text, Settings.Instance.FontSize, _arrowBelow, appName, processName);
    }

    public void HideBubble()
    {
        if (_isHiding || !IsVisible)
            return;

        _isHiding = true;
        _speech.Stop();
        Hide();
        _isHiding = false;
    }

    private void OnBridgeMessage(BridgeMessage message)
    {
        switch (message.Action)
        {
            case "copy":
                if (!string.IsNullOrEmpty(message.Text))
                {
                    System.Windows.Clipboard.SetText(message.Text);
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
                    HandleResize(message.W.Value, message.H.Value);
                break;
        }
    }

    private void HandleResize(double width, double height)
    {
        var dipSize = PhysicalToDipSize(width, height);
        Width = Math.Max(dipSize.Width, 120);
        Height = Math.Max(dipSize.Height, 80);
        SetWindowPosition(new System.Windows.Size(Width, Height));
    }

    private void SetWindowPosition(System.Windows.Size size)
    {
        var scale = GetDpiScale();
        var anchorDip = new System.Windows.Point(_anchorPoint.X / scale, _anchorPoint.Y / scale);
        var workArea = Win32Interop.GetWorkAreaForPoint(_anchorPoint);
        var workLeft = workArea.Left / scale;
        var workTop = workArea.Top / scale;
        var workRight = workArea.Right / scale;
        var workBottom = workArea.Bottom / scale;

        var x = anchorDip.X - OffsetX;
        var y = anchorDip.Y - size.Height - OffsetY;
        _arrowBelow = false;

        if (y < workTop + EdgeMargin)
        {
            y = anchorDip.Y + OffsetY;
            _arrowBelow = true;
        }

        x = Math.Clamp(x, workLeft + EdgeMargin, workRight - size.Width - EdgeMargin);
        y = Math.Clamp(y, workTop + EdgeMargin, workBottom - size.Height - EdgeMargin);

        Left = x;
        Top = y;
    }

    private double GetDpiScale()
    {
        var source = PresentationSource.FromVisual(this);
        if (source?.CompositionTarget is not null)
            return source.CompositionTarget.TransformToDevice.M11;

        return 1.0;
    }

    private System.Windows.Size PhysicalToDipSize(double physicalWidth, double physicalHeight)
    {
        var scale = GetDpiScale();
        return new System.Windows.Size(physicalWidth / scale, physicalHeight / scale);
    }
}
