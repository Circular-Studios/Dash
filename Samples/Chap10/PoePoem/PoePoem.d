/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module PoePoem;

/+
 + The code sample assumes the text resource is ASCII.
 + A safer option is to use the import() expression
 + or a module ctor for loading text resources.
 +/

import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.stdio;
import std.utf : count, toUTFz;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;

import resource;

enum ID_TIMER = 1;
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
    TCHAR[16] szAppName;
    TCHAR[64] szCaption;
    TCHAR[64] szErrMsg;

    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    LoadString(hInstance, IDS_APPNAME, szAppName.ptr, szAppName.count);
    LoadString(hInstance, IDS_CAPTION, szCaption.ptr, szCaption.count);

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(hInstance, szAppName.ptr);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH) GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = szAppName.ptr;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", szAppName.ptr, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(szAppName.ptr,              // window class name
                        szCaption.ptr,              // window caption
                        WS_OVERLAPPEDWINDOW,        // window style
                        CW_USEDEFAULT,              // initial x position
                        CW_USEDEFAULT,              // initial y position
                        CW_USEDEFAULT,              // initial x size
                        CW_USEDEFAULT,              // initial y size
                        NULL,                       // parent window handle
                        NULL,                       // window menu handle
                        hInstance,                  // program instance handle
                        NULL);                      // creation parameters

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
    static string  pText;
    static HGLOBAL hResource;
    static HWND hScroll;
    static int  iPosition, cxChar, cyChar, cyClient, iNumLines, xScroll;
    HDC hdc;
    PAINTSTRUCT ps;
    RECT rect;
    TEXTMETRIC tm;

    switch (message)
    {
        case WM_CREATE:
            hdc = GetDC(hwnd);
            GetTextMetrics(hdc, &tm);
            cxChar = tm.tmAveCharWidth;
            cyChar = tm.tmHeight + tm.tmExternalLeading;
            ReleaseDC(hwnd, hdc);

            xScroll = GetSystemMetrics(SM_CXVSCROLL);
            hScroll = CreateWindow("scrollbar", NULL,
                                   WS_CHILD | WS_VISIBLE | SBS_VERT,
                                   0, 0, 0, 0,
                                   hwnd, cast(HMENU)1, hinst, NULL);

            hResource = LoadResource(hinst, FindResource(hinst, "AnnabelLee", "TEXT"));
            pText     = to!string(cast(char*)LockResource(hResource));
            iNumLines = std.algorithm.count(pText, '\n');

            SetScrollRange(hScroll, SB_CTL, 0, iNumLines, FALSE);
            SetScrollPos(hScroll, SB_CTL, 0, FALSE);
            return 0;

        case WM_SIZE:
            MoveWindow(hScroll, LOWORD(lParam) - xScroll, 0,
                       xScroll, cyClient = HIWORD(lParam), TRUE);
            SetFocus(hwnd);
            return 0;

        case WM_SETFOCUS:
            SetFocus(hScroll);
            return 0;

        case WM_VSCROLL:

            switch (wParam)
            {
                case SB_TOP:
                    iPosition = 0;
                    break;

                case SB_BOTTOM:
                    iPosition = iNumLines;
                    break;

                case SB_LINEUP:
                    iPosition -= 1;
                    break;

                case SB_LINEDOWN:
                    iPosition += 1;
                    break;

                case SB_PAGEUP:
                    iPosition -= cyClient / cyChar;
                    break;

                case SB_PAGEDOWN:
                    iPosition += cyClient / cyChar;
                    break;

                case SB_THUMBPOSITION:
                    iPosition = LOWORD(lParam);
                    break;

                default:
            }

            iPosition = max(0, min(iPosition, iNumLines));

            if (iPosition != GetScrollPos(hScroll, SB_CTL))
            {
                SetScrollPos(hScroll, SB_CTL, iPosition, TRUE);
                InvalidateRect(hwnd, NULL, TRUE);
            }

            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);
            scope(exit) EndPaint(hwnd, &ps);
            pText = to!string(cast(char*)LockResource(hResource));

            GetClientRect(hwnd, &rect);
            rect.left += cxChar;
            rect.top  += cyChar * (1 - iPosition);
            DrawText(hdc, pText.toUTF16z, -1, &rect, DT_EXTERNALLEADING);

            return 0;

        case WM_DESTROY:
            FreeResource(hResource);
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
