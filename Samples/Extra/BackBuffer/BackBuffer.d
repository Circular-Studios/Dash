/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +
 + Demonstrates a simple double-buffer drawing mechanism.
 + Basically you do all the drawing in a backbuffer and
 + then blit that to the screen when you're done.
 + 
 + Some good info about avoiding flicker can be found here:
 + http://www.catch22.net/tuts/flicker
 + 
 + Also see various codeproject.com C/C++ helper libraries
 + and articles that have anti-flicker code.
 + 
 + Note that scrollbars and titlebars still flicker,
 + but this could also be fixed. Search online to figure
 + this stuff out.
 +/

module BackBuffer;

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

string appName     = "BackBuffer";
string description = "BackBuffer Demo";
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
            FillRect(hdcMem, &rect, GetStockObject(BLACK_BRUSH));
            
            rect.left += 10;
            rect.top  += 10;
            rect.right -= 10;
            rect.bottom -= 10;
            FillRect(hdcMem, &rect, GetStockObject(WHITE_BRUSH));

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
