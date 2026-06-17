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

    private void OnWebMessageReceived(object? sender, CoreWebView2WebMessageReceivedEventArgs e)
    {
        try
        {
            var message = JsonSerializer.Deserialize<BridgeMessage>(
                e.WebMessageAsJson,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            if (message?.Action is not null)
                MessageReceived?.Invoke(message);
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

    [JsonPropertyName("h")]
    public double? H { get; set; }

    [JsonPropertyName("scope")]
    public string? Scope { get; set; }

    [JsonPropertyName("process")]
    public string? Process { get; set; }

    [JsonPropertyName("name")]
    public string? Name { get; set; }

    [JsonPropertyName("bundleId")]
    public string? BundleId { get; set; }
}
