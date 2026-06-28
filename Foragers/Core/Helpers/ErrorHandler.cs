using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

namespace Foragers.Core.Helpers;

public static class ErrorHandler
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int MessageBox(IntPtr hWnd, string text, string caption, uint type);

    private const uint MB_OK = 0x00000000;
    private const uint MB_ICONERROR = 0x00000010;
    private const uint MB_SETFOREGROUND = 0x00010000;

    public static void ShowError(string title, string message)
    {
        StringBuilder sb = new();
        sb.AppendLine(message);
        sb.AppendLine();
        sb.AppendLine("The application will now close.");

        string fullMessage = sb.ToString();
        LogToAll($"[ERROR] {title}: {fullMessage}");

        _ = MessageBox(IntPtr.Zero, fullMessage, title, MB_OK | MB_ICONERROR | MB_SETFOREGROUND);
    }

    public static void ShowError(string title, Exception ex)
    {
        StringBuilder sb = new();
        sb.AppendLine($"Error: {ex.Message}");

        if (ex.InnerException != null)
        {
            sb.AppendLine();
            sb.AppendLine($"Inner: {ex.InnerException.Message}");
        }

        sb.AppendLine();
        sb.AppendLine("The application will now close.");

        string fullMessage = sb.ToString();
        LogToAll($"[ERROR] {title}: {fullMessage}");
        LogToAll(ex.StackTrace ?? "No stack trace");

        _ = MessageBox(IntPtr.Zero, fullMessage, title, MB_OK | MB_ICONERROR | MB_SETFOREGROUND);
    }

    private static void LogToAll(string message)
    {
        Console.Error.WriteLine(message);
        Debug.WriteLine(message);

        try
        {
            string logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "error.log");
            File.AppendAllText(logPath, $"[{DateTime.Now}] {message}{Environment.NewLine}");
        }
        catch { }
    }
}
