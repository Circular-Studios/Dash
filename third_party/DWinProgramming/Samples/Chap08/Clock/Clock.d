/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Clock;

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

enum ID_TIMER = 1;

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
    string appName = "Clock";

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

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        "Analog Clock",                // window caption
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

void SetIsotropic(HDC hdc, int cxClient, int cyClient)
{
    SetMapMode(hdc, MM_ISOTROPIC);
    SetWindowExtEx(hdc, 1000, 1000, NULL);
    SetViewportExtEx(hdc, cxClient / 2, -cyClient / 2, NULL);
    SetViewportOrgEx(hdc, cxClient / 2,  cyClient / 2, NULL);
}

void RotatePoint(POINT[] pt, int iNum, int iAngle)
{
    int i;
    POINT ptTemp;

    for (i = 0; i < iNum; i++)
    {
        ptTemp.x = cast(int)(pt[i].x * cos(PI * 2 * iAngle / 360) +
                             pt[i].y * sin(PI * 2 * iAngle / 360));

        ptTemp.y = cast(int)(pt[i].y * cos(PI * 2 * iAngle / 360) -
                             pt[i].x * sin(PI * 2 * iAngle / 360));

        pt[i] = ptTemp;
    }
}

void DrawClock(HDC hdc)
{
    int iAngle;
    POINT pt[3];

    for (iAngle = 0; iAngle < 360; iAngle += 6)
    {
        pt[0].x =   0;
        pt[0].y = 900;

        RotatePoint(pt, 1, iAngle);

        pt[2].x = pt[2].y = iAngle % 5 ? 33 : 100;

        pt[0].x -= pt[2].x / 2;
        pt[0].y -= pt[2].y / 2;

        pt[1].x = pt[0].x + pt[2].x;
        pt[1].y = pt[0].y + pt[2].y;

        SelectObject(hdc, GetStockObject(BLACK_BRUSH));

        Ellipse(hdc, pt[0].x, pt[0].y, pt[1].x, pt[1].y);
    }
}

void DrawHands(HDC hdc, SYSTEMTIME* pst, BOOL fChange)
{
    static POINT[5][3] pt =
    [
        [POINT(0, -150), POINT(100, 0), POINT(0, 600), POINT(-100, 0), POINT(0, -150)],
        [POINT(0, -200), POINT( 50, 0), POINT(0, 800), POINT( -50, 0), POINT(0, -200)],
        [POINT(0,    0), POINT(  0, 0), POINT(0,   0), POINT(   0, 0), POINT(0,  800)]
    ];
    int i;
    int[3] iAngle;
    POINT[5][3] ptTemp;

    iAngle[0] = (pst.wHour * 30) % 360 + pst.wMinute / 2;
    iAngle[1] =  pst.wMinute * 6;
    iAngle[2] =  pst.wSecond * 6;

    ptTemp[] = pt[];

    for (i = fChange ? 0 : 2; i < 3; i++)
    {
        RotatePoint(ptTemp[i], 5, iAngle[i]);
        Polyline(hdc, ptTemp[i].ptr, 5);
    }
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int cxClient, cyClient;
    static SYSTEMTIME stPrevious;
    BOOL fChange;
    HDC  hdc;
    PAINTSTRUCT ps;
    SYSTEMTIME  st;

    switch (message)
    {
        case WM_CREATE:
            SetTimer(hwnd, ID_TIMER, 1000, NULL);
            GetLocalTime(&st);
            stPrevious = st;
            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_TIMER:
            GetLocalTime(&st);

            fChange = st.wHour != stPrevious.wHour ||
                      st.wMinute != stPrevious.wMinute;

            hdc = GetDC(hwnd);

            SetIsotropic(hdc, cxClient, cyClient);

            SelectObject(hdc, GetStockObject(WHITE_PEN));
            DrawHands(hdc, &stPrevious, fChange);

            SelectObject(hdc, GetStockObject(BLACK_PEN));
            DrawHands(hdc, &st, TRUE);

            ReleaseDC(hwnd, hdc);

            stPrevious = st;
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            SetIsotropic(hdc, cxClient, cyClient);

            DrawClock(hdc);
            DrawHands(hdc, &stPrevious, TRUE);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            KillTimer(hwnd, ID_TIMER);
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
