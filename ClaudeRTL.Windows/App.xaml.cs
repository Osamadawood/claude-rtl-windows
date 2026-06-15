using System.Windows;

namespace ClaudeRTL;

public partial class App : Application
{
    private TrayIcon? _trayIcon;
    private ApplicationCoordinator? _coordinator;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        _coordinator = new ApplicationCoordinator();
        _coordinator.Start();
        _trayIcon = new TrayIcon();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _coordinator?.Dispose();
        _trayIcon?.Dispose();
        base.OnExit(e);
    }
}
