/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module WhatSize;

import core.runtime;
import core.thread;
import std.string;
import std.utf : count, toUTFz;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}
import std.math;

pragma(lib, "gdi32.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;

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
    string appName = "WhatSize";

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
    wndclass.hbrBackground = cast(HBRUSH) GetStockObject(WHITE_BRUSH);

    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,            // window class name
                        "What Size is the Window?",  // window caption
                        WS_OVERLAPPEDWINDOW,         // window style
                        CW_USEDEFAULT,               // initial x position
                        CW_USEDEFAULT,               // initial y position
                        CW_USEDEFAULT,               // initial x size
                        CW_USEDEFAULT,               // initial y size
                        NULL,                        // parent window handle
                        NULL,                        // window menu handle
                        hInstance,                   // program instance handle
                        NULL);                       // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

void Show(HWND hwnd, HDC hdc, int xText, int yText, int iMapMode, string mapMode)
{
    RECT rect;
    SaveDC(hdc);

    SetMapMode(hdc, iMapMode);
    GetClientRect(hwnd, &rect);
    DPtoLP(hdc, cast(PPOINT)&rect, 2);

    RestoreDC(hdc, -1);

    auto value = format("%-20s %7s %7s %7s %7s", mapMode, rect.left, rect.right, rect.top, rect.bottom);
    TextOut(hdc, xText, yText, value.toUTF16z, value.count);
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    enum heading   = "Mapping Mode            Left   Right     Top  Bottom";
    enum underline = "------------            ----   -----     ---  ------";
    static int cxChar, cyChar;
    HDC hdc;
    PAINTSTRUCT ps;
    TEXTMETRIC  tm;

    switch (message)
    {
        case WM_CREATE:
        {
            hdc = GetDC(hwnd);
            SelectObject(hdc, GetStockObject(SYSTEM_FIXED_FONT));

            GetTextMetrics(hdc, &tm);
            cxChar = tm.tmAveCharWidth;
            cyChar = tm.tmHeight + tm.tmExternalLeading;

            ReleaseDC(hwnd, hdc);
            return 0;
        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);
            SelectObject(hdc, GetStockObject(SYSTEM_FIXED_FONT));

            SetMapMode(hdc, MM_ANISOTROPIC);
            SetWindowExtEx(hdc, 1, 1, NULL);
            SetViewportExtEx(hdc, cxChar, cyChar, NULL);

            TextOut(hdc, 1, 1, heading.toUTF16z, heading.count);
            TextOut(hdc, 1, 2, underline.toUTF16z, underline.count);

            Show(hwnd, hdc, 1, 3, MM_TEXT,      "pixels)");
            Show(hwnd, hdc, 1, 4, MM_LOMETRIC,  "LOMETRIC(.1 mm)");
            Show(hwnd, hdc, 1, 5, MM_HIMETRIC,  "HIMETRIC(.01 mm)");
            Show(hwnd, hdc, 1, 6, MM_LOENGLISH, "LOENGLISH(.01 in)");
            Show(hwnd, hdc, 1, 7, MM_HIENGLISH, "HIENGLISH(.001 in)");
            Show(hwnd, hdc, 1, 8, MM_TWIPS,     "TWIPS(1/1440 in)");

            EndPaint(hwnd, &ps);
            return 0;
        }

        case WM_DESTROY:
        {
            PostQuitMessage(0);
            return 0;
        }

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
