using System.Windows;

namespace ClaudeRTL;

public partial class App : System.Windows.Application
{
    private TrayIcon? _trayIcon;
    private ApplicationCoordinator? _coordinator;

    protected override void OnStartup(StartupEventArgs e)
    {
        CrashLogger.Initialize();
        CrashLogger.AttachDispatcher(Dispatcher);

        base.OnStartup(e);

        if (!SingleInstanceManager.TryBecomeSingleInstance())
        {
            Shutdown();
            return;
        }

        SingleInstanceManager.SettingsRequested += () => SettingsWindow.Open();

        if (!WebView2RuntimeCheck.IsInstalled())
        {
            WebView2RuntimeCheck.PromptInstall();
            Shutdown();
            return;
        }

        var trayOnly = e.Args.Contains("--tray-only", StringComparer.OrdinalIgnoreCase);

        Settings.Instance.Load();
        ThemeManager.Instance.Start();
        _coordinator = new ApplicationCoordinator();
        _coordinator.Start();
        _trayIcon = new TrayIcon();

        if (!Settings.Instance.DidOnboard)
        {
            OnboardingWindow.ShowIfNeeded();
        }
        else if (!trayOnly)
        {
            SettingsWindow.Open();
        }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        Settings.Instance.Save();
        _coordinator?.Dispose();
        ThemeManager.Instance.Dispose();
        SingleInstanceManager.Dispose();
        _trayIcon?.Dispose();
        base.OnExit(e);
    }
}
