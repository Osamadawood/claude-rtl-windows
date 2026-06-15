using System.Windows;

namespace ClaudeRTL;

public partial class App : System.Windows.Application
{
    private TrayIcon? _trayIcon;
    private ApplicationCoordinator? _coordinator;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        if (!WebView2RuntimeCheck.IsInstalled())
        {
            WebView2RuntimeCheck.PromptInstall();
            Shutdown();
            return;
        }

        Settings.Instance.Load();
        _coordinator = new ApplicationCoordinator();
        _coordinator.Start();
        _trayIcon = new TrayIcon();
        OnboardingWindow.ShowIfNeeded();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        Settings.Instance.Save();
        _coordinator?.Dispose();
        _trayIcon?.Dispose();
        base.OnExit(e);
    }
}
