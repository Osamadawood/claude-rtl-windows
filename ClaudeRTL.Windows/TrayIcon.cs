using System.Drawing;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using Hardcodet.Wpf.TaskbarNotification;

namespace ClaudeRTL;

public sealed class TrayIcon : IDisposable
{
    private readonly TaskbarIcon _taskbarIcon;
    private readonly MenuItem _excludeAppItem;
    private readonly MenuItem _excludeSessionItem;
    private readonly MenuItem _excludeAlwaysItem;
    private ForegroundAppInfo? _menuTargetApp;

    public TrayIcon()
    {
        _excludeSessionItem = new MenuItem { Header = "هذه الجلسة" };
        _excludeSessionItem.Click += OnExcludeSession;

        _excludeAlwaysItem = new MenuItem { Header = "دائمًا" };
        _excludeAlwaysItem.Click += OnExcludeAlways;

        var excludeSubmenu = new MenuItem
        {
            Header = "إيقاف على …",
            Items = { _excludeSessionItem, _excludeAlwaysItem }
        };

        _excludeAppItem = excludeSubmenu;

        var contextMenu = new ContextMenu
        {
            FlowDirection = FlowDirection.RightToLeft
        };
        contextMenu.Opened += OnContextMenuOpened;

        var settingsItem = new MenuItem { Header = "الإعدادات…" };
        settingsItem.Click += (_, _) => SettingsWindow.Open();

        var quitItem = new MenuItem { Header = "خروج" };
        quitItem.Click += (_, _) => System.Windows.Application.Current.Shutdown();

        contextMenu.Items.Add(settingsItem);
        contextMenu.Items.Add(_excludeAppItem);
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

    private void OnContextMenuOpened(object? sender, RoutedEventArgs e)
    {
        _menuTargetApp = ForegroundAppWatcher.GetForegroundApp();
        if (_menuTargetApp is { } app && !string.IsNullOrEmpty(app.ProcessName))
        {
            _excludeAppItem.Header = $"إيقاف على {app.DisplayName}";
            _excludeAppItem.IsEnabled = true;
        }
        else
        {
            _excludeAppItem.Header = "إيقاف على …";
            _excludeAppItem.IsEnabled = false;
        }
    }

    private void OnExcludeSession(object sender, RoutedEventArgs e)
    {
        if (_menuTargetApp is not { ProcessName: var processName })
            return;

        Settings.Instance.ExcludeForSession(processName);
        SettingsWindow.ReloadIfOpen();
    }

    private void OnExcludeAlways(object sender, RoutedEventArgs e)
    {
        if (_menuTargetApp is not { ProcessName: var processName, DisplayName: var displayName })
            return;

        Settings.Instance.ExcludePermanently(processName, displayName);
        SettingsWindow.ReloadIfOpen();
    }

    public void Dispose() => _taskbarIcon.Dispose();
}
