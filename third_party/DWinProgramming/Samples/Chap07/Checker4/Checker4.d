/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Checker4;

import core.runtime;
import core.thread;
import core.stdc.config;
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

enum DIVISIONS = 5;
string childClass = "Checker4_Child";
int idFocus;

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    string appName = "Checker4";

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

    if(!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    wndclass.lpfnWndProc   = &ChildWndProc;
    wndclass.cbWndExtra    = c_long.sizeof;
    wndclass.hIcon         = NULL;
    wndclass.lpszClassName = childClass.toUTF16z;

    if(!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z, "Checker4 Mouse Hit-Test Demo",
                        WS_OVERLAPPEDWINDOW,
                        CW_USEDEFAULT, CW_USEDEFAULT,
                        CW_USEDEFAULT, CW_USEDEFAULT,
                        NULL, NULL, hInstance, NULL);

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while(GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HWND[DIVISIONS][DIVISIONS] hwndChild;
    int cxBlock, cyBlock, x, y;

    switch (message)
    {
        case WM_CREATE:
            for(x = 0; x < DIVISIONS; x++)
                for(y = 0; y < DIVISIONS; y++)
                    hwndChild[x][y] = CreateWindow(childClass.toUTF16z, NULL,
                                                    WS_CHILDWINDOW | WS_VISIBLE,
                                                    0, 0, 0, 0,
                                                    hwnd, cast(HMENU)(y << 8 | x),  // child ID
                                                    cast(HINSTANCE)GetWindowLongPtr(hwnd, GWL_HINSTANCE),  // hInstance
                                                    NULL);

            return 0;

        case WM_SIZE:
            cxBlock = LOWORD(lParam) / DIVISIONS;
            cyBlock = HIWORD(lParam) / DIVISIONS;

            for(x = 0; x < DIVISIONS; x++)
                for(y = 0; y < DIVISIONS; y++)
                    MoveWindow(hwndChild[x][y],
                                x * cxBlock, y * cyBlock,
                                cxBlock, cyBlock, TRUE);

            return 0;

        case WM_LBUTTONDOWN:
            MessageBeep(0);
            return 0;

        case WM_SETFOCUS:
            // GetDlgItem takes a parent hwnd and child ID to get child hwnd.
            // child will update idFocus
            SetFocus(GetDlgItem(hwnd, idFocus));
            return 0;

        case WM_KEYDOWN:    // Possibly change the focus window
            x = idFocus & 0xFF;
            y = idFocus >> 8;

            switch (wParam)
            {
                case VK_UP:
                    y--;                    break;

                case VK_DOWN:
                    y++;                    break;

                case VK_LEFT:
                    x--;                    break;

                case VK_RIGHT:
                    x++;                    break;

                case VK_HOME:
                    x = y = 0;              break;

                case VK_END:
                    x = y = DIVISIONS - 1;  break;

                default:
                    return 0;
            }

            x = (x + DIVISIONS) % DIVISIONS;    // wrap around if went beyond bounds
            y = (y + DIVISIONS) % DIVISIONS;

            idFocus = y << 8 | x;

            SetFocus(GetDlgItem(hwnd, idFocus));
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern(Windows)
LRESULT ChildWndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    HDC hdc;
    PAINTSTRUCT ps;
    RECT rect;

    switch (message)
    {
        case WM_CREATE:
            SetWindowLongPtr(hwnd, 0, 0);      // on/off flag
            return 0;

        case WM_KEYDOWN:
            // Send most key presses to the parent window, except return or space
            if (wParam != VK_RETURN && wParam != VK_SPACE)
            {
                SendMessage(GetParent(hwnd), message, wParam, lParam);
                return 0;
            }
            
            // For Return and Space, fall through to WM_LBUTTONDOWN, which will toggle the square
            goto case;

        case WM_LBUTTONDOWN:
            SetWindowLongPtr(hwnd, 0, 1 ^ GetWindowLongPtr(hwnd, 0));  // toggle int
            SetFocus(hwnd);
            InvalidateRect(hwnd, NULL, FALSE);
            return 0;

        // For focus messages, invalidate the window for repainting
        case WM_SETFOCUS:
            // get child window ID (can ommit GWL_ID if using GetDlgCtrlID)
            idFocus = GetWindowLongPtr(hwnd, GWL_ID);
            goto case;

        // Fall through
        case WM_KILLFOCUS:
            InvalidateRect(hwnd, NULL, TRUE);
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            GetClientRect(hwnd, &rect);
            Rectangle(hdc, 0, 0, rect.right, rect.bottom);

            // Draw the "x" mark
            if (GetWindowLongPtr(hwnd, 0))     // get int state
            {
                MoveToEx(hdc, 0,          0, NULL);
                LineTo  (hdc, rect.right, rect.bottom);
                MoveToEx(hdc, 0,          rect.bottom, NULL);
                LineTo  (hdc, rect.right, 0);
            }

            // Draw the "focus" rectangle
            if (hwnd == GetFocus())     // get hwnd of currently focused window, see if matches ours
            {
                rect.left   += rect.right / 10;
                rect.right  -= rect.left;
                rect.top    += rect.bottom / 10;
                rect.bottom -= rect.top;

                SelectObject(hdc, GetStockObject(NULL_BRUSH));
                SelectObject(hdc, CreatePen(PS_DASH, 0, 0));
                Rectangle(hdc, rect.left, rect.top, rect.right, rect.bottom);
                DeleteObject(SelectObject(hdc, GetStockObject(BLACK_PEN)));
            }

            EndPaint(hwnd, &ps);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
