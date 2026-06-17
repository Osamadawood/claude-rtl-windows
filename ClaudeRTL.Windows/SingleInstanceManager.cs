namespace ClaudeRTL;

internal static class SingleInstanceManager
{
    private const string MutexName = "Global\\ClaudeRTL.SingleInstance";
    private const string EventName = "Global\\ClaudeRTL.ShowSettings";

    private static Mutex? _mutex;
    private static EventWaitHandle? _settingsEvent;
    private static Thread? _listenerThread;
    private static volatile bool _running;

    public static event Action? SettingsRequested;

    public static bool TryBecomeSingleInstance()
    {
        var createdNew = false;
        _mutex = new Mutex(true, MutexName, out createdNew);
        if (!createdNew)
        {
            try
            {
                using var existingEvent = EventWaitHandle.OpenExisting(EventName);
                existingEvent.Set();
            }
            catch
            {
                // Existing instance may not have created the event yet.
            }

            return false;
        }

        _settingsEvent = new EventWaitHandle(false, EventResetMode.AutoReset, EventName);
        _running = true;
        _listenerThread = new Thread(ListenForSettingsRequest)
        {
            IsBackground = true,
            Name = "ClaudeRTL.SettingsSignal"
        };
        _listenerThread.Start();
        return true;
    }

    private static void ListenForSettingsRequest()
    {
        while (_running && _settingsEvent is not null)
        {
            if (!_settingsEvent.WaitOne(TimeSpan.FromMilliseconds(500)))
                continue;

            System.Windows.Application.Current?.Dispatcher.BeginInvoke(() =>
                SettingsRequested?.Invoke());
        }
    }

    public static void Dispose()
    {
        _running = false;
        _settingsEvent?.Set();
        _listenerThread?.Join(TimeSpan.FromSeconds(1));
        _settingsEvent?.Dispose();
        _mutex?.ReleaseMutex();
        _mutex?.Dispose();
    }
}
