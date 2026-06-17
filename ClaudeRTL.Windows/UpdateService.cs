namespace ClaudeRTL;

/// <summary>
/// Safe wrapper around WinSparkle. Every native call is guarded so a missing or
/// incompatible WinSparkle.dll can never crash the app — failures are logged to crash.log.
/// </summary>
internal static class UpdateService
{
    private const string AppcastUrl = "https://claude-rtl.grwlab.net/appcast-win.xml";

    private const string CompanyName = "GRW Lab";
    private const string AppName = "Claude RTL";
    private const int CheckIntervalSeconds = 86400; // 24 hours

    // DSA public key (PEM) used by WinSparkle 0.8.1 to verify update signatures.
    // The matching private key (dsa_priv.pem) must sign every release listed in the appcast.
    private const string DsaPublicKeyPem = @"-----BEGIN PUBLIC KEY-----
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
9Arc5tTcCAl2Zn2+eCZsrRbnj8/V+rA=
-----END PUBLIC KEY-----
";

    private static readonly object Sync = new();
    private static bool _initialized;

    public static void Initialize()
    {
        lock (Sync)
        {
            if (_initialized)
                return;

            try
            {
                WinSparkleInterop.win_sparkle_set_appcast_url(AppcastUrl);

                if (WinSparkleInterop.win_sparkle_set_dsa_pub_pem(DsaPublicKeyPem) != 1)
                    CrashLogger.Log("UpdateService.Initialize", "WinSparkle rejected the DSA public key (PEM).");

                WinSparkleInterop.win_sparkle_set_app_details(CompanyName, AppName, Settings.VersionLabel());
                WinSparkleInterop.win_sparkle_set_automatic_check_for_updates(
                    Settings.Instance.AutoCheckForUpdates ? 1 : 0);
                WinSparkleInterop.win_sparkle_set_update_check_interval(CheckIntervalSeconds);
                WinSparkleInterop.win_sparkle_init();

                _initialized = true;
            }
            catch (Exception ex)
            {
                CrashLogger.Log("UpdateService.Initialize", ex);
            }
        }
    }

    public static void CheckNow()
    {
        try
        {
            if (!_initialized)
                Initialize();

            WinSparkleInterop.win_sparkle_check_update_with_ui();
        }
        catch (Exception ex)
        {
            CrashLogger.Log("UpdateService.CheckNow", ex);
        }
    }

    public static void SetAutomaticCheck(bool enabled)
    {
        try
        {
            WinSparkleInterop.win_sparkle_set_automatic_check_for_updates(enabled ? 1 : 0);
        }
        catch (Exception ex)
        {
            CrashLogger.Log("UpdateService.SetAutomaticCheck", ex);
        }
    }

    public static void Shutdown()
    {
        lock (Sync)
        {
            if (!_initialized)
                return;

            try
            {
                WinSparkleInterop.win_sparkle_cleanup();
            }
            catch (Exception ex)
            {
                CrashLogger.Log("UpdateService.Shutdown", ex);
            }
            finally
            {
                _initialized = false;
            }
        }
    }
}
