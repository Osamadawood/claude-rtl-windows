using System.IO;
using System.Windows;
using Microsoft.Web.WebView2.Core;

namespace ClaudeRTL;

public sealed class OnboardingWindow : Window
{
    private static OnboardingWindow? _instance;

    public static void ShowIfNeeded()
    {
        if (Settings.Instance.DidOnboard)
            return;

        Open();
    }

    public static void Open()
    {
        if (_instance is { IsVisible: true })
        {
            _instance.Activate();
            return;
        }

        _instance = new OnboardingWindow();
        _instance.Show();
        _instance.Activate();
    }

    private readonly Microsoft.Web.WebView2.Wpf.WebView2 _webView = new();

    private OnboardingWindow()
    {
        Title = "Claude RTL";
        Width = 520;
        Height = 620;
        WindowStartupLocation = WindowStartupLocation.CenterScreen;
        Content = _webView;
        Loaded += async (_, _) => await InitializeWebViewAsync();
    }

    private async Task InitializeWebViewAsync()
    {
        var resourcesDir = Path.Combine(AppContext.BaseDirectory, "Resources");
        Directory.CreateDirectory(resourcesDir);

        var environment = await CoreWebView2Environment.CreateAsync(
            userDataFolder: Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "ClaudeRTL",
                "WebView2-Onboarding"));

        await _webView.EnsureCoreWebView2Async(environment);
        _webView.CoreWebView2.WebMessageReceived += OnWebMessageReceived;

        var onboardingPath = Path.Combine(resourcesDir, "onboarding.html");
        _webView.CoreWebView2.Navigate(new Uri(onboardingPath).AbsoluteUri);
    }

    private void OnWebMessageReceived(object? sender, CoreWebView2WebMessageReceivedEventArgs e)
    {
        try
        {
            using var doc = System.Text.Json.JsonDocument.Parse(e.WebMessageAsJson);
            if (!doc.RootElement.TryGetProperty("action", out var actionProp))
                return;

            if (actionProp.GetString() != "finish")
                return;

            Dispatcher.Invoke(() =>
            {
                Settings.Instance.DidOnboard = true;
                Settings.Instance.Save();
                Close();
            });
        }
        catch
        {
            // Ignore malformed messages.
        }
    }

    protected override void OnClosed(EventArgs e)
    {
        if (_webView.CoreWebView2 is not null)
            _webView.CoreWebView2.WebMessageReceived -= OnWebMessageReceived;

        base.OnClosed(e);
        _instance = null;
    }
}
