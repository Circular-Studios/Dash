/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module DigiClock;

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
import win32.winnls;

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
    string appName = "DigClock";

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
                        "Digital Clock",               // window caption
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



void DisplayDigit(HDC hdc, int iNumber)
{
    static int[7][10] fSevenSegment =
    [
        [1, 1, 1, 0, 1, 1, 1,],
        [0, 0, 1, 0, 0, 1, 0,],
        [1, 0, 1, 1, 1, 0, 1,],
        [1, 0, 1, 1, 0, 1, 1,],
        [0, 1, 1, 1, 0, 1, 0,],
        [1, 1, 0, 1, 0, 1, 1,],
        [1, 1, 0, 1, 1, 1, 1,],
        [1, 0, 1, 0, 0, 1, 0,],
        [1, 1, 1, 1, 1, 1, 1,],
        [1, 1, 1, 1, 0, 1, 1 ]
    ];

    static POINT[6][7] ptSegment  =
    [
        [POINT(7,  6),   POINT(11, 2),    POINT(31,  2),  POINT(35, 6),   POINT(31, 10),  POINT(11, 10)],
        [POINT(6,  7),   POINT(10, 11),   POINT(10,  31), POINT(6, 35),   POINT(2, 31),   POINT(2, 11)],
        [POINT(36, 7),   POINT(40, 11),   POINT(40,  31), POINT(36, 35),  POINT(32, 31),  POINT(32, 11)],
        [POINT(7, 36),   POINT(11, 32),   POINT(31, 32),  POINT(35, 36),  POINT(31, 40),  POINT(11, 40)],
        [POINT(6, 37),   POINT(10, 41),   POINT(10, 61),  POINT(6, 65),   POINT(2, 61),   POINT(2, 41)],
        [POINT(36, 37),  POINT(40, 41),   POINT(40, 61),  POINT(36, 65),  POINT(32, 61),  POINT(32, 41)],
        [POINT(7, 66),   POINT(11, 62),   POINT(31, 62),  POINT(35, 66),  POINT(31, 70),  POINT(11, 70)],
    ];
    int iSeg;

    for(iSeg = 0; iSeg < 7; iSeg++)
        if(fSevenSegment [iNumber][iSeg])
            Polygon(hdc, ptSegment[iSeg].ptr, 6);

}


void DisplayTwoDigits(HDC hdc, int iNumber, BOOL fSuppress)
{
    if(!fSuppress ||(iNumber / 10 != 0))
        DisplayDigit(hdc, iNumber / 10);

    OffsetWindowOrgEx(hdc, -42, 0, NULL);
    DisplayDigit(hdc, iNumber % 10);
    OffsetWindowOrgEx(hdc, -42, 0, NULL);
}


void DisplayColon(HDC hdc)
{
    POINT[4][2] ptColon  =
    [
        [
            POINT(2,  21),
            POINT(6,  17),
            POINT(10, 21),
            POINT(6,  25),

        ],
        [
            POINT(2,  51),
            POINT(6,  47),
            POINT(10, 51),
            POINT(6,  55)
        ]
    ];

    Polygon(hdc, ptColon[0].ptr, 4);
    Polygon(hdc, ptColon[1].ptr, 4);

    OffsetWindowOrgEx(hdc, -12, 0, NULL);
}


void DisplayTime(HDC hdc, BOOL f24Hour, BOOL fSuppress)
{
    SYSTEMTIME st;

    GetLocalTime(&st);

    if(f24Hour)
        DisplayTwoDigits(hdc, st.wHour, fSuppress);
    else
        DisplayTwoDigits(hdc,(st.wHour %= 12) ? st.wHour : 12, fSuppress);

    DisplayColon(hdc);
    DisplayTwoDigits(hdc, st.wMinute, FALSE);
    DisplayColon(hdc);
    DisplayTwoDigits(hdc, st.wSecond, FALSE);
}


extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BOOL f24Hour, fSuppress;
    static HBRUSH hBrushRed;
    static int cxClient, cyClient;
    HDC hdc;
    PAINTSTRUCT ps;
    wchar[2] szBuffer;

    switch (message)
    {
        case WM_CREATE:
            hBrushRed = CreateSolidBrush(RGB(255, 0, 0));
            SetTimer(hwnd, ID_TIMER, 1000, NULL);
            goto case;

        // fall through
        case WM_SETTINGCHANGE:
            GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_ITIME, szBuffer.ptr, 2);
            f24Hour = (szBuffer[0] == '1');

            GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_ITLZERO, szBuffer.ptr, 2);
            fSuppress = (szBuffer[0] == '0');

            InvalidateRect(hwnd, NULL, TRUE);
              return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_TIMER:
            InvalidateRect(hwnd, NULL, TRUE);
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            SetMapMode(hdc, MM_ISOTROPIC);
            SetWindowExtEx(hdc, 276, 72, NULL);
            SetViewportExtEx(hdc, cxClient, cyClient, NULL);

            SetWindowOrgEx(hdc, 138, 36, NULL);
            SetViewportOrgEx(hdc, cxClient / 2, cyClient / 2, NULL);
            SelectObject(hdc, GetStockObject(NULL_PEN));
            SelectObject(hdc, hBrushRed);

            DisplayTime(hdc, f24Hour, fSuppress);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            KillTimer(hwnd, ID_TIMER);
            DeleteObject(hBrushRed);
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

