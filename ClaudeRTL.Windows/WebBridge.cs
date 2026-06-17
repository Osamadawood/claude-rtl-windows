using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.Wpf;

namespace ClaudeRTL;

internal sealed class WebBridge
{
    private readonly WebView2 _webView;

    public event Action<BridgeMessage>? MessageReceived;

    public WebBridge(WebView2 webView) => _webView = webView;

    public void Attach()
    {
        _webView.CoreWebView2.WebMessageReceived += OnWebMessageReceived;
    }

    public void Detach()
    {
        if (_webView.CoreWebView2 is not null)
            _webView.CoreWebView2.WebMessageReceived -= OnWebMessageReceived;
    }

    public async Task ShowBubbleAsync(string text, double fontSize, bool arrowBelow, string appName, string appId)
    {
        var json = JsonSerializer.Serialize(text);
        var appNameJson = JsonSerializer.Serialize(appName);
        var appIdJson = JsonSerializer.Serialize(appId);
        await _webView.CoreWebView2.ExecuteScriptAsync(
            $"window.showBubble({json}, {fontSize.ToString(System.Globalization.CultureInfo.InvariantCulture)}, {(arrowBelow ? "true" : "false")}, {appNameJson}, {appIdJson})");
    }

    public async Task SetSpeakingAsync(bool speaking) =>
        await _webView.CoreWebView2.ExecuteScriptAsync($"window.setSpeaking({(speaking ? "true" : "false")})");

    public async Task HighlightRangeAsync(int location, int length) =>
        await _webView.CoreWebView2.ExecuteScriptAsync($"window.highlightRange({location}, {length})");

    public async Task ClearHighlightAsync() =>
        await _webView.CoreWebView2.ExecuteScriptAsync("window.clearHighlight()");

    public async Task SetThemeAsync(string theme) =>
        await _webView.CoreWebView2.ExecuteScriptAsync(
            $"window.setTheme({JsonSerializer.Serialize(theme)})");

    public async Task SetArrowBelowAsync(bool arrowBelow) =>
        await _webView.CoreWebView2.ExecuteScriptAsync(
            $"window.setArrowBelow({(arrowBelow ? "true" : "false")})");

    private void OnWebMessageReceived(object? sender, CoreWebView2WebMessageReceivedEventArgs e)
    {
        try
        {
            var message = JsonSerializer.Deserialize<BridgeMessage>(
                e.WebMessageAsJson,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            if (message?.Action is not null)
            {
                var dispatcher = System.Windows.Application.Current?.Dispatcher;
                if (dispatcher is not null && !dispatcher.CheckAccess())
                    dispatcher.Invoke(() => MessageReceived?.Invoke(message));
                else
                    MessageReceived?.Invoke(message);
            }
        }
        catch
        {
            // Ignore malformed messages from the page.
        }
    }
}

internal sealed class BridgeMessage
{
    [JsonPropertyName("action")]
    public string? Action { get; set; }

    [JsonPropertyName("text")]
    public string? Text { get; set; }

    [JsonPropertyName("w")]
    public double? W { get; set; }

    [JsonPropertyName("width")]
    public double? Width { get; set; }

    [JsonPropertyName("h")]
    public double? H { get; set; }

    [JsonPropertyName("height")]
    public double? Height { get; set; }

    [JsonPropertyName("scope")]
    public string? Scope { get; set; }

    [JsonPropertyName("process")]
    public string? Process { get; set; }

    [JsonPropertyName("name")]
    public string? Name { get; set; }

    [JsonPropertyName("bundleId")]
    public string? BundleId { get; set; }

    [JsonPropertyName("enabled")]
    public bool? Enabled { get; set; }

    [JsonPropertyName("mode")]
    public string? Mode { get; set; }

    [JsonPropertyName("theme")]
    public string? Theme { get; set; }

    [JsonPropertyName("size")]
    public double? Size { get; set; }

    [JsonPropertyName("url")]
    public string? Url { get; set; }
}
