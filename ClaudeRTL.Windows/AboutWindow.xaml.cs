using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Media.Imaging;

namespace ClaudeRTL;

public partial class AboutWindow : Window
{
    public AboutWindow()
    {
        InitializeComponent();
        LoadIcon();

        var version = Assembly.GetExecutingAssembly().GetName().Version;
        VersionText.Text = version is null
            ? "Version 1.0.0"
            : $"Version {version.Major}.{version.Minor}.{version.Build}";
    }

    private void OnOpenWebsite(object sender, RoutedEventArgs e)
    {
        Process.Start(new ProcessStartInfo("https://grwlab.net")
        {
            UseShellExecute = true
        });
    }

    private void OnClose(object sender, RoutedEventArgs e) => Close();

    private void LoadIcon()
    {
        var iconPath = Path.Combine(AppContext.BaseDirectory, "Resources", "AppIcon.ico");
        if (!File.Exists(iconPath))
            return;

        IconImage.Source = BitmapFrame.Create(new Uri(iconPath, UriKind.Absolute));
    }
}
