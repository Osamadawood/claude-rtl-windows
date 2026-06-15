namespace ClaudeRTL;

/// <summary>
/// App settings. Launch-at-login registry wiring arrives in Increment 6.
/// </summary>
public sealed class Settings
{
    public static Settings Instance { get; } = new();

    private Settings() { }

    public bool LaunchAtLogin { get; set; }
}
