/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Sketch;

import core.memory;
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

string appName     = "Sketch";
string description = "Sketch";
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
    hinst = hInstance;
    HACCEL hAccel;
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

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

void GetLargestDisplayMode(out int pcxBitmap, out int pcyBitmap)
{
    DEVMODE devmode;
    int iModeNum = 0;

    devmode.dmSize = (DEVMODE.sizeof);

    while (EnumDisplaySettings(NULL, iModeNum++, &devmode))
    {
        pcxBitmap = max(pcxBitmap, cast(int)devmode.dmPelsWidth);
        pcyBitmap = max(pcyBitmap, cast(int)devmode.dmPelsHeight);
    }
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BOOL fLeftButtonDown, fRightButtonDown;
    static HBITMAP hBitmap;
    static HDC hdcMem;
    static int cxBitmap, cyBitmap, cxClient, cyClient, xMouse, yMouse;
    HDC hdc;
    PAINTSTRUCT ps;

    switch (message)
    {
        case WM_CREATE:
            GetLargestDisplayMode(cxBitmap, cyBitmap);

            hdc     = GetDC(hwnd);
            hBitmap = CreateCompatibleBitmap(hdc, cxBitmap, cyBitmap);
            hdcMem  = CreateCompatibleDC(hdc);
            ReleaseDC(hwnd, hdc);

            if (!hBitmap)     // no memory for bitmap
            {
                DeleteDC(hdcMem);
                return -1;
            }

            SelectObject(hdcMem, hBitmap);
            PatBlt(hdcMem, 0, 0, cxBitmap, cyBitmap, WHITENESS);
            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_LBUTTONDOWN:

            if (!fRightButtonDown)
                SetCapture(hwnd);

            xMouse = LOWORD(lParam);
            yMouse = HIWORD(lParam);
            fLeftButtonDown = TRUE;
            return 0;

        case WM_LBUTTONUP:

            if (fLeftButtonDown)
                SetCapture(NULL);

            fLeftButtonDown = FALSE;
            return 0;

        case WM_RBUTTONDOWN:

            if (!fLeftButtonDown)
                SetCapture(hwnd);

            xMouse = LOWORD(lParam);
            yMouse = HIWORD(lParam);
            fRightButtonDown = TRUE;
            return 0;

        case WM_RBUTTONUP:

            if (fRightButtonDown)
                SetCapture(NULL);

            fRightButtonDown = FALSE;
            return 0;

        case WM_MOUSEMOVE:

            if (!fLeftButtonDown && !fRightButtonDown)
                return 0;

            hdc = GetDC(hwnd);

            SelectObject(hdc,
                         GetStockObject(fLeftButtonDown ? BLACK_PEN : WHITE_PEN));

            SelectObject(hdcMem,
                         GetStockObject(fLeftButtonDown ? BLACK_PEN : WHITE_PEN));

            MoveToEx(hdc,    xMouse, yMouse, NULL);
            MoveToEx(hdcMem, xMouse, yMouse, NULL);

            xMouse = cast(short)LOWORD(lParam);
            yMouse = cast(short)HIWORD(lParam);

            LineTo(hdc,    xMouse, yMouse);
            LineTo(hdcMem, xMouse, yMouse);

            ReleaseDC(hwnd, hdc);
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            BitBlt(hdc, 0, 0, cxClient, cyClient, hdcMem, 0, 0, SRCCOPY);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            DeleteDC(hdcMem);
            DeleteObject(hBitmap);
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
