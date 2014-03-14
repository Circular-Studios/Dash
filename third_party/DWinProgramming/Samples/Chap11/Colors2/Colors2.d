/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Colors2;

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

string appName     = "Colors2";
string description = "Color Scroll";
enum ID_TIMER = 1;
HINSTANCE hinst;

HWND hDlgModeless;

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

    hDlgModeless = CreateDialog(hInstance, "ColorScrDlg", hwnd, &ColorScrDlg);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        if (hDlgModeless == null || !IsDialogMessage(hDlgModeless, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return msg.wParam;
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_DESTROY:
            DeleteObject(cast(HGDIOBJ)SetClassLong(hwnd, GCL_HBRBACKGROUND,
                                                   cast(LONG)GetStockObject(WHITE_BRUSH)));
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern (Windows)
BOOL ColorScrDlg(HWND hDlg, UINT message,
                 WPARAM wParam, LPARAM lParam)
{
    static ubyte[3] iColor;
    HWND hwndParent, hCtrl;
    int  iCtrlID, iIndex;

    switch (message)
    {
        case WM_INITDIALOG:

            for (iCtrlID = 10; iCtrlID < 13; iCtrlID++)
            {
                hCtrl = GetDlgItem(hDlg, iCtrlID);
                SetScrollRange(hCtrl, SB_CTL, 0, 255, FALSE);
                SetScrollPos(hCtrl, SB_CTL, 0, FALSE);
            }

            return TRUE;

        case WM_VSCROLL:
            hCtrl      = cast(HWND)lParam;
            iCtrlID    = GetWindowLongPtr(hCtrl, GWL_ID);
            iIndex     = iCtrlID - 10;
            hwndParent = GetParent(hDlg);

            switch (LOWORD(wParam))
            {
                case SB_PAGEDOWN:
                    iColor[iIndex] += 15;    // fall through
                    goto case;

                case SB_LINEDOWN:
                    iColor[iIndex] = cast(ubyte)min(255, iColor[iIndex] + 1);
                    break;

                case SB_PAGEUP:
                    iColor[iIndex] -= 15;    // fall through
                    goto case;

                case SB_LINEUP:
                    iColor[iIndex] = cast(ubyte)max(0, iColor[iIndex] - 1);
                    break;

                case SB_TOP:
                    iColor[iIndex] = 0;
                    break;

                case SB_BOTTOM:
                    iColor[iIndex] = 255;
                    break;

                case SB_THUMBPOSITION:
                case SB_THUMBTRACK:
                    iColor[iIndex] = cast(ubyte)HIWORD(wParam);
                    break;

                default:
                    return FALSE;
            }

            SetScrollPos(hCtrl, SB_CTL,      iColor[iIndex], TRUE);
            SetDlgItemInt(hDlg,  iCtrlID + 3, iColor[iIndex], FALSE);

            DeleteObject(cast(HGDIOBJ)SetClassLong(hwndParent, GCL_HBRBACKGROUND,
                                                   cast(LONG)CreateSolidBrush(RGB(iColor[0], iColor[1], iColor[2]))));

            InvalidateRect(hwndParent, NULL, TRUE);
            return TRUE;

        default:
    }

    return FALSE;
}
