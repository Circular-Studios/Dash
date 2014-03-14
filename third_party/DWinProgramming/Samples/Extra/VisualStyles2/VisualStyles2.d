/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +
 +  Similar as Extra\VisualStyles, but adds hit testing.
 +/

module VisualStyles;

import core.memory;
import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.traits;
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

import uxSchema;
import uxTheme;

string appName     = "VisualStyles";
string description = "VisualStyles Demo";
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

enum Control
{
    Button
}

template isOneOf(X, T...)
{
    static if (!T.length)
        enum bool isOneOf = false;
    else static if (is (X == T[0]))
        enum bool isOneOf = true;
    else
        enum bool isOneOf = isOneOf!(Unqual!X, T[1..$]);
}

auto get(T)(LPARAM lParam)
    if (isOneOf!(T, SIZE, POINT))
{
    return T(cast(short)LOWORD(lParam),
             cast(short)HIWORD(lParam));
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int cxClient, cyClient, cxSource, cySource;
    int x, y;
    HDC hdc;
    PAINTSTRUCT ps;
    static POINT hitPoint;
    static bool mouseLDown;
    
    static HDC     hdcMem;
    static HBITMAP hbmMem;
    static HANDLE  hOld;
    RECT rect;
    
    switch (message)
    {
        case WM_LBUTTONDOWN:
        {
            hitPoint = get!POINT(lParam);
            mouseLDown = true;
            InvalidateRect(hwnd, NULL, TRUE);
            return 0;
        }        
        
        case WM_LBUTTONUP:
        {
            hitPoint = get!POINT(lParam);
            mouseLDown = false;
            InvalidateRect(hwnd, NULL, TRUE);
            return 0;
        }
        
        case WM_MOUSEMOVE:
        {
            hitPoint = get!POINT(lParam);
            InvalidateRect(hwnd, NULL, TRUE);
            return 0;
        }
        
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
        
            //~ writeln(buttonState);
            auto buttonRect = RECT(100, 100, 190, 130);
            DrawControl(hwnd, hdcMem, buttonRect, Control.Button, mouseLDown, hitPoint);
         
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

void DrawControl(HWND hwnd, HDC hdcMem, RECT rect, Control control, bool mouseLDown, POINT hitPoint)
{
    HTHEME hTheme = OpenThemeData(hwnd, "Button");
    scope(exit)
    {
        if (hTheme !is null)
            CloseThemeData(hTheme);
    }
    
    final switch (control)
    {
        case Control.Button:
        {
            if (hTheme is null)
            {
                DrawCustomButton(hdcMem, rect, mouseLDown, hitPoint);
            }
            else
            {
                DrawThemedButton(hTheme, hdcMem, rect, mouseLDown, hitPoint);
            }
            break;
        }
    }
}

import std.utf : count;
import std.exception;
import std.stdio;

void DrawCustomButton(HDC hDC, RECT rc, bool mouseLDown, POINT hitPoint)
{
    SIZE size;
    auto text = "My button";
    
    FillRect(hDC,  &rc, cast(HBRUSH)GetStockObject(GRAY_BRUSH));
    FrameRect(hDC, &rc, cast(HBRUSH)GetStockObject(LTGRAY_BRUSH));
    
    // calculate center
    GetTextExtentPoint32(hDC, text.toUTF16z, text.count, &size);
    auto rectWidth = (rc.right - rc.left);
    auto textWidth = (size.cx);
    auto xPos = rc.left + ((rectWidth - textWidth) / 2);
    
    auto rectHeight = (rc.bottom - rc.top);
    auto textHeight = (size.cy);
    auto yPos = rc.top + ((rectHeight - textHeight) / 2);
    
    TextOut(hDC, xPos, yPos, text.toUTF16z, text.count);
}

void DrawThemedButton(HTHEME hTheme, HDC hDC, RECT rc, bool mouseLDown, POINT hitPoint)
{
    RECT rcContent;
    HRESULT hr;
    int state;
    auto text = "My button";   

    WORD hitResult;
    HitTestThemeBackground(hTheme, hDC, BP_PUSHBUTTON, state, 
                           HTTB_BACKGROUNDSEG, &rc, null, hitPoint, &hitResult);        

    if (hitResult == HTNOWHERE)
    {
        state = PBS_NORMAL;
    }
    else
    {
        state = mouseLDown ? PBS_PRESSED : PBS_HOT;
    }
    
    DrawThemeBackground(hTheme, hDC, BP_PUSHBUTTON, state, &rc, null);
    GetThemeBackgroundContentRect(hTheme, hDC, BP_PUSHBUTTON, state, &rc, &rcContent);
    DrawThemeText(hTheme, hDC, BP_PUSHBUTTON, state, 
                  text.toUTF16z, text.count,
                  DT_CENTER | DT_VCENTER | DT_SINGLELINE,
                  0, &rcContent);
}
