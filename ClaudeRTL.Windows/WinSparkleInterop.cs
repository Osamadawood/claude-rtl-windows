using System.Runtime.InteropServices;

namespace ClaudeRTL;

/// <summary>
/// P/Invoke declarations for WinSparkle (https://winsparkle.org). The native
/// WinSparkle.dll (x64) is shipped next to the executable. All exports use the
/// C calling convention (cdecl).
/// </summary>
internal static class WinSparkleInterop
{
    private const string Dll = "WinSparkle.dll";

    /// <summary>Sets the URL of the appcast XML feed (ASCII URL).</summary>
    [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void win_sparkle_set_appcast_url([MarshalAs(UnmanagedType.LPStr)] string url);

    /// <summary>
    /// Sets the DSA public key (PEM) used to verify update signatures. This is the
    /// correct API for WinSparkle 0.8.1. Returns 1 if the PEM is a valid DSA key, 0 otherwise.
    /// </summary>
    [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int win_sparkle_set_dsa_pub_pem([MarshalAs(UnmanagedType.LPStr)] string dsaPubPem);

    /// <summary>Sets the company, application name and version (wide strings).</summary>
    [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void win_sparkle_set_app_details(
        [MarshalAs(UnmanagedType.LPWStr)] string companyName,
        [MarshalAs(UnmanagedType.LPWStr)] string appName,
        [MarshalAs(UnmanagedType.LPWStr)] string appVersion);

    /// <summary>Enables (1) or disables (0) automatic background update checks.</summary>
    [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void win_sparkle_set_automatic_check_for_updates(int state);

    /// <summary>Sets the automatic update check interval, in seconds (minimum 3600).</summary>
    [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void win_sparkle_set_update_check_interval(int intervalSeconds);

    /// <summary>Starts WinSparkle. Must be called after configuration.</summary>
    [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void win_sparkle_init();

    /// <summary>Checks for updates and shows the WinSparkle UI to the user.</summary>
    [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void win_sparkle_check_update_with_ui();

    /// <summary>Shuts WinSparkle down and releases its resources.</summary>
    [DllImport(Dll, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void win_sparkle_cleanup();
}
