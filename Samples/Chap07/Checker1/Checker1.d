/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Checker1;

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
    string appName = "Checker1";

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

    hwnd = CreateWindow(appName.toUTF16z,               // window class name
                        "Checker1 Mouse Hit-Test Demo", // window caption
                        WS_OVERLAPPEDWINDOW,            // window style
                        CW_USEDEFAULT,                  // initial x position
                        CW_USEDEFAULT,                  // initial y position
                        CW_USEDEFAULT,                  // initial x size
                        CW_USEDEFAULT,                  // initial y size
                        NULL,                           // parent window handle
                        NULL,                           // window menu handle
                        hInstance,                      // program instance handle
                        NULL);                          // creation parameters

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
    enum DIVISIONS = 5;

    static BOOL[DIVISIONS][DIVISIONS] fState;
    static int cxBlock, cyBlock;
    HDC hdc;
    int x, y;  // id of selected block (mouse pixel index / block width)
    PAINTSTRUCT ps;
    RECT rect;

    switch (message)
    {
        case WM_SIZE:
            cxBlock = LOWORD(lParam) / DIVISIONS;
            cyBlock = HIWORD(lParam) / DIVISIONS;
            return 0;

        case WM_LBUTTONDOWN:
            x = LOWORD(lParam) / cxBlock;
            y = HIWORD(lParam) / cyBlock;

            if (x < DIVISIONS && y < DIVISIONS)
            {
                fState[x][y] ^= 1;

                rect.left   = x * cxBlock;
                rect.top    = y * cyBlock;
                rect.right  = (x + 1) * cxBlock;
                rect.bottom = (y + 1) * cyBlock;

                InvalidateRect(hwnd, &rect, FALSE);
            }
            else
                MessageBeep(0);

            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            for (x = 0; x < DIVISIONS; x++)
            {
                for (y = 0; y < DIVISIONS; y++)
                {
                    Rectangle(hdc, x * cxBlock, y * cyBlock,
                              (x + 1) * cxBlock, (y + 1) * cyBlock);

                    if (fState[x][y])
                    {
                        // Draw '\'
                        MoveToEx(hdc,  x * cxBlock,  y * cyBlock, NULL);
                        LineTo(hdc, (x + 1) * cxBlock, (y + 1) * cyBlock);

                        // Draw '/'
                        MoveToEx(hdc,  x * cxBlock, (y + 1) * cyBlock, NULL);
                        LineTo(hdc, (x + 1) * cxBlock,  y * cyBlock);
                    }
                }
            }

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
