using System.Runtime.InteropServices;
using System.Text;

namespace Foragers_Project.Core.Helpers;

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

        _ = MessageBox(IntPtr.Zero, sb.ToString(), title, MB_OK | MB_ICONERROR | MB_SETFOREGROUND);
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

        _ = MessageBox(IntPtr.Zero, sb.ToString(), title, MB_OK | MB_ICONERROR | MB_SETFOREGROUND);
    }
}
