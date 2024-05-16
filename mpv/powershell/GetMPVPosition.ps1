Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class User32 {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("gdi32.dll", SetLastError = true)]
    public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr GetDC(IntPtr hWnd);
}

[StructLayout(LayoutKind.Sequential)]
public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

public static class WindowHelper {
    private const int MaxTitleLength = 256;
    private const int LOGPIXELSX = 88;
    private const int LOGPIXELSY = 90;

    public static string GetMPVPosition() {
        IntPtr mpvHandle = IntPtr.Zero;

        User32.EnumWindows(new User32.EnumWindowsProc((hWnd, lParam) => {
            StringBuilder title = new StringBuilder(MaxTitleLength);
            User32.GetWindowText(hWnd, title, MaxTitleLength);
            if (title.ToString().Contains("mpv") && User32.IsWindowVisible(hWnd)) {
                mpvHandle = hWnd;
                return false; // Stop enumeration
            }
            return true; // Continue enumeration
        }), IntPtr.Zero);

        if (mpvHandle == IntPtr.Zero) {
            return "0,0";
        }

        RECT rct;
        if (User32.GetWindowRect(mpvHandle, out rct)) {
            IntPtr hdc = User32.GetDC(mpvHandle);
            int dpiX = User32.GetDeviceCaps(hdc, LOGPIXELSX);
            float scalingFactor = dpiX / 96.0f; // 96 DPI is the default scaling base

            int adjustedLeft = (int)(rct.Left / scalingFactor);
            int adjustedTop = (int)(rct.Top / scalingFactor);
            return adjustedLeft + "," + adjustedTop;
        }
        return "0,0";
    }
}
"@

# Debug output
Write-Host "Attempting to find MPV window..."
$position = [WindowHelper]::GetMPVPosition()
Write-Host "MPV window position: $position"
[Console]::WriteLine($position)
