namespace ClaudeRTL;

public sealed class Settings
{
    public static Settings Instance { get; } = new();

    private Settings() { }

    public bool LaunchAtLogin { get; set; }
    public bool IsEnabled { get; set; } = true;
}
