/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Colors1;

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

int idFocus;
WNDPROC[3] OldScroll;
HINSTANCE hInst;

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
    hInst = hInstance;
    string appName = "Colors1";

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
                        "Color Scroll",                // window caption
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

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static COLORREF[3] crPrim = [RGB(255, 0, 0), RGB(0, 255, 0), RGB(0, 0, 255)];
    static HBRUSH[3] hBrush;
    static HBRUSH hBrushStatic;
    static HWND[3] hwndScroll;
    static HWND[3] hwndLabel;
    static HWND[3] hwndValue;
    static HWND hwndRect;
    static int[3] color;
    static int  cyChar;
    static RECT rcColor;

    immutable(wchar) *[] szColorLabel =
    [
        "Red", "Green",
        "Blue"
    ];

    HINSTANCE hInstance;
    int i, cxClient, cyClient;
    char[] szBuffer;

    switch (message)
    {
        case WM_CREATE:
            hInstance = cast(HINSTANCE)GetWindowLongPtr(hwnd, GWL_HINSTANCE);

            // Create the white-rectangle window against which the
            // scroll bars will be positioned. The child window ID is 9.
            hwndRect = CreateWindow("static", NULL,
                                    WS_CHILD | WS_VISIBLE | SS_WHITERECT,
                                    0, 0, 0, 0,
                                    hwnd, cast(HMENU)9, hInstance, NULL);

            for (i = 0; i < 3; i++)
            {
                // The three scroll bars have IDs 0, 1, and 2, with
                // scroll bar ranges from 0 through 255.
                hwndScroll[i] = CreateWindow("scrollbar", NULL,
                                             WS_CHILD | WS_VISIBLE |
                                             WS_TABSTOP | SBS_VERT,
                                             0, 0, 0, 0,
                                             hwnd, cast(HMENU)i, hInstance, NULL);

                SetScrollRange(hwndScroll[i], SB_CTL, 0, 255, FALSE);
                SetScrollPos(hwndScroll[i], SB_CTL, 0, FALSE);

                // The three color-name labels have IDs 3, 4, and 5,
                // and text strings "Red", "Green", and "Blue".
                hwndLabel[i] = CreateWindow("static", szColorLabel[i],
                                            WS_CHILD | WS_VISIBLE | SS_CENTER,
                                            0, 0, 0, 0,
                                            hwnd, cast(HMENU)(i + 3),
                                            hInstance, NULL);

                // The three color-value text fields have IDs 6, 7,
                // and 8, and initial text strings of "0".
                hwndValue[i] = CreateWindow("static", "0",
                                            WS_CHILD | WS_VISIBLE | SS_CENTER,
                                            0, 0, 0, 0,
                                            hwnd, cast(HMENU)(i + 6),
                                            hInstance, NULL);

                // override scrollbar's window procedure, keep old one since we'll use it
                OldScroll[i] = cast(WNDPROC) SetWindowLongPtr(hwndScroll[i], GWL_WNDPROC, cast(LONG)&ScrollProc);
                hBrush[i]    = CreateSolidBrush(crPrim[i]);
            }

            hBrushStatic = CreateSolidBrush(GetSysColor(COLOR_BTNHIGHLIGHT));

            cyChar = HIWORD(GetDialogBaseUnits());
            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);

            SetRect(&rcColor, cxClient / 2, 0, cxClient, cyClient);

            MoveWindow(hwndRect, 0, 0, cxClient / 2, cyClient, TRUE);

            for (i = 0; i < 3; i++)
            {
                MoveWindow(hwndScroll[i],
                           (2 * i + 1) * cxClient / 14, 2 * cyChar,
                           cxClient / 14, cyClient - 4 * cyChar, TRUE);

                MoveWindow(hwndLabel[i],
                           (4 * i + 1) * cxClient / 28, cyChar / 2,
                           cxClient / 7, cyChar, TRUE);

                MoveWindow(hwndValue[i],
                           (4 * i + 1) * cxClient / 28,
                           cyClient - 3 * cyChar / 2,
                           cxClient / 7, cyChar, TRUE);
            }

            SetFocus(hwnd);
            return 0;

        case WM_SETFOCUS:
            SetFocus(hwndScroll[idFocus]);
            return 0;

        case WM_VSCROLL:
            i = GetWindowLongPtr(cast(HWND)lParam, GWL_ID);

            switch (LOWORD(wParam))
            {
                case SB_PAGEDOWN:
                    color[i] += 15;
                    goto case;

                // fall through
                case SB_LINEDOWN:
                    color[i] = min(255, color[i] + 1);
                    break;

                case SB_PAGEUP:
                    color[i] -= 15;
                    goto case;

                // fall through
                case SB_LINEUP:
                    color[i] = max(0, color[i] - 1);
                    break;

                case SB_TOP:
                    color[i] = 0;
                    break;

                case SB_BOTTOM:
                    color[i] = 255;
                    break;

                case SB_THUMBPOSITION:
                case SB_THUMBTRACK:
                    color[i] = HIWORD(wParam);
                    break;

                default:
                    break;
            }

            SetScrollPos(hwndScroll[i], SB_CTL, color[i], TRUE);
            szBuffer = format("%s", color[i]).dup;
            SetWindowText(hwndValue[i], szBuffer.toUTF16z);

            // This sets the new class background, and deletes the old background brush
            DeleteObject(cast(HBRUSH)SetClassLong(hwnd, GCL_HBRBACKGROUND,
                                                  cast(LONG)CreateSolidBrush(RGB(to!ubyte (color[0]), to!ubyte (color[1]), to!ubyte (color[2])))));

            InvalidateRect(hwnd, &rcColor, TRUE);
            return 0;

        case WM_CTLCOLORSCROLLBAR:
            i = GetWindowLongPtr(cast(HWND)lParam, GWL_ID);
            return cast(LRESULT)hBrush[i];

        case WM_CTLCOLORSTATIC:
            i = GetWindowLongPtr(cast(HWND)lParam, GWL_ID);

            if (i >= 3 && i <= 8)  // static text controls
            {
                SetTextColor(cast(HDC)wParam, crPrim[i % 3]);
                SetBkColor(cast(HDC)wParam, GetSysColor(COLOR_BTNHIGHLIGHT));
                return cast(LRESULT)hBrushStatic;
            }

            break;

        case WM_SYSCOLORCHANGE:
            DeleteObject(hBrushStatic);
            hBrushStatic = CreateSolidBrush(GetSysColor(COLOR_BTNHIGHLIGHT));
            return 0;

        case WM_DESTROY:
            DeleteObject(cast(HBRUSH)SetClassLong(hwnd, GCL_HBRBACKGROUND, cast(LONG)GetStockObject(WHITE_BRUSH)));

            for (i = 0; i < 3; i++)
                DeleteObject(hBrush[i]);

            DeleteObject(hBrushStatic);
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern (Windows)
LRESULT ScrollProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    int id = GetWindowLongPtr(hwnd, GWL_ID);

    switch (message)
    {
        case WM_KEYDOWN:

            if (wParam == VK_TAB)
                SetFocus(GetDlgItem(GetParent(hwnd), (id + (GetKeyState(VK_SHIFT) < 0 ? 2 : 1)) % 3));

            break;

        case WM_SETFOCUS:
            idFocus = id;
            break;

        default:
    }

    return CallWindowProc(OldScroll[id], hwnd, message, wParam, lParam);
}
