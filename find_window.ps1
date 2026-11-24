Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  using System.Text;
  public class WinUtil {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
"@

$list = [System.Collections.ArrayList]::new()
[WinUtil]::EnumWindows({
    param($hwnd, $lparam)
    $sb = New-Object System.Text.StringBuilder 256
    [WinUtil]::GetWindowText($hwnd, $sb, 256) | Out-Null
    $title = $sb.ToString()
    if ($title -like "*VirtualBox*" -or $title -like "*MicroVerse*") {
        $pid = 0
        [WinUtil]::GetWindowThreadProcessId($hwnd, [ref]$pid) | Out-Null
        $vis = [WinUtil]::IsWindowVisible($hwnd)
        Write-Host "HWND: $hwnd | PID: $pid | Visible: $vis | Title: '$title'"
        # Bring to foreground and restore
        [WinUtil]::ShowWindow($hwnd, 9) | Out-Null # SW_RESTORE
        [WinUtil]::SetForegroundWindow($hwnd) | Out-Null
    }
    return $true
}, [IntPtr]::Zero) | Out-Null
