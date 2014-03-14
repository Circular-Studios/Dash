/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module HelloBlit;

import core.memory;
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

string appName     = "HelloBit";
string description = "HelloBit";
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

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HBITMAP hBitmap;
    static HDC hdcMem;
    static int cxBitmap, cyBitmap, cxClient, cyClient, iSize = IDM_BIG;
    string szText = " Hello, world! ";
    HDC hdc;
    HMENU hMenu;
    int x, y;
    PAINTSTRUCT ps;
    SIZE size;

    switch (message)
    {
        case WM_CREATE:
            hdc    = GetDC(hwnd);
            hdcMem = CreateCompatibleDC(hdc);

            GetTextExtentPoint32(hdc, szText.toUTF16z, szText.count, &size);
            cxBitmap = size.cx;
            cyBitmap = size.cy;
            hBitmap  = CreateCompatibleBitmap(hdc, cxBitmap, cyBitmap);

            ReleaseDC(hwnd, hdc);

            SelectObject(hdcMem, hBitmap);
            TextOut(hdcMem, 0, 0, szText.toUTF16z, szText.count);
            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_COMMAND:
            hMenu = GetMenu(hwnd);

            switch (LOWORD(wParam))
            {
                case IDM_BIG:
                case IDM_SMALL:
                    CheckMenuItem(hMenu, iSize, MF_UNCHECKED);
                    iSize = LOWORD(wParam);
                    CheckMenuItem(hMenu, iSize, MF_CHECKED);
                    InvalidateRect(hwnd, NULL, TRUE);
                    break;
                
                default:
            }

            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            switch (iSize)
            {
                case IDM_BIG:
                    StretchBlt(hdc, 0, 0, cxClient, cyClient,
                               hdcMem, 0, 0, cxBitmap, cyBitmap, SRCCOPY);
                    break;

                case IDM_SMALL:
                    for (y = 0; y < cyClient; y += cyBitmap)
                    {
                        for (x = 0; x < cxClient; x += cxBitmap)
                        {
                            BitBlt(hdc, x, y, cxBitmap, cyBitmap, hdcMem, 0, 0, SRCCOPY);
                        }
                    }

                    break;
                        
                default:
            }

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
