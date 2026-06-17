using System.IO;
using System.Windows;
using System.Windows.Media;
using System.Windows.Threading;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.Wpf;

namespace ClaudeRTL;

public partial class BubbleWindow : Window
{
    private const double EdgeMargin = 12;
    private const double OffsetX = 20;
    private const double OffsetY = 14;
    private const double MinBubbleWidth = 220;
    private const double MaxBubbleWidth = 520;
    private const double MinBubbleHeight = 64;
    private const double MaxHeightScreenFraction = 0.70;
    private const double BubbleCornerRadius = 18;

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
    private double? _pendingResizeWidth;
    private double? _pendingResizeHeight;

    public BubbleWindow(ApplicationCoordinator coordinator)
    {
        _coordinator = coordinator;
        InitializeComponent();
        PrepareWebViewDefaultBackground();
        Deactivated += (_, _) => HideBubble();
        Loaded += async (_, _) => await InitializeWebViewAsync();
        Closed += (_, _) => _speech.Dispose();

        _speech.SpeakingChanged += async speaking =>
        {
            if (_bridge is null)
                return;

            try
            {
                await _bridge.SetSpeakingAsync(speaking);
            }
            catch (Exception ex)
            {
                CrashLogger.Log("BubbleWindow.SetSpeaking", ex);
            }
        };

        _speech.SpeakProgress += async (location, length) =>
        {
            if (_bridge is null)
                return;

            try
            {
                await _bridge.HighlightRangeAsync(location, length);
            }
            catch (Exception ex)
            {
                CrashLogger.Log("BubbleWindow.HighlightRange", ex);
            }
        };
    }

    private async Task InitializeWebViewAsync()
    {
        try
        {
            var resourcesDir = Path.Combine(AppContext.BaseDirectory, "Resources");
            Directory.CreateDirectory(resourcesDir);

            PrepareWebViewDefaultBackground();

            var environment = await CoreWebView2Environment.CreateAsync(
                userDataFolder: Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "ClaudeRTL",
                    "WebView2"));

            await WebView.EnsureCoreWebView2Async(environment);
            TryEnableTransparentWebViewBackgroundAfterInit();

            _bridge = new WebBridge(WebView);
            _bridge.MessageReceived += OnBridgeMessage;
            _bridge.Attach();

            var bubblePath = Path.Combine(resourcesDir, "bubble.html");
            WebView.CoreWebView2.NavigationCompleted += async (_, e) =>
            {
                if (!e.IsSuccess)
                    return;

                try
                {
                    _isReady = true;
                    ThemeManager.Instance.Register(async () =>
                    {
                        if (_bridge is not null)
                            await _bridge.SetThemeAsync(ThemeManager.Instance.EffectiveTheme());
                    });
                    await ApplyThemeAsync();
                    ApplyPendingResize();
                    if (_pendingText is not null)
                    {
                        await ShowBubbleContentAsync(_pendingText, _pendingAppName, _pendingProcessName);
                        _pendingText = null;
                    }

                    FocusWebViewIfReady();
                }
                catch (Exception ex)
                {
                    CrashLogger.Log("BubbleWindow.NavigationCompleted", ex);
                }
            };

            WebView.CoreWebView2.Navigate(new Uri(bubblePath).AbsoluteUri);
        }
        catch (Exception ex)
        {
            CrashLogger.Log("BubbleWindow.InitializeWebView", ex);
        }
    }

    public void ShowAt(System.Drawing.Point cursor, string text, string appName, string processName)
    {
        RunOnUiThread(() =>
        {
            try
            {
                _anchorPoint = cursor;
                _arrowBelow = false;
                _isHiding = false;
                _pendingAppName = appName ?? string.Empty;
                _pendingProcessName = processName ?? string.Empty;
                _pendingResizeWidth = null;
                _pendingResizeHeight = null;

                ApplyInitialWindowSize();

                if (!_isReady || _bridge is null)
                {
                    _pendingText = text;
                    ShowBubbleWindow();
                    return;
                }

                ShowBubbleWindow();
                _ = ShowBubbleContentAsync(text, _pendingAppName, _pendingProcessName);
            }
            catch (Exception ex)
            {
                CrashLogger.Log("BubbleWindow.ShowAt", ex);
            }
        });
    }

    private void ShowBubbleWindow()
    {
        Show();
        Activate();
        Dispatcher.BeginInvoke(FocusWebViewIfReady, DispatcherPriority.Loaded);
    }

    private void FocusWebViewIfReady()
    {
        if (!IsVisible || !IsLoaded || !_isReady || WebView.CoreWebView2 is null)
            return;

        try
        {
            WebView.Focus();
        }
        catch (Exception ex)
        {
            CrashLogger.Log("BubbleWindow.FocusWebView", ex);
        }
    }

    private async Task ShowBubbleContentAsync(string text, string appName, string processName)
    {
        if (_bridge is null)
            return;

        try
        {
            _speech.Stop();
            await _bridge.ShowBubbleAsync(
                text,
                Settings.Instance.FontSize,
                _arrowBelow,
                appName ?? string.Empty,
                processName ?? string.Empty);
        }
        catch (Exception ex)
        {
            CrashLogger.Log("BubbleWindow.ShowBubbleContent", ex);
        }
    }

    private async Task ApplyThemeAsync()
    {
        if (_bridge is null)
            return;

        try
        {
            TryUpdateWebViewBackgroundForTheme(ThemeManager.Instance.EffectiveTheme());
            await _bridge.SetThemeAsync(ThemeManager.Instance.EffectiveTheme());
        }
        catch (Exception ex)
        {
            CrashLogger.Log("BubbleWindow.ApplyTheme", ex);
        }
    }

    public void HideBubble()
    {
        RunOnUiThread(() =>
        {
            try
            {
                if (_isHiding || !IsVisible)
                    return;

                _isHiding = true;
                _speech.Stop();
                Hide();
                _isHiding = false;
            }
            catch (Exception ex)
            {
                CrashLogger.Log("BubbleWindow.HideBubble", ex);
            }
        });
    }

    private void OnBridgeMessage(BridgeMessage message)
    {
        RunOnUiThread(() =>
        {
            try
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
                        QueueOrApplyResize(message.Width ?? message.W, message.Height ?? message.H);
                        break;
                    case "disableApp":
                        HandleDisableApp(message);
                        break;
                }
            }
            catch (Exception ex)
            {
                CrashLogger.Log("BubbleWindow.OnBridgeMessage", ex);
            }
        });
    }

    private void HandleDisableApp(BridgeMessage message)
    {
        var processName = message.Process ?? message.BundleId ?? string.Empty;
        var displayName = message.Name ?? processName;
        if (string.IsNullOrWhiteSpace(processName))
            return;

        if (string.Equals(message.Scope, "always", StringComparison.OrdinalIgnoreCase))
            Settings.Instance.ExcludePermanently(processName, displayName);
        else
            Settings.Instance.ExcludeForSession(processName);

        SettingsWindow.ReloadIfOpen();
        HideBubble();
    }

    private void QueueOrApplyResize(double? width, double? height)
    {
        if (!TryNormalizeResize(width, height, out var validWidth, out var validHeight))
            return;

        if (!_isReady || !IsVisible)
        {
            _pendingResizeWidth = validWidth;
            _pendingResizeHeight = validHeight;
            return;
        }

        ApplyResize(validWidth, validHeight);
    }

    private void ApplyPendingResize()
    {
        if (_pendingResizeWidth is not double width || _pendingResizeHeight is not double height)
            return;

        _pendingResizeWidth = null;
        _pendingResizeHeight = null;
        ApplyResize(width, height);
    }

    private static bool TryNormalizeResize(double? width, double? height, out double validWidth, out double validHeight)
    {
        validWidth = 0;
        validHeight = 0;

        if (width is not > 0 || height is not > 0)
            return false;

        if (double.IsNaN(width.Value) || double.IsInfinity(width.Value))
            return false;

        if (double.IsNaN(height.Value) || double.IsInfinity(height.Value))
            return false;

        validWidth = width.Value;
        validHeight = height.Value;
        return true;
    }

    private void ApplyInitialWindowSize()
    {
        Width = MinBubbleWidth;
        Height = MinBubbleHeight;
        SetWindowPosition(new System.Windows.Size(Width, Height));
        UpdateRoundedWindowClip();
    }

    private void ApplyResize(double width, double height)
    {
        try
        {
            var scale = GetDpiScale();
            var workArea = GetEffectiveWorkArea(_anchorPoint);
            var workHeightDip = workArea.Height / scale;
            if (workHeightDip <= 0)
                workHeightDip = SystemParameters.WorkArea.Height;

            var maxHeightDip = Math.Max(MinBubbleHeight, Math.Floor(workHeightDip * MaxHeightScreenFraction));

            var widthDip = Math.Clamp(width / scale, MinBubbleWidth, MaxBubbleWidth);
            var heightDip = Math.Clamp(height / scale, MinBubbleHeight, maxHeightDip);

            var previousArrowBelow = _arrowBelow;
            Width = widthDip;
            Height = heightDip;
            SetWindowPosition(new System.Windows.Size(Width, Height));
            UpdateRoundedWindowClip();

            if (_arrowBelow != previousArrowBelow && _bridge is not null)
                _ = _bridge.SetArrowBelowAsync(_arrowBelow);
        }
        catch (Exception ex)
        {
            CrashLogger.Log("BubbleWindow.ApplyResize", ex);
        }
    }

    private void SetWindowPosition(System.Windows.Size size)
    {
        try
        {
            if (size.Width <= 0 || size.Height <= 0 ||
                double.IsNaN(size.Width) || double.IsNaN(size.Height))
                return;

            var scale = GetDpiScale();
            var anchorDip = new System.Windows.Point(_anchorPoint.X / scale, _anchorPoint.Y / scale);
            var workArea = GetEffectiveWorkArea(_anchorPoint);
            var workLeft = workArea.Left / scale;
            var workTop = workArea.Top / scale;
            var workRight = workArea.Right / scale;
            var workBottom = workArea.Bottom / scale;

            if (workRight <= workLeft || workBottom <= workTop)
            {
                var fallback = SystemParameters.WorkArea;
                workLeft = fallback.Left;
                workTop = fallback.Top;
                workRight = fallback.Right;
                workBottom = fallback.Bottom;
            }

            var x = anchorDip.X - OffsetX;
            var y = anchorDip.Y - size.Height - OffsetY;
            _arrowBelow = false;

            if (y < workTop + EdgeMargin)
            {
                y = anchorDip.Y + OffsetY;
                _arrowBelow = true;
            }

            var maxX = Math.Max(workLeft + EdgeMargin, workRight - size.Width - EdgeMargin);
            var maxY = Math.Max(workTop + EdgeMargin, workBottom - size.Height - EdgeMargin);
            x = Math.Clamp(x, workLeft + EdgeMargin, maxX);
            y = Math.Clamp(y, workTop + EdgeMargin, maxY);

            Left = x;
            Top = y;
        }
        catch (Exception ex)
        {
            CrashLogger.Log("BubbleWindow.SetWindowPosition", ex);
        }
    }

    private static System.Drawing.Rectangle GetEffectiveWorkArea(System.Drawing.Point anchor)
    {
        var workArea = Win32Interop.GetWorkAreaForPoint(anchor);
        if (workArea.Width > 0 && workArea.Height > 0)
            return workArea;

        var fallback = SystemParameters.WorkArea;
        return new System.Drawing.Rectangle(
            (int)fallback.Left,
            (int)fallback.Top,
            (int)fallback.Width,
            (int)fallback.Height);
    }

    private void RunOnUiThread(Action action)
    {
        if (Dispatcher.CheckAccess())
            action();
        else
            Dispatcher.Invoke(action);
    }

    private double GetDpiScale()
    {
        var source = PresentationSource.FromVisual(this);
        if (source?.CompositionTarget is not null)
        {
            var scale = source.CompositionTarget.TransformToDevice.M11;
            if (scale > 0 && !double.IsNaN(scale) && !double.IsInfinity(scale))
                return scale;
        }

        return 1.0;
    }

    private void PrepareWebViewDefaultBackground()
    {
        try
        {
            // Always opaque before EnsureCoreWebView2Async — WPF WebView2 defaults to transparent,
            // which crashes some runtimes when the controller applies DefaultBackgroundColor.
            WebView.DefaultBackgroundColor = GetOpaqueBackgroundForTheme(ThemeManager.Instance.EffectiveTheme());
        }
        catch (Exception ex)
        {
            CrashLogger.Log("BubbleWindow.DefaultBackgroundColor", ex);
            TryApplyFallbackOpaqueBackground();
        }
    }

    private void TryEnableTransparentWebViewBackgroundAfterInit()
    {
        if (!WebView2Capabilities.SupportsTransparentBackground())
            return;

        try
        {
            WebView.DefaultBackgroundColor = System.Drawing.Color.FromArgb(0, 0, 0, 0);
        }
        catch (Exception ex)
        {
            CrashLogger.Log("BubbleWindow.DefaultBackgroundColor.Transparent", ex);
        }
    }

    private void TryUpdateWebViewBackgroundForTheme(string theme)
    {
        if (WebView.CoreWebView2 is null)
            return;

        if (WebView.DefaultBackgroundColor.A == 0)
            return;

        try
        {
            WebView.DefaultBackgroundColor = GetOpaqueBackgroundForTheme(theme);
        }
        catch (Exception ex)
        {
            CrashLogger.Log("BubbleWindow.DefaultBackgroundColor.Theme", ex);
        }
    }

    private static void TryApplyFallbackOpaqueBackground(WebView2 webView)
    {
        try
        {
            webView.DefaultBackgroundColor = System.Drawing.Color.FromArgb(255, 255, 255, 255);
        }
        catch
        {
            // Ignore secondary failure.
        }
    }

    private void TryApplyFallbackOpaqueBackground() => TryApplyFallbackOpaqueBackground(WebView);

    private static System.Drawing.Color GetOpaqueBackgroundForTheme(string theme) =>
        theme == "light"
            ? System.Drawing.Color.FromArgb(255, 243, 238, 226)
            : System.Drawing.Color.FromArgb(255, 23, 17, 9);

    private void UpdateRoundedWindowClip()
    {
        if (Width <= 0 || Height <= 0)
            return;

        Clip = new RectangleGeometry(new Rect(0, 0, Width, Height), BubbleCornerRadius, BubbleCornerRadius);
    }
}
