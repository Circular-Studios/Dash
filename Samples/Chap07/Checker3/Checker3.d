/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Checker3;

import core.runtime;
import core.thread;
import core.stdc.config;
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

enum DIVISIONS = 5;
string childClass = "Checker3_Child";

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    string appName = "Checker3";

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

    if(!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    wndclass.lpfnWndProc   = &ChildWndProc;
    wndclass.cbWndExtra    = c_long.sizeof;
    wndclass.hIcon         = NULL;
    wndclass.lpszClassName = childClass.toUTF16z;

    if(!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z, "Checker3 Mouse Hit-Test Demo",
                        WS_OVERLAPPEDWINDOW,
                        CW_USEDEFAULT, CW_USEDEFAULT,
                        CW_USEDEFAULT, CW_USEDEFAULT,
                        NULL, NULL, hInstance, NULL);

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while(GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HWND[DIVISIONS][DIVISIONS] hwndChild;    // 25 windows
    int cxBlock, cyBlock, x, y;

    switch (message)
    {
        case WM_CREATE:
        {
            for (x = 0; x < DIVISIONS; x++)
                for (y = 0; y < DIVISIONS; y++)
                    hwndChild[x][y] = CreateWindow(childClass.toUTF16z, NULL,
                                                   WS_CHILDWINDOW | WS_VISIBLE,
                                                   0, 0, 0, 0,
                                                   hwnd,
                                                   cast(HMENU)(y << 8 | x), // ID
                                                   cast(HINSTANCE)GetWindowLongPtr(hwnd, GWL_HINSTANCE),
                                                   NULL);

            return 0;
        }

        case WM_SIZE:
        {
            cxBlock = LOWORD(lParam) / DIVISIONS;
            cyBlock = HIWORD(lParam) / DIVISIONS;

            for (x = 0; x < DIVISIONS; x++)
                for (y = 0; y < DIVISIONS; y++)
                    MoveWindow(hwndChild[x][y],
                               x * cxBlock, y * cyBlock, // upper left corner relative to this client area
                               cxBlock, cyBlock, // width, height
                               TRUE);


            // needs repainting

            return 0;
        }

        case WM_LBUTTONDOWN:
            MessageBeep(0);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern (Windows)
LRESULT ChildWndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    HDC hdc;
    PAINTSTRUCT ps;
    RECT rect;

    switch (message)
    {
        case WM_CREATE:
            SetWindowLongPtr(hwnd, 0, 0);      // on/off flag in the extra space when we registered wnd class
            return 0;

        case WM_LBUTTONDOWN:
            SetWindowLongPtr(hwnd, 0, 1 ^ GetWindowLongPtr(hwnd, 0));     // toggle int
            InvalidateRect(hwnd, NULL, FALSE);      // invalidate entire child window client area
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            GetClientRect(hwnd, &rect);
            Rectangle(hdc, 0, 0, rect.right, rect.bottom);      // painting is now simplified

            // paint diagonal lines
            if (GetWindowLongPtr(hwnd, 0))
            {
                MoveToEx(hdc, 0, 0, NULL);
                LineTo(hdc, rect.right, rect.bottom);
                MoveToEx(hdc, 0, rect.bottom, NULL);
                LineTo(hdc, rect.right, 0);
            }

            EndPaint(hwnd, &ps);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
