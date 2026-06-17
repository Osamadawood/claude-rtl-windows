using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Win32;

namespace ClaudeRTL;

public enum TriggerMode
{
    AllApps,
    ClaudeOnly,
    CustomList
}

public enum ThemeMode
{
    Auto,
    Light,
    Dark
}

public sealed class ProcessAppRecord
{
    public string ProcessName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? ExePath { get; set; }
}

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
    public bool AutoCheckForUpdates { get; set; } = true;
    public double FontSize { get; set; } = 16;
    public TriggerMode TriggerMode { get; set; } = TriggerMode.AllApps;
    public ThemeMode ThemeMode { get; set; } = ThemeMode.Auto;
    public List<ProcessAppRecord> IncludedApps { get; set; } = [];
    public List<ProcessAppRecord> ExcludedAppsAlways { get; set; } = [];

    /// <summary>Session-only exclusions; cleared on each launch.</summary>
    public HashSet<string> ExcludedProcessesSession { get; } = new(StringComparer.OrdinalIgnoreCase);

    public IReadOnlyList<string> IncludedProcesses =>
        IncludedApps.Select(a => a.ProcessName).ToList();

    public IReadOnlyList<string> ExcludedProcessesAlways =>
        ExcludedAppsAlways.Select(a => a.ProcessName).ToList();

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
            AutoCheckForUpdates = loaded.AutoCheckForUpdates;
            FontSize = loaded.FontSize > 0 ? loaded.FontSize : 16;
            LaunchAtLogin = loaded.LaunchAtLogin;
            TriggerMode = Enum.TryParse<TriggerMode>(loaded.TriggerMode, out var mode)
                ? mode
                : TriggerMode.AllApps;
            ThemeMode = Enum.TryParse<ThemeMode>(loaded.ThemeMode, out var theme)
                ? theme
                : ThemeMode.Auto;
            IncludedApps = loaded.IncludedApps ?? [];
            ExcludedAppsAlways = loaded.ExcludedAppsAlways ?? [];

            foreach (var app in IncludedApps.Concat(ExcludedAppsAlways))
            {
                if (!string.IsNullOrEmpty(app.ProcessName))
                    app.ProcessName = app.ProcessName.ToLowerInvariant();
            }
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
            AutoCheckForUpdates = AutoCheckForUpdates,
            FontSize = FontSize,
            LaunchAtLogin = LaunchAtLogin,
            TriggerMode = TriggerMode.ToString(),
            ThemeMode = ThemeMode.ToString(),
            IncludedApps = IncludedApps,
            ExcludedAppsAlways = ExcludedAppsAlways
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
            var exePath = Environment.ProcessPath
                ?? Path.Combine(AppContext.BaseDirectory, "ClaudeRTL.exe");
            key.SetValue(RunValueName, $"\"{exePath}\" --tray-only");
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

    public void ExcludeForSession(string processName)
    {
        if (string.IsNullOrWhiteSpace(processName))
            return;

        ExcludedProcessesSession.Add(processName.ToLowerInvariant());
    }

    public void ExcludePermanently(string processName, string? displayName = null, string? exePath = null)
    {
        processName = processName.ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(processName))
            return;

        if (ExcludedAppsAlways.Any(a => string.Equals(a.ProcessName, processName, StringComparison.OrdinalIgnoreCase)))
            return;

        ExcludedAppsAlways.Add(new ProcessAppRecord
        {
            ProcessName = processName,
            DisplayName = displayName ?? processName,
            ExePath = exePath
        });
        Save();
    }

    public void RemoveExcludedPermanently(string processName)
    {
        ExcludedAppsAlways.RemoveAll(a =>
            string.Equals(a.ProcessName, processName, StringComparison.OrdinalIgnoreCase));
        Save();
    }

    public void AddIncludedApp(string processName, string displayName, string? exePath = null)
    {
        processName = processName.ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(processName))
            return;

        if (IncludedApps.Any(a => string.Equals(a.ProcessName, processName, StringComparison.OrdinalIgnoreCase)))
            return;

        IncludedApps.Add(new ProcessAppRecord
        {
            ProcessName = processName,
            DisplayName = displayName,
            ExePath = exePath
        });
        Save();
    }

    public void RemoveIncludedApp(string processName)
    {
        IncludedApps.RemoveAll(a =>
            string.Equals(a.ProcessName, processName, StringComparison.OrdinalIgnoreCase));
        Save();
    }

    public void ResetFontSize() => FontSize = 16;

    public void ResetAllSettingsExceptLaunchAtLogin()
    {
        TriggerMode = TriggerMode.AllApps;
        ExcludedAppsAlways.Clear();
        IncludedApps.Clear();
        ExcludedProcessesSession.Clear();
        FontSize = 16;
        ThemeMode = ThemeMode.Auto;
        Save();
    }

    public static string VersionLabel() =>
        typeof(Settings).Assembly.GetName().Version?.ToString(3) ?? "1.1.0";

    public static bool IsClaudeProcess(string processName, string? displayName)
    {
        var name = processName.ToLowerInvariant();
        var title = displayName?.ToLowerInvariant() ?? string.Empty;
        return name.Contains("claude") || name.Contains("anthropic") || title == "claude";
    }

    private sealed class SettingsData
    {
        public bool DidOnboard { get; set; }
        public bool IsEnabled { get; set; } = true;
        public bool AutoCheckForUpdates { get; set; } = true;
        public double FontSize { get; set; } = 16;
        public bool LaunchAtLogin { get; set; }
        public string? TriggerMode { get; set; }
        public string? ThemeMode { get; set; }
        public List<ProcessAppRecord>? IncludedApps { get; set; }
        public List<ProcessAppRecord>? ExcludedAppsAlways { get; set; }
    }
}
