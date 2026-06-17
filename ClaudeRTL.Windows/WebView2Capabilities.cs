using Microsoft.Web.WebView2.Core;

namespace ClaudeRTL;

internal static class WebView2Capabilities
{
    private static readonly Version TransparentBackgroundMinRuntime = new(1, 0, 1210, 39);

    public static bool SupportsTransparentBackground()
    {
        try
        {
            var raw = CoreWebView2Environment.GetAvailableBrowserVersionString();
            var versionToken = raw.Split(' ', StringSplitOptions.RemoveEmptyEntries)[0];
            return Version.TryParse(versionToken, out var version) && version >= TransparentBackgroundMinRuntime;
        }
        catch
        {
            return false;
        }
    }
}
