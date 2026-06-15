using System.Diagnostics;
using System.Windows;
using Microsoft.Web.WebView2.Core;

namespace ClaudeRTL;

internal static class WebView2RuntimeCheck
{
    public static bool IsInstalled()
    {
        try
        {
            var version = CoreWebView2Environment.GetAvailableBrowserVersionString();
            return !string.IsNullOrWhiteSpace(version);
        }
        catch
        {
            return false;
        }
    }

    public static void PromptInstall()
    {
        var result = MessageBox.Show(
            "Claude RTL يحتاج Microsoft WebView2 Runtime.\n\nهل تريد فتح صفحة التحميل الآن؟",
            "Claude RTL",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (result == MessageBoxResult.Yes)
        {
            Process.Start(new ProcessStartInfo("https://go.microsoft.com/fwlink/p/?LinkId=2124703")
            {
                UseShellExecute = true
            });
        }
    }
}
