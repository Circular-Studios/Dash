/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module ClipText;

import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.utf;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}
import std.windows.charset;

pragma(lib, "gdi32.lib");

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;

import resource;

string appName     = "ClipText";
string description = "Clipboard Text Transfers - Unicode Version";
enum ID_TIMER = 1;
HINSTANCE hinst;

enum szDefaultText = "Default Text - Unicode Version";
enum szCaption     = "Clipboard Text Transfers - Unicode Version";

alias CF_UNICODETEXT CF_TCHAR;
enum GMEM_SHARE = 8192;

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
    hinst = hInstance;
    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;
    HACCEL hAccel;

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH) GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = appName.toUTF16z;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

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

    hAccel = LoadAccelerators(hInstance, appName.toUTF16z);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        if (!TranslateAccelerator(hwnd, hAccel, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return msg.wParam;
}

wstring fromWStringz(const wchar* s)
{
    if (s is null) return null;

    wchar* ptr;
    for (ptr = cast(wchar*)s; *ptr; ++ptr) {}

    return to!wstring(s[0..ptr-s]);
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static wstring pText;
    BOOL bEnable;
    HGLOBAL hGlobal;
    HDC hdc;
    PTSTR pGlobal;
    PAINTSTRUCT ps;
    RECT rect;

    switch (message)
    {
        case WM_CREATE:
            SendMessage(hwnd, WM_COMMAND, IDM_EDIT_RESET, 0);
            return 0;

        case WM_INITMENUPOPUP:
            EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_PASTE,
                           IsClipboardFormatAvailable(CF_TCHAR) ? MF_ENABLED : MF_GRAYED);

            bEnable = pText.length ? MF_ENABLED : MF_GRAYED;

            EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_CUT,   bEnable);
            EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_COPY,  bEnable);
            EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_CLEAR, bEnable);
            break;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_EDIT_PASTE:
                    OpenClipboard(hwnd);

                    hGlobal = GetClipboardData(CF_TCHAR);

                    if (hGlobal !is null)
                    {
                        pGlobal = cast(wchar*)GlobalLock(hGlobal);
                        pText   = fromWStringz(pGlobal);
                        InvalidateRect(hwnd, NULL, TRUE);
                    }

                    CloseClipboard();
                    return 0;

                case IDM_EDIT_CUT:
                case IDM_EDIT_COPY:

                    if (!pText.length)
                        return 0;

                    hGlobal = GlobalAlloc(GHND | GMEM_SHARE, (pText.length + 1) * wchar.sizeof);
                    pGlobal = cast(wchar*) GlobalLock(hGlobal);
                    pGlobal[0..pText.length] = pText[];
                    GlobalUnlock(hGlobal);

                    OpenClipboard(hwnd);
                    EmptyClipboard();
                    SetClipboardData(CF_TCHAR, hGlobal);
                    CloseClipboard();

                    if (LOWORD(wParam) == IDM_EDIT_COPY)
                        return 0;

                    goto case IDM_EDIT_CLEAR;

                case IDM_EDIT_CLEAR:
                    pText = "";
                    InvalidateRect(hwnd, NULL, TRUE);
                    return 0;

                case IDM_EDIT_RESET:
                    pText = szDefaultText;
                    InvalidateRect(hwnd, NULL, TRUE);
                    return 0;

                default:
            }

            break;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);
            GetClientRect(hwnd, &rect);

            if (pText.length)
                DrawText(hdc, to!string(pText).toUTF16z, -1, &rect, DT_EXPANDTABS | DT_WORDBREAK);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
