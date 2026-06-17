using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

namespace ClaudeRTL;

internal static class AppIconHelper
{
    public static string? IconToBase64Png(Icon? icon, int size = 22)
    {
        if (icon is null)
            return null;

        using var bitmap = new Bitmap(size, size);
        using (var graphics = Graphics.FromImage(bitmap))
        {
            graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            graphics.DrawIcon(icon, new Rectangle(0, 0, size, size));
        }

        using var stream = new MemoryStream();
        bitmap.Save(stream, ImageFormat.Png);
        return Convert.ToBase64String(stream.ToArray());
    }

    public static string? GetIconBase64ForExe(string? exePath, int size = 22)
    {
        if (string.IsNullOrWhiteSpace(exePath) || !File.Exists(exePath))
            return null;

        try
        {
            using var icon = Icon.ExtractAssociatedIcon(exePath);
            return IconToBase64Png(icon, size);
        }
        catch
        {
            return null;
        }
    }

    public static string? GetIconBase64ForApp(ProcessAppRecord app, int size = 22)
    {
        var fromPath = GetIconBase64ForExe(app.ExePath, size);
        if (fromPath is not null)
            return fromPath;

        try
        {
            foreach (var process in Process.GetProcessesByName(app.ProcessName))
            {
                try
                {
                    var path = process.MainModule?.FileName;
                    var iconData = GetIconBase64ForExe(path, size);
                    if (iconData is not null)
                        return iconData;
                }
                catch
                {
                    // Access denied for elevated/system processes.
                }
            }
        }
        catch
        {
            // Process name lookup failed.
        }

        return null;
    }
}
