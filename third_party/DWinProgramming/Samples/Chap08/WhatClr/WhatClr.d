/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module WhatClr;

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

pragma(lib, "gdi32.lib");

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;

enum ID_TIMER = 1;

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
    string appName = "WhatClr";

    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH)GetStockObject(WHITE_BRUSH);

    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    int cxWindow, cyWindow;
    FindWindowSize(cxWindow, cyWindow);

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        "What Color",                  // window caption
                        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_BORDER,           // window style
                        CW_USEDEFAULT,                 // initial x position
                        CW_USEDEFAULT,                 // initial y position
                        cxWindow,                      // initial x size
                        cyWindow,                      // initial y size
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

void FindWindowSize(ref int pcxWindow, ref int pcyWindow)
{
    HDC hdcScreen;
    TEXTMETRIC tm;

    hdcScreen = CreateIC("DISPLAY", NULL, NULL, NULL);
    GetTextMetrics(hdcScreen, &tm);
    DeleteDC(hdcScreen);

    pcxWindow = 2 * GetSystemMetrics(SM_CXBORDER) + 12 * tm.tmAveCharWidth;

    pcyWindow = 2 * GetSystemMetrics(SM_CYBORDER) + GetSystemMetrics(SM_CYCAPTION) +
                2 * tm.tmHeight;
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static COLORREF cr;
    static COLORREF crLast;
    static HDC hdcScreen;
    HDC hdc;
    PAINTSTRUCT ps;
    POINT  pt;
    RECT   rc;
    string szBuffer;

    switch (message)
    {
        case WM_CREATE:
            hdcScreen = CreateDC("DISPLAY", NULL, NULL, NULL);

            SetTimer(hwnd, ID_TIMER, 100, NULL);
            return 0;

        case WM_TIMER:
            GetCursorPos(&pt);
            cr = GetPixel(hdcScreen, pt.x, pt.y);

            if (cr != crLast)
            {
                crLast = cr;
                InvalidateRect(hwnd, NULL, FALSE);
            }

            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            GetClientRect(hwnd, &rc);

            szBuffer = format("  %02X %02X %02X  ", GetRValue(cr), GetGValue(cr), GetBValue(cr));
            DrawText(hdc, szBuffer.toUTF16z, -1, &rc, DT_SINGLELINE | DT_CENTER | DT_VCENTER);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            DeleteDC(hdcScreen);
            KillTimer(hwnd, ID_TIMER);
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
