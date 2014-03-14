/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +
 + Demonstrates using Cartesian coordinates which has 
 + the Y axis positive values towards the top compared to GDI.
 + 
 + More info found here: 
 + http://www.functionx.com/visualc/gdi/gdicoord.htm
 +/

module Cartesian;

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

string appName     = "Cartesian";
string description = "Cartesian Demo";
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
    
    //~ wndclass.hbrBackground = cast(HBRUSH) GetStockObject(WHITE_BRUSH);
    wndclass.hbrBackground = null;  // don't send WM_ERASEBKND messages
    
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
    static int cxClient, cyClient, cxSource, cySource;
    int x, y;
    HDC hdc;
    PAINTSTRUCT ps;

    static HDC     hdcMem;
    static HBITMAP hbmMem;
    static HANDLE  hOld;
    RECT rect;
    
    switch (message)
    {
        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        // When you set 'hbrBackground = null' it prevents
        // the WM_ERASEBKND message to be sent.
        case WM_ERASEBKGND:
            return 1;
        
        case WM_PAINT:
        {
            // Get DC for window
            hdc = BeginPaint(hwnd, &ps);
            
            // Create an off-screen DC for double-buffering
            hdcMem = CreateCompatibleDC(hdc);
            hbmMem = CreateCompatibleBitmap(hdc, cxClient, cyClient);
            hOld = SelectObject(hdcMem, hbmMem);
        
            // Draw into hdcMem
            GetClientRect(hwnd, &rect);
            
            // Flip Y axis
            SetMapMode(hdcMem, MM_ANISOTROPIC);
            SetViewportOrgEx(hdcMem, 0, rect.bottom, null);
            SetWindowExtEx(hdcMem, rect.bottom, rect.right, null);
            SetViewportExtEx(hdcMem, rect.bottom, -rect.right, null);
            
            // Required for both contexts
            SetMapMode(hdc, MM_ANISOTROPIC);
            SetViewportOrgEx(hdc, 0, rect.bottom, null);
            SetWindowExtEx(hdc, rect.bottom, rect.right, null);
            SetViewportExtEx(hdc, rect.bottom, -rect.right, null);
            
            FillRect(hdcMem, &rect, GetStockObject(BLACK_BRUSH));

            SelectObject(hdcMem, GetStockObject(WHITE_PEN));
            MoveToEx(hdcMem, 50, 50, null);
            LineTo(hdcMem, 150, 100);  // should result in a '/' line pointing toward top-right

            // Transfer the off-screen DC to the screen
            BitBlt(hdc, 0, 0, cxClient, cyClient, hdcMem, 0, 0, SRCCOPY);

            // Free-up the off-screen DC
            SelectObject(hdcMem, hOld);
            DeleteObject(hbmMem);
            DeleteDC (hdcMem);

            EndPaint(hwnd, &ps);
            return 0;
        }
        
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
