/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module SineWave;

import core.runtime;
import core.thread;
import std.string;
import std.utf;

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
    string appName = "SineWave";

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
                        "Sine Wave Using Polyline",  // window caption
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

enum NUM   = 1000;

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int cxClient, cyClient;
    HDC hdc;
    PAINTSTRUCT ps;
    POINT[NUM] apt;

    switch (message)
    {
        case WM_SIZE:
        {
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;
        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);

            MoveToEx(hdc, 0, cyClient / 2, NULL);
            LineTo(hdc, cxClient, cyClient / 2);

            foreach (index; 0 .. NUM)
            {
                apt[index].x = index * cxClient / NUM;
                apt[index].y = cast(int)(cyClient / 2 * (1 - sin(2*PI * index / NUM)));
            }

            Polyline(hdc, apt.ptr, NUM);
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
