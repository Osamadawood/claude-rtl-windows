using System.Windows;

namespace ClaudeRTL;

public partial class BubbleWindow : Window
{
    public BubbleWindow()
    {
        InitializeComponent();
    }

    public void ShowPlainText(System.Drawing.Point cursor, string text)
    {
        PlainText.Text = text;
        Left = cursor.X + 12;
        Top = cursor.Y + 12;
        Show();
        Activate();
    }

    public void HideBubble() => Hide();
}
