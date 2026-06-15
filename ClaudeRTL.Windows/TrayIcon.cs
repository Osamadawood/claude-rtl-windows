using System.Drawing;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using Hardcodet.Wpf.TaskbarNotification;

namespace ClaudeRTL;

public sealed class TrayIcon : IDisposable
{
    private readonly TaskbarIcon _taskbarIcon;
    private readonly MenuItem _launchAtLoginItem;

    public TrayIcon()
    {
        _launchAtLoginItem = new MenuItem
        {
            Header = "تشغيل عند بدء النظام",
            IsCheckable = true,
            IsChecked = Settings.Instance.LaunchAtLogin
        };
        _launchAtLoginItem.Click += OnToggleLaunchAtLogin;

        var contextMenu = new ContextMenu
        {
            FlowDirection = FlowDirection.RightToLeft
        };

        var aboutItem = new MenuItem { Header = "حول Claude RTL" };
        aboutItem.Click += OnShowAbout;

        var onboardingItem = new MenuItem { Header = "إعادة الشرح" };
        onboardingItem.Click += OnShowOnboarding;

        var quitItem = new MenuItem { Header = "خروج" };
        quitItem.Click += OnQuit;

        contextMenu.Items.Add(aboutItem);
        contextMenu.Items.Add(onboardingItem);
        contextMenu.Items.Add(_launchAtLoginItem);
        contextMenu.Items.Add(new Separator());
        contextMenu.Items.Add(quitItem);

        _taskbarIcon = new TaskbarIcon
        {
            ToolTipText = "Claude RTL",
            Icon = LoadIcon(),
            ContextMenu = contextMenu
        };
    }

    private static Icon LoadIcon()
    {
        var iconPath = Path.Combine(AppContext.BaseDirectory, "Resources", "AppIcon.ico");
        return File.Exists(iconPath)
            ? new Icon(iconPath)
            : SystemIcons.Application;
    }

    private void OnShowAbout(object sender, RoutedEventArgs e)
    {
        var about = new AboutWindow();
        about.ShowDialog();
    }

    private void OnShowOnboarding(object sender, RoutedEventArgs e) => OnboardingWindow.Show();

    private void OnToggleLaunchAtLogin(object sender, RoutedEventArgs e)
    {
        Settings.Instance.SetLaunchAtLogin(_launchAtLoginItem.IsChecked);
    }

    private void OnQuit(object sender, RoutedEventArgs e) => Application.Current.Shutdown();

    public void Dispose() => _taskbarIcon.Dispose();
}
