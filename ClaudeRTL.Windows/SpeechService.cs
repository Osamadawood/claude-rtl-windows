using System.Speech.Synthesis;
using System.Windows;

namespace ClaudeRTL;

internal sealed class SpeechService : IDisposable
{
    private SpeechSynthesizer? _synthesizer;
    private bool _speaking;

    public event Action<bool>? SpeakingChanged;
    public event Action<int, int>? SpeakProgress;

    public void Toggle(string text)
    {
        var trimmed = text.Trim();
        if (string.IsNullOrEmpty(trimmed))
            return;

        if (_speaking)
        {
            Stop();
            return;
        }

        Start(trimmed);
    }

    public void Stop()
    {
        if (_synthesizer is null)
            return;

        _synthesizer.SpeakAsyncCancelAll();
        _synthesizer.SpeakProgress -= OnSpeakProgress;
        _synthesizer.SpeakCompleted -= OnSpeakCompleted;
        _synthesizer.Dispose();
        _synthesizer = null;
        SetSpeaking(false);
    }

    private void Start(string text)
    {
        _synthesizer = new SpeechSynthesizer();
        _synthesizer.SpeakProgress += OnSpeakProgress;
        _synthesizer.SpeakCompleted += OnSpeakCompleted;

        var arabicVoice = _synthesizer.GetInstalledVoices()
            .FirstOrDefault(v => v.Enabled && v.VoiceInfo.Culture.Name.StartsWith("ar", StringComparison.OrdinalIgnoreCase));

        if (arabicVoice is null)
        {
            _synthesizer.Dispose();
            _synthesizer = null;
            MessageBox.Show(
                "ثبّت حزمة صوت عربية من إعدادات ويندوز (الوقت واللغة ← الكلام) ثم أعد المحاولة.",
                "Claude RTL",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
            return;
        }

        _synthesizer.SelectVoice(arabicVoice.VoiceInfo.Name);
        SetSpeaking(true);
        _synthesizer.SpeakAsync(text);
    }

    private void OnSpeakProgress(object? sender, SpeakProgressEventArgs e) =>
        SpeakProgress?.Invoke(e.CharacterPosition, e.CharacterCount);

    private void OnSpeakCompleted(object? sender, SpeakCompletedEventArgs e) => Stop();

    private void SetSpeaking(bool speaking)
    {
        _speaking = speaking;
        SpeakingChanged?.Invoke(speaking);
    }

    public void Dispose() => Stop();
}
