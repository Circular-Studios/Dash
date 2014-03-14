/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module DevCaps1;

import core.runtime;
import std.algorithm : min, max;
import std.conv;
import std.math;
import std.string;
import std.utf : count, toUTFz;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");
pragma(lib, "winmm.lib");
import win32.mmsystem;
import win32.windef;
import win32.winuser;
import win32.wingdi;

struct DeviceCaps
{
    int    index;
    string label;
    string desc;
}

enum devCaps =
[
    DeviceCaps(HORZSIZE,     "HORZSIZE",     "Width in millimeters:"),
    DeviceCaps(VERTSIZE,     "VERTSIZE",     "Height in millimeters:"),
    DeviceCaps(HORZRES,      "HORZRES",      "Width in pixels:"),
    DeviceCaps(VERTRES,      "VERTRES",      "Height in raster lines:"),
    DeviceCaps(BITSPIXEL,    "BITSPIXEL",    "Color bits per pixel:"),
    DeviceCaps(PLANES,       "PLANES",       "Number of color planes:"),
    DeviceCaps(NUMBRUSHES,   "NUMBRUSHES",   "Number of device brushes:"),
    DeviceCaps(NUMPENS,      "NUMPENS",      "Number of device pens:"),
    DeviceCaps(NUMMARKERS,   "NUMMARKERS",   "Number of device markers:"),
    DeviceCaps(NUMFONTS,     "NUMFONTS",     "Number of device fonts:"),
    DeviceCaps(NUMCOLORS,    "NUMCOLORS",    "Number of device colors:"),
    DeviceCaps(PDEVICESIZE,  "PDEVICESIZE",  "Size of device structure:"),
    DeviceCaps(ASPECTX,      "ASPECTX",      "Relative width of pixel:"),
    DeviceCaps(ASPECTY,      "ASPECTY",      "Relative height of pixel:"),
    DeviceCaps(ASPECTXY,     "ASPECTXY",     "Relative diagonal of pixel:"),
    DeviceCaps(LOGPIXELSX,   "LOGPIXELSX",   "Horizontal dots per inch:"),
    DeviceCaps(LOGPIXELSY,   "LOGPIXELSY",   "Vertical dots per inch:"),
    DeviceCaps(SIZEPALETTE,  "SIZEPALETTE",  "Number of palette entries:"),
    DeviceCaps(NUMRESERVED,  "NUMRESERVED",  "Reserved palette entries:"),
    DeviceCaps(COLORRES,     "COLORRES",     "Actual color resolution:")
];

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
    string appName = "DevCaps1";

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

    if(!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,       // window class name
                        "Device Capabilities",  // window caption
                        WS_OVERLAPPEDWINDOW,    // window style
                        CW_USEDEFAULT,          // initial x position
                        CW_USEDEFAULT,          // initial y position
                        CW_USEDEFAULT,          // initial x size
                        CW_USEDEFAULT,          // initial y size
                        NULL,                   // parent window handle
                        NULL,                   // window menu handle
                        hInstance,              // program instance handle
                        NULL);                  // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while(GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int cxChar, cxCaps, cyChar, cxClient, cyClient, iMaxWidth;
    HDC hdc;
    int x, y, iVertPos, iHorzPos, iPaintStart, iPaintEnd;
    PAINTSTRUCT ps;
    SCROLLINFO  si;
    TEXTMETRIC tm;

    switch(message)
    {
        case WM_CREATE:
        {
            hdc = GetDC(hwnd);
            scope(exit) ReleaseDC(hwnd, hdc);

            GetTextMetrics(hdc, &tm);
            cxChar = tm.tmAveCharWidth;
            cxCaps = (tm.tmPitchAndFamily & 1 ? 3 : 2) * cxChar / 2;
            cyChar = tm.tmHeight + tm.tmExternalLeading;

            // Save the width of the three columns
            iMaxWidth = 40 * cxChar + 22 * cxCaps;

            return 0;
        }

        case WM_SIZE:
        {
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;
        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);
            scope(exit) EndPaint(hwnd, &ps);

            foreach (index, caps; devCaps)
            {
                TextOut(hdc, 0, cyChar * index, caps.label.toUTF16z, caps.label.count);
                TextOut(hdc, 14 * cxCaps, cyChar * index, caps.desc.toUTF16z, caps.desc.count);
                SetTextAlign(hdc, TA_RIGHT | TA_TOP);

                auto value = format("%5s", GetDeviceCaps(hdc, caps.index));
                TextOut(hdc, 14 * cxCaps + 35 * cxChar, cyChar * index, value.toUTF16z, value.count);
                SetTextAlign(hdc, TA_LEFT | TA_TOP);
            }

            return 0;
        }

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
