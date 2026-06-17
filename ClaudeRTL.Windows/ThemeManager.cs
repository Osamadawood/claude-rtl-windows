using System.Windows;
using System.Windows.Interop;
using Microsoft.Win32;

namespace ClaudeRTL;

public sealed class ThemeManager : IDisposable
{
    internal const int WM_SETTINGCHANGE = 0x001A;

    public static ThemeManager Instance { get; } = new();

    private readonly List<Func<Task>> _applyThemeHandlers = [];
    private HwndSource? _hwndSource;
    private string? _lastAppliedTheme;
    private bool _started;

    private ThemeManager() { }

    public void Start()
    {
        if (_started)
            return;

        var parameters = new HwndSourceParameters("ClaudeRTL.ThemeWatcher")
        {
            Width = 0,
            Height = 0,
            WindowStyle = 0,
            ParentWindow = new IntPtr(-3)
        };

        _hwndSource = new HwndSource(parameters);
        _hwndSource.AddHook(WndProc);
        _started = true;
    }

    public void Register(Func<Task> applyThemeAsync) => _applyThemeHandlers.Add(applyThemeAsync);

    public string EffectiveTheme() => ResolveEffectiveTheme(Settings.Instance.ThemeMode);

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

    public void ApplyToAllWebViews()
    {
        _lastAppliedTheme = null;
        ApplyToAllWebViewsIfNeeded();
    }

    public void ApplyToAllWebViewsIfNeeded()
    {
        var theme = EffectiveTheme();
        if (theme == _lastAppliedTheme)
            return;

        _lastAppliedTheme = theme;
        System.Windows.Application.Current.Dispatcher.InvokeAsync(async () =>
        {
            foreach (var handler in _applyThemeHandlers)
            {
                try
                {
                    await handler();
                }
                catch
                {
                    // Ignore theme apply failures on individual views.
                }
            }
        });
    }

    private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (msg == WM_SETTINGCHANGE && Settings.Instance.ThemeMode == ThemeMode.Auto)
        {
            System.Windows.Application.Current.Dispatcher.BeginInvoke(ApplyToAllWebViewsIfNeeded);
        }

        return IntPtr.Zero;
    }

    public void Dispose()
    {
        if (_hwndSource is not null)
        {
            _hwndSource.RemoveHook(WndProc);
            _hwndSource.Dispose();
            _hwndSource = null;
        }

        _started = false;
        _applyThemeHandlers.Clear();
    }
}
