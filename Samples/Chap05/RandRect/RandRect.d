/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module RandRect;

import core.runtime;
import core.thread;
import std.string;
import std.utf;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}
import std.math;
import std.random;

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
    string appName = "RandRect";

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

    hwnd = CreateWindow(appName.toUTF16z,       // window class name
                        "Random Rectangles",    // window caption
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

    while (true)
    {
        if (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE))
        {
            if (msg.message == WM_QUIT)
                break;

            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
        else
        {
            DrawRectangle(hwnd);
            Thread.sleep(dur!"msecs"(80));  // necessary on modern hardware to slow things down
        }
    }

    return msg.wParam;
}

int cxClient, cyClient;

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

void DrawRectangle(HWND hwnd)
{
    HBRUSH hBrush;
    HDC  hdc;
    RECT rect;

    if (cxClient == 0 || cyClient == 0)
        return;

    SetRect (&rect, uniform(0, cxClient), uniform(0, cyClient),
                    uniform(0, cxClient), uniform(0, cyClient));

    hBrush = CreateSolidBrush(RGB(cast(byte)uniform(0, 256), 
                                  cast(byte)uniform(0, 256), 
                                  cast(byte)uniform(0, 256)));

    hdc = GetDC(hwnd);
    FillRect(hdc, &rect, hBrush);
    ReleaseDC(hwnd, hdc);
    DeleteObject(hBrush);
}
