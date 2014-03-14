/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module BitMask;

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

import resource;

string appName     = "BitMask";
string description = "Bitmap Masking Demo";
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

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HBITMAP hBitmapImag, hBitmapMask;
    static HINSTANCE hInstance;
    static int cxClient, cyClient, cxBitmap, cyBitmap;
    BITMAP bitmap;
    HDC hdc, hdcMemImag, hdcMemMask;
    int x, y;
    PAINTSTRUCT ps;

    switch (message)
    {
        case WM_CREATE:
            hInstance = (cast(LPCREATESTRUCT)lParam).hInstance;

            // Load the original image and get its size
            hBitmapImag = LoadBitmap(hInstance, "Block");
            GetObject(hBitmapImag, BITMAP.sizeof, &bitmap);
            cxBitmap = bitmap.bmWidth;
            cyBitmap = bitmap.bmHeight;

            // Select the original image into a memory DC
            hdcMemImag = CreateCompatibleDC(NULL);
            SelectObject(hdcMemImag, hBitmapImag);

            // Create the monochrome mask bitmap and memory DC
            hBitmapMask = CreateBitmap(cxBitmap, cyBitmap, 1, 1, NULL);
            hdcMemMask  = CreateCompatibleDC(NULL);
            SelectObject(hdcMemMask, hBitmapMask);

            // Color the mask bitmap black with a white ellipse
            SelectObject(hdcMemMask, GetStockObject(BLACK_BRUSH));
            Rectangle(hdcMemMask, 0, 0, cxBitmap, cyBitmap);
            SelectObject(hdcMemMask, GetStockObject(WHITE_BRUSH));
            Ellipse(hdcMemMask, 0, 0, cxBitmap, cyBitmap);

            // Mask the original image
            BitBlt(hdcMemImag, 0, 0, cxBitmap, cyBitmap,
                   hdcMemMask, 0, 0, SRCAND);

            DeleteDC(hdcMemImag);
            DeleteDC(hdcMemMask);
            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            // Select bitmaps into memory DCs
            hdcMemImag = CreateCompatibleDC(hdc);
            SelectObject(hdcMemImag, hBitmapImag);

            hdcMemMask = CreateCompatibleDC(hdc);
            SelectObject(hdcMemMask, hBitmapMask);

            // Center image
            x = (cxClient - cxBitmap) / 2;
            y = (cyClient - cyBitmap) / 2;

            // Do the bitblits
            BitBlt(hdc, x, y, cxBitmap, cyBitmap, hdcMemMask, 0, 0, 0x220326);
            BitBlt(hdc, x, y, cxBitmap, cyBitmap, hdcMemImag, 0, 0, SRCPAINT);

            DeleteDC(hdcMemImag);
            DeleteDC(hdcMemMask);
            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            DeleteObject(hBitmapImag);
            DeleteObject(hBitmapMask);
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
