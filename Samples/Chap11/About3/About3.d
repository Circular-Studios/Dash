/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module About3;

import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.utf : count, toUTFz;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;

import resource;

string appName     = "About3";
string description = "About Box Demo Program";
enum ID_TIMER = 1;
HINSTANCE hinst;

extern (Windows)
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    int result;
    void exceptionHandler(Throwable e) { throw e; }

    try
    {
        Runtime.initialize(&exceptionHandler);
        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, iCmdShow);
        Runtime.terminate(&exceptionHandler);
    }
    catch (Throwable o)
    {
        MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(hInstance, appName.toUTF16z);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH)GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = appName.toUTF16z;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &EllipPushWndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = NULL;
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH)(COLOR_BTNFACE + 1);

    // ~ wndclass.hbrBackground = cast(HBRUSH)(COLOR_WINDOW + 1);
    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = "EllipPush";

    RegisterClass(&wndclass);

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        description.toUTF16z,          // window caption
                        WS_OVERLAPPEDWINDOW,           // window style
                        CW_USEDEFAULT,                 // initial x position
                        CW_USEDEFAULT,                 // initial y position
                        CW_USEDEFAULT,                 // initial x size
                        CW_USEDEFAULT,                 // initial y size
                        NULL,                          // parent window handle
                        NULL,                          // window menu handle
                        hInstance,                     // program instance handle
                        NULL);                         // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HINSTANCE hInstance;

    switch (message)
    {
        case WM_CREATE:
            hInstance = (cast(LPCREATESTRUCT)lParam).hInstance;
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_APP_ABOUT:
                    DialogBox(hInstance, "AboutBox", hwnd, &AboutDlgProc);
                    break;
                
                default:
            }

            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern (Windows)
BOOL AboutDlgProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_INITDIALOG:
            return true;

        case WM_COMMAND:
        {
            switch (LOWORD(wParam))
            {
                case IDOK:
                    EndDialog(hDlg, 0);
                    return true;

                default:
            }

            break;
        }

        default:
    }

    return false;
}

extern (Windows)
LRESULT EllipPushWndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    TCHAR[40] szText;
    HBRUSH hBrush;
    HDC hdc;
    PAINTSTRUCT ps;
    RECT rect;

    switch (message)
    {
        case WM_PAINT:
            GetClientRect(hwnd, &rect);
            GetWindowText(hwnd, szText.ptr, szText.count);

            hdc = BeginPaint(hwnd, &ps);

            hBrush = CreateSolidBrush(GetSysColor(COLOR_WINDOW));
            hBrush = cast(HBRUSH)SelectObject(hdc, hBrush);
            SetBkColor(hdc, GetSysColor(COLOR_WINDOW));
            SetTextColor(hdc, GetSysColor(COLOR_WINDOWTEXT));

            Ellipse(hdc, rect.left, rect.top, rect.right, rect.bottom);
            DrawText(hdc, szText.ptr, -1, &rect, DT_SINGLELINE | DT_CENTER | DT_VCENTER);

            DeleteObject(SelectObject(hdc, hBrush));

            EndPaint(hwnd, &ps);
            return 0;

        case WM_KEYUP:

            if (wParam != VK_SPACE)
                break;

            goto case WM_LBUTTONUP;

        case WM_LBUTTONUP:
            SendMessage(GetParent(hwnd), WM_COMMAND, GetWindowLongPtr(hwnd, GWL_ID), cast(LPARAM)hwnd);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
