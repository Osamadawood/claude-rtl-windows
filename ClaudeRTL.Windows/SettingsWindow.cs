using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Windows;
using Microsoft.Web.WebView2.Core;
using Microsoft.Win32;

namespace ClaudeRTL;

public sealed class SettingsWindow : Window
{
    private static SettingsWindow? _instance;
    private readonly Microsoft.Web.WebView2.Wpf.WebView2 _webView = new();
    private WebBridge? _bridge;
    private bool _isReady;

    public static void Open()
    {
        System.Windows.Application.Current.Dispatcher.Invoke(() =>
        {
            if (_instance is { IsVisible: true })
            {
                _instance.Activate();
                return;
            }

            _instance = new SettingsWindow();
            _instance.Show();
            _instance.Activate();
        });
    }

    public static void ReloadIfOpen()
    {
        if (_instance is not null)
            _ = _instance.PushStateAsync();
    }

    private SettingsWindow()
    {
        Title = "Claude RTL — الإعدادات";
        Width = 640;
        Height = 520;
        MinWidth = 560;
        MinHeight = 460;
        WindowStartupLocation = WindowStartupLocation.CenterScreen;
        FlowDirection = FlowDirection.RightToLeft;
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
                "WebView2-Settings"));

        await _webView.EnsureCoreWebView2Async(environment);
        _bridge = new WebBridge(_webView);
        _bridge.MessageReceived += OnBridgeMessage;
        _bridge.Attach();

        var settingsPath = Path.Combine(resourcesDir, "settings.html");
        _webView.CoreWebView2.NavigationCompleted += async (_, e) =>
        {
            if (!e.IsSuccess)
                return;

            _isReady = true;
            await PushStateAsync();
            await ApplyThemeToWebViewAsync();
        };

        _webView.CoreWebView2.Navigate(new Uri(settingsPath).AbsoluteUri);
    }

    private async void OnBridgeMessage(BridgeMessage message)
    {
        switch (message.Action)
        {
            case "ready":
                await PushStateAsync();
                break;
            case "setEnabled":
                if (message.Enabled is bool enabled)
                {
                    Settings.Instance.IsEnabled = enabled;
                    Settings.Instance.Save();
                }
                break;
            case "setMode":
                if (Enum.TryParse<TriggerMode>(message.Mode, out var mode))
                {
                    Settings.Instance.TriggerMode = mode;
                    Settings.Instance.Save();
                    await PushStateAsync();
                }
                break;
            case "addExcluded":
                await PickAndAddAppAsync(exclude: true);
                break;
            case "addIncluded":
                await PickAndAddAppAsync(exclude: false);
                break;
            case "removeExcluded":
                if (!string.IsNullOrEmpty(message.Process))
                {
                    Settings.Instance.RemoveExcludedPermanently(message.Process);
                    await PushStateAsync();
                }
                break;
            case "removeIncluded":
                if (!string.IsNullOrEmpty(message.Process))
                {
                    Settings.Instance.RemoveIncludedApp(message.Process);
                    await PushStateAsync();
                }
                break;
            case "setFontSize":
                if (message.Size is > 0)
                {
                    Settings.Instance.FontSize = message.Size.Value;
                    Settings.Instance.Save();
                    await PushStateAsync();
                }
                break;
            case "setTheme":
                if (Enum.TryParse<ThemeMode>(message.Theme, out var themeMode))
                {
                    Settings.Instance.ThemeMode = themeMode;
                    Settings.Instance.Save();
                    await ApplyThemeToWebViewAsync();
                    await PushStateAsync();
                }
                break;
            case "setLaunchAtLogin":
                if (message.Enabled is bool launch)
                    Settings.Instance.SetLaunchAtLogin(launch);
                await PushStateAsync();
                break;
            case "showOnboarding":
                OnboardingWindow.Open();
                break;
            case "resetAll":
                Settings.Instance.ResetAllSettingsExceptLaunchAtLogin();
                await PushStateAsync();
                await ApplyThemeToWebViewAsync();
                break;
            case "openUrl":
                if (!string.IsNullOrEmpty(message.Url))
                {
                    try
                    {
                        Process.Start(new ProcessStartInfo(message.Url) { UseShellExecute = true });
                    }
                    catch
                    {
                        // Ignore failed URL opens.
                    }
                }
                break;
        }
    }

    private async Task PickAndAddAppAsync(bool exclude)
    {
        var dialog = new OpenFileDialog
        {
            Title = "اختر تطبيقًا",
            Filter = "التطبيقات (*.exe)|*.exe",
            CheckFileExists = true
        };

        if (dialog.ShowDialog() != true)
            return;

        var exePath = dialog.FileName;
        var processName = Path.GetFileNameWithoutExtension(exePath).ToLowerInvariant();
        var displayName = FileVersionInfo.GetVersionInfo(exePath).FileDescription;
        if (string.IsNullOrWhiteSpace(displayName))
            displayName = Path.GetFileNameWithoutExtension(exePath);

        if (exclude)
            Settings.Instance.ExcludePermanently(processName, displayName, exePath);
        else
            Settings.Instance.AddIncludedApp(processName, displayName, exePath);

        await PushStateAsync();
    }

    private async Task PushStateAsync()
    {
        if (!_isReady || _webView.CoreWebView2 is null)
            return;

        var state = BuildState();
        var json = JsonSerializer.Serialize(state);
        await _webView.CoreWebView2.ExecuteScriptAsync($"window.applyState({json})");
    }

    private async Task ApplyThemeToWebViewAsync()
    {
        if (_webView.CoreWebView2 is null)
            return;

        var theme = ResolveEffectiveTheme(Settings.Instance.ThemeMode);
        await _webView.CoreWebView2.ExecuteScriptAsync(
            $"window.setTheme({JsonSerializer.Serialize(theme)})");
    }

    internal static string ResolveEffectiveTheme(ThemeMode mode) => mode switch
    {
        ThemeMode.Light => "light",
        ThemeMode.Dark => "dark",
        _ => ReadSystemAppsUseLightTheme() ? "light" : "dark"
    };

    private static bool ReadSystemAppsUseLightTheme()
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(
                @"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", writable: false);
            var value = key?.GetValue("AppsUseLightTheme");
            return value is int i && i != 0;
        }
        catch
        {
            return true;
        }
    }

    internal static object BuildStateObject()
    {
        static object MapApp(ProcessAppRecord app) => new
        {
            processName = app.ProcessName,
            displayName = app.DisplayName,
            iconBase64 = AppIconHelper.GetIconBase64ForApp(app)
        };

        return new
        {
            isEnabled = Settings.Instance.IsEnabled,
            triggerMode = Settings.Instance.TriggerMode.ToString(),
            themeMode = Settings.Instance.ThemeMode.ToString(),
            fontSize = Settings.Instance.FontSize,
            launchAtLogin = Settings.Instance.LaunchAtLogin,
            version = Settings.VersionLabel(),
            excludedApps = Settings.Instance.ExcludedAppsAlways.Select(MapApp).ToList(),
            includedApps = Settings.Instance.IncludedApps.Select(MapApp).ToList()
        };
    }

    private static object BuildState() => BuildStateObject();

    protected override void OnClosed(EventArgs e)
    {
        _bridge?.Detach();
        base.OnClosed(e);
        _instance = null;
    }
}
