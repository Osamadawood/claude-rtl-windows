using System.Text.RegularExpressions;

namespace ClaudeRTL;

internal static partial class ArabicDetector
{
    [GeneratedRegex(@"[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]", RegexOptions.Compiled)]
    private static partial Regex ArabicPattern();

    public static bool ContainsArabic(string text) =>
        !string.IsNullOrEmpty(text) && ArabicPattern().IsMatch(text);
}
