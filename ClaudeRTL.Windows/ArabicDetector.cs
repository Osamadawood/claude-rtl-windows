using System.Text.RegularExpressions;

namespace ClaudeRTL;

internal static partial class ArabicDetector
{
    [GeneratedRegex(@"[\u0600-\u06FF]", RegexOptions.Compiled)]
    private static partial Regex ArabicPattern();

    public static bool ContainsArabic(string text) =>
        !string.IsNullOrEmpty(text) && ArabicPattern().IsMatch(text);
}
