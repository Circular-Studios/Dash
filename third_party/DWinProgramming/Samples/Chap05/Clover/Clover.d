/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Clover;

import core.runtime;
import std.string;
import std.utf;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}
import std.math;

pragma(lib, "gdi32.lib");
pragma(lib, "winmm.lib");

import win32.mmsystem;
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
    string appName = "Clover";

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

    hwnd = CreateWindow(appName.toUTF16z,     // window class name
                        "Draw a Clover",      // window caption
                        WS_OVERLAPPEDWINDOW,  // window style
                        CW_USEDEFAULT,        // initial x position
                        CW_USEDEFAULT,        // initial y position
                        CW_USEDEFAULT,        // initial x size
                        CW_USEDEFAULT,        // initial y size
                        NULL,                 // parent window handle
                        NULL,                 // window menu handle
                        hInstance,            // program instance handle
                        NULL);                // creation parameters

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
    static HRGN hRgnClip;
    static int cxClient, cyClient;
    double fAngle, fRadius;
    HCURSOR hCursor;
    HDC  hdc;
    HRGN[6] hRgnTemp;
    PAINTSTRUCT ps;

    switch (message)
    {
        case WM_SIZE:
        {
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);

            hCursor = SetCursor(LoadCursor(NULL, IDC_WAIT));
            ShowCursor(TRUE);

            if (hRgnClip)
                DeleteObject(hRgnClip);

            hRgnTemp[0] = CreateEllipticRgn(0, cyClient / 3, cxClient / 2, 2 * cyClient / 3);
            hRgnTemp[1] = CreateEllipticRgn(cxClient / 2, cyClient / 3, cxClient, 2 * cyClient / 3);
            hRgnTemp[2] = CreateEllipticRgn(cxClient / 3, 0, 2 * cxClient / 3, cyClient / 2);
            hRgnTemp[3] = CreateEllipticRgn(cxClient / 3, cyClient / 2, 2 * cxClient / 3, cyClient);
            hRgnTemp[4] = CreateRectRgn(0, 0, 1, 1);
            hRgnTemp[5] = CreateRectRgn(0, 0, 1, 1);
            hRgnClip    = CreateRectRgn(0, 0, 1, 1);

            CombineRgn(hRgnTemp[4], hRgnTemp[0], hRgnTemp[1], RGN_OR);
            CombineRgn(hRgnTemp[5], hRgnTemp[2], hRgnTemp[3], RGN_OR);
            CombineRgn(hRgnClip,    hRgnTemp[4], hRgnTemp[5], RGN_XOR);

            foreach (i; 0 .. 6)
                DeleteObject(hRgnTemp[i]);

            SetCursor(hCursor);
            ShowCursor(FALSE);
            return 0;
        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);
            scope(exit) EndPaint(hwnd, &ps);

            SetViewportOrgEx(hdc, cxClient / 2, cyClient / 2, NULL);
            SelectClipRgn(hdc, hRgnClip);

            fRadius = hypot(cxClient / 2.0, cyClient / 2.0);

            for (fAngle = 0.0; fAngle < PI*2; fAngle += PI*2 / 360)
            {
                MoveToEx(hdc, 0, 0, NULL);
                LineTo(hdc, cast(int)(fRadius * cos(fAngle) + 0.5), cast(int)(-fRadius * sin(fAngle) + 0.5));
            }

            return 0;
        }

        case WM_DESTROY:
        {
            DeleteObject(hRgnClip);
            PostQuitMessage(0);
            return 0;
        }

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
