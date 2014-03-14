/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module AltWind;

import core.runtime;
import std.string;
import std.utf;

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

extern(Windows)
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
    catch(Throwable o)
    {
        MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    string appName = "AltWind";

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

    hwnd = CreateWindow(appName.toUTF16z,                               // window class name
                        "Alternate and Winding Fill Modes",             // window caption
                        WS_OVERLAPPEDWINDOW,                            // window style
                        CW_USEDEFAULT,                                  // initial x position
                        CW_USEDEFAULT,                                  // initial y position
                        CW_USEDEFAULT,                                  // initial x size
                        CW_USEDEFAULT,                                  // initial y size
                        NULL,                                           // parent window handle
                        NULL,                                           // window menu handle
                        hInstance,                                      // program instance handle
                        NULL);                                          // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
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
    int i, x, y, iVertPos, iHorzPos, iPaintStart, iPaintEnd;
    PAINTSTRUCT ps;
    TEXTMETRIC tm;

    enum aptFigure =
    [
        POINT(10,70), POINT(50,70), POINT(50,10), POINT(90,10), POINT(90,50),
        POINT(30,50), POINT(30,90), POINT(70,90), POINT(70,30), POINT(10,30)
    ];

    POINT[10] apt;

    switch(message)
    {
        case WM_CREATE:
        {
            hdc = GetDC(hwnd);
            scope(exit)
                ReleaseDC(hwnd, hdc);

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

            apt[0].x = cxClient / 4;
            apt[0].y = cyClient / 2;

            apt[1].x = cxClient / 2;
            apt[1].y = cyClient / 4;

            apt[2].x =     cxClient / 2;
            apt[2].y = 3 * cyClient / 4;

            apt[3].x = 3 * cxClient / 4;
            apt[3].y =     cyClient / 2;

            return 0;
        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);
            scope(exit)
            {
                EndPaint(hwnd, &ps);
            }

            SelectObject(hdc, GetStockObject(GRAY_BRUSH));
            foreach (index; 0 .. 10)
            {
                apt[index].x = cxClient * aptFigure[index].x / 200;
                apt[index].y = cyClient * aptFigure[index].y / 100;
            }

            SetPolyFillMode(hdc, ALTERNATE);
            Polygon(hdc, apt.ptr, apt.length);

            foreach (index; 0 .. 10)
            {
                apt[index].x += cxClient / 2;
            }

            SetPolyFillMode(hdc, WINDING);
            Polygon(hdc, apt.ptr, apt.length);
            return 0;
        }

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

void DrawBezier(HDC hdc, POINT[4] apt)
{
    PolyBezier(hdc, apt.ptr, apt.length);

    MoveToEx(hdc, apt[0].x, apt[0].y, NULL);
    LineTo(hdc, apt[1].x, apt[1].y);

    MoveToEx(hdc, apt[2].x, apt[2].y, NULL);
    LineTo(hdc, apt[3].x, apt[3].y);
}
