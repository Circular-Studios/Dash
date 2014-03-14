/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module BlokOut2;

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
    string appName = "BlokOut2";

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
                        "Mouse Button Demo",           // window caption
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

void DrawBoxOutline(HWND hwnd, POINT ptBeg, POINT ptEnd)
{
    HDC hdc;
    hdc = GetDC(hwnd);
    SetROP2(hdc, R2_NOT);
    SelectObject(hdc, GetStockObject(NULL_BRUSH));

    Rectangle(hdc, ptBeg.x, ptBeg.y, ptEnd.x, ptEnd.y);
    ReleaseDC(hwnd, hdc);
}

extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BOOL  fBlocking, fValidBox;
    static POINT ptBeg, ptEnd, ptBoxBeg, ptBoxEnd;
    HDC hdc;
    PAINTSTRUCT ps;

    switch (message)
    {
        case WM_LBUTTONDOWN:
        {
            ptBeg.x = ptEnd.x = cast(short)LOWORD(lParam);
            ptBeg.y = ptEnd.y = cast(short)HIWORD(lParam);

            DrawBoxOutline(hwnd, ptBeg, ptEnd);

            SetCapture(hwnd);
            SetCursor(LoadCursor(NULL, IDC_CROSS));

            fBlocking = TRUE;
            return 0;
        }

        case WM_MOUSEMOVE:
        {
            if (fBlocking)
            {
                SetCursor(LoadCursor(NULL, IDC_CROSS));

                DrawBoxOutline(hwnd, ptBeg, ptEnd);

                ptEnd.x = cast(short)LOWORD(lParam);   // lParam will be negative pair of X and Y short,
                ptEnd.y = cast(short)HIWORD(lParam);   // however LOWORD and HIWORD return ushort. Cast is needed to
                                                       // preserve sign bit.
                DrawBoxOutline(hwnd, ptBeg, ptEnd);
            }

            return 0;
        }

        case WM_LBUTTONUP:
        {
            if (fBlocking)
            {
                DrawBoxOutline(hwnd, ptBeg, ptEnd);

                ptBoxBeg   = ptBeg;
                ptBoxEnd.x = cast(short)LOWORD(lParam);
                ptBoxEnd.y = cast(short)HIWORD(lParam);

                ReleaseCapture();
                SetCursor(LoadCursor(NULL, IDC_ARROW));

                fBlocking = FALSE;
                fValidBox = TRUE;

                InvalidateRect(hwnd, NULL, TRUE);
            }

            return 0;
        }

        case WM_CHAR:
        {
            if (fBlocking && (wParam == '\x1B'))     // i.e., Escape
            {
                DrawBoxOutline(hwnd, ptBeg, ptEnd);
                ReleaseCapture();
                SetCursor(LoadCursor(NULL, IDC_ARROW));

                fBlocking = FALSE;
            }

            return 0;
        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);

            if (fValidBox)
            {
                SelectObject(hdc, GetStockObject(BLACK_BRUSH));
                Rectangle(hdc, ptBoxBeg.x, ptBoxBeg.y,
                               ptBoxEnd.x, ptBoxEnd.y);
            }

            if (fBlocking)
            {
                SetROP2(hdc, R2_NOT);
                SelectObject(hdc, GetStockObject(NULL_BRUSH));
                Rectangle(hdc, ptBeg.x, ptBeg.y, ptEnd.x, ptEnd.y);
            }

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
