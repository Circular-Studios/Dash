/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Blowup;

import core.memory;
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

import resource;

string appName     = "Blowup";
string description = "Blow-Up Mouse Demo";
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
    hinst = hInstance;
    HACCEL hAccel;
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
    wndclass.lpszMenuName  = appName.toUTF16z;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        description.toUTF16z,          // window caption
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
    hAccel = LoadAccelerators(hInstance, appName.toUTF16z);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        if (!TranslateAccelerator(hwnd, hAccel, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return msg.wParam;
}

void InvertBlock(HWND hwndScr, HWND hwnd, POINT ptBeg, POINT ptEnd)
{
    HDC hdc;

    hdc = GetDCEx(hwndScr, NULL, DCX_CACHE | DCX_LOCKWINDOWUPDATE);
    ClientToScreen(hwnd, &ptBeg);
    ClientToScreen(hwnd, &ptEnd);
    PatBlt(hdc, ptBeg.x, ptBeg.y, ptEnd.x - ptBeg.x, ptEnd.y - ptBeg.y, DSTINVERT);
    ReleaseDC(hwndScr, hdc);
}

HBITMAP CopyBitmap(HBITMAP hBitmapSrc)
{
    BITMAP  bitmap;
    HBITMAP hBitmapDst;
    HDC hdcSrc, hdcDst;

    GetObject(hBitmapSrc, BITMAP.sizeof, &bitmap);
    hBitmapDst = CreateBitmapIndirect(&bitmap);

    hdcSrc = CreateCompatibleDC(NULL);
    hdcDst = CreateCompatibleDC(NULL);

    SelectObject(hdcSrc, hBitmapSrc);
    SelectObject(hdcDst, hBitmapDst);

    BitBlt(hdcDst, 0, 0, bitmap.bmWidth, bitmap.bmHeight, hdcSrc, 0, 0, SRCCOPY);

    DeleteDC(hdcSrc);
    DeleteDC(hdcDst);

    return hBitmapDst;
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BOOL bCapturing, bBlocking;
    static HBITMAP hBitmap;
    static HWND  hwndScr;
    static POINT ptBeg, ptEnd;
    BITMAP  bm;
    HBITMAP hBitmapClip;
    HDC hdc, hdcMem;
    int iEnable;
    PAINTSTRUCT ps;
    RECT rect;

    switch (message)
    {
        case WM_LBUTTONDOWN:

            if (!bCapturing)
            {
                if (LockWindowUpdate(hwndScr = GetDesktopWindow()))
                {
                    bCapturing = TRUE;
                    SetCapture(hwnd);
                    SetCursor(LoadCursor(NULL, IDC_CROSS));
                }
                else
                    MessageBeep(0);
            }

            return 0;

        case WM_RBUTTONDOWN:

            if (bCapturing)
            {
                bBlocking = TRUE;
                ptBeg.x   = LOWORD(lParam);
                ptBeg.y   = HIWORD(lParam);
                ptEnd     = ptBeg;
                InvertBlock(hwndScr, hwnd, ptBeg, ptEnd);
            }

            return 0;

        case WM_MOUSEMOVE:

            if (bBlocking)
            {
                InvertBlock(hwndScr, hwnd, ptBeg, ptEnd);
                ptEnd.x = LOWORD(lParam);
                ptEnd.y = HIWORD(lParam);
                InvertBlock(hwndScr, hwnd, ptBeg, ptEnd);
            }

            return 0;

        case WM_LBUTTONUP:
        case WM_RBUTTONUP:

            if (bBlocking)
            {
                InvertBlock(hwndScr, hwnd, ptBeg, ptEnd);
                ptEnd.x = LOWORD(lParam);
                ptEnd.y = HIWORD(lParam);

                if (hBitmap)
                {
                    DeleteObject(hBitmap);
                    hBitmap = NULL;
                }

                hdc     = GetDC(hwnd);
                hdcMem  = CreateCompatibleDC(hdc);
                hBitmap = CreateCompatibleBitmap(hdc,
                                                 abs(ptEnd.x - ptBeg.x),
                                                 abs(ptEnd.y - ptBeg.y));

                SelectObject(hdcMem, hBitmap);

                StretchBlt(hdcMem, 0, 0, abs(ptEnd.x - ptBeg.x),
                           abs(ptEnd.y - ptBeg.y),
                           hdc, ptBeg.x, ptBeg.y, ptEnd.x - ptBeg.x,
                           ptEnd.y - ptBeg.y, SRCCOPY);

                DeleteDC(hdcMem);
                ReleaseDC(hwnd, hdc);
                InvalidateRect(hwnd, NULL, TRUE);
            }

            if (bBlocking || bCapturing)
            {
                bBlocking = bCapturing = FALSE;
                SetCursor(LoadCursor(NULL, IDC_ARROW));
                ReleaseCapture();
                LockWindowUpdate(NULL);
            }

            return 0;

        case WM_INITMENUPOPUP:
            iEnable = IsClipboardFormatAvailable(CF_BITMAP) ?
                      MF_ENABLED : MF_GRAYED;

            EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_PASTE, iEnable);

            iEnable = hBitmap ? MF_ENABLED : MF_GRAYED;

            EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_CUT,    iEnable);
            EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_COPY,   iEnable);
            EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_DELETE, iEnable);
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_EDIT_CUT:
                case IDM_EDIT_COPY:

                    if (hBitmap)
                    {
                        hBitmapClip = CopyBitmap(hBitmap);
                        OpenClipboard(hwnd);
                        EmptyClipboard();
                        SetClipboardData(CF_BITMAP, hBitmapClip);
                    }

                    if (LOWORD(wParam) == IDM_EDIT_COPY)
                        return 0;
                    
                    goto case;

                // fall through for IDM_EDIT_CUT
                case IDM_EDIT_DELETE:

                    if (hBitmap)
                    {
                        DeleteObject(hBitmap);
                        hBitmap = NULL;
                    }

                    InvalidateRect(hwnd, NULL, TRUE);
                    return 0;

                case IDM_EDIT_PASTE:

                    if (hBitmap)
                    {
                        DeleteObject(hBitmap);
                        hBitmap = NULL;
                    }

                    OpenClipboard(hwnd);
                    hBitmapClip = GetClipboardData(CF_BITMAP);

                    if (hBitmapClip)
                        hBitmap = CopyBitmap(hBitmapClip);

                    CloseClipboard();
                    InvalidateRect(hwnd, NULL, TRUE);
                    return 0;

                default:
            }

            break;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            if (hBitmap)
            {
                GetClientRect(hwnd, &rect);

                hdcMem = CreateCompatibleDC(hdc);
                SelectObject(hdcMem, hBitmap);
                GetObject(hBitmap, BITMAP.sizeof, cast(PSTR)&bm);
                SetStretchBltMode(hdc, COLORONCOLOR);

                StretchBlt(hdc,    0, 0, rect.right, rect.bottom,
                           hdcMem, 0, 0, bm.bmWidth, bm.bmHeight, SRCCOPY);

                DeleteDC(hdcMem);
            }

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:

            if (hBitmap)
                DeleteObject(hBitmap);

            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
