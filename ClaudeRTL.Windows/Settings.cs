using System.IO;
using System.Text.Json;
using System.Windows;
using Microsoft.Win32;

namespace ClaudeRTL;

public sealed class Settings
{
    private const string RunKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string RunValueName = "ClaudeRTL";

    public static Settings Instance { get; } = new();

    private static string SettingsDirectory =>
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "ClaudeRTL");

    private static string SettingsPath => Path.Combine(SettingsDirectory, "settings.json");

    private Settings() { }

    public bool LaunchAtLogin { get; set; }
    public bool DidOnboard { get; set; }
    public bool IsEnabled { get; set; } = true;
    public double FontSize { get; set; } = 16;

    public void Load()
    {
        try
        {
            if (!File.Exists(SettingsPath))
            {
                LaunchAtLogin = IsLaunchAtLoginRegistered();
                return;
            }

            var json = File.ReadAllText(SettingsPath);
            var loaded = JsonSerializer.Deserialize<SettingsData>(json);
            if (loaded is null)
                return;

            DidOnboard = loaded.DidOnboard;
            IsEnabled = loaded.IsEnabled;
            FontSize = loaded.FontSize > 0 ? loaded.FontSize : 16;
            LaunchAtLogin = loaded.LaunchAtLogin;
        }
        catch
        {
            LaunchAtLogin = IsLaunchAtLoginRegistered();
        }
    }

    public void Save()
    {
        Directory.CreateDirectory(SettingsDirectory);
        var data = new SettingsData
        {
            DidOnboard = DidOnboard,
            IsEnabled = IsEnabled,
            FontSize = FontSize,
            LaunchAtLogin = LaunchAtLogin
        };

        var json = JsonSerializer.Serialize(data, new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(SettingsPath, json);
    }

    public void SetLaunchAtLogin(bool enabled)
    {
        LaunchAtLogin = enabled;
        using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, writable: true);
        if (key is null)
            return;

        if (enabled)
        {
            var exePath = Environment.ProcessPath ?? Application.ResourceAssembly.Location;
            key.SetValue(RunValueName, $"\"{exePath}\"");
        }
        else
        {
            key.DeleteValue(RunValueName, throwOnMissingValue: false);
        }

        Save();
    }

    public bool IsLaunchAtLoginRegistered()
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, writable: false);
        return key?.GetValue(RunValueName) is not null;
    }

    private sealed class SettingsData
    {
        public bool DidOnboard { get; set; }
        public bool IsEnabled { get; set; } = true;
        public double FontSize { get; set; } = 16;
        public bool LaunchAtLogin { get; set; }
    }
}
