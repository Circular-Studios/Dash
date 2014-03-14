/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module BtnLook;

import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.range;
import std.string;
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

struct Button
{
    int iStyle;
    immutable(wchar)* szText;
}

Button[] buttons =
[
    Button(BS_PUSHBUTTON,      "PUSHBUTTON"   ),
    Button(BS_DEFPUSHBUTTON,   "DEFPUSHBUTTON"),
    Button(BS_CHECKBOX,        "CHECKBOX"     ),
    Button(BS_AUTOCHECKBOX,    "AUTOCHECKBOX" ),
    Button(BS_RADIOBUTTON,     "RADIOBUTTON"  ),
    Button(BS_3STATE,          "3STATE"       ),
    Button(BS_AUTO3STATE,      "AUTO3STATE"   ),
    Button(BS_GROUPBOX,        "GROUPBOX"     ),
    Button(BS_AUTORADIOBUTTON, "AUTORADIO"    ),
    Button(BS_OWNERDRAW,       "OWNERDRAW"    ),
];

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
    string appName = "BtnLook";

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
                        "Button Look",                 // window caption
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
    static HWND[] hwndButtons;

    if (hwndButtons is null)
    {
        hwndButtons.length = buttons.length;
    }

    static RECT rect;
    static szTop    = "message            wParam       lParam";
    static szUnd    = "_______            ______       ______";
    static szFormat = "%-16s%04X-%04X    %04X-%04X";
    static char[] szBuffer;
    static int cxChar, cyChar;
    HDC hdc;
    PAINTSTRUCT ps;
    int i;

    switch (message)
    {
        case WM_CREATE:
            cxChar = LOWORD(GetDialogBaseUnits());
            cyChar = HIWORD(GetDialogBaseUnits());

            foreach (index, button, ref hwndButton; lockstep(buttons, hwndButtons))
            {
                hwndButton = CreateWindow("button",
                                          button.szText,
                                          WS_CHILD | WS_VISIBLE | button.iStyle,
                                          cxChar, cyChar * (1 + 2 * index),
                                          20 * cxChar, 7 * cyChar / 4,
                                          hwnd, cast(HMENU)index,
                                          (cast(LPCREATESTRUCT)lParam).hInstance, // lparam is createstruct,
                                                                                  // but could use global window handle
                                          NULL);
            }

            return 0;

        case WM_SIZE:
            rect.left   = 24 * cxChar;
            rect.top    =  2 * cyChar;
            rect.right  = LOWORD(lParam);
            rect.bottom = HIWORD(lParam);
            return 0;

        // ~ case WM_KILLFOCUS:
        // ~ if (hwnd == GetParent(cast(HWND)wParam))
        // ~ SetFocus(hwnd);

        // ~ return 0;

        case WM_PAINT:
            InvalidateRect(hwnd, &rect, TRUE);

            hdc = BeginPaint(hwnd, &ps);
            SelectObject(hdc, GetStockObject(SYSTEM_FIXED_FONT));
            SetBkMode(hdc, TRANSPARENT);

            TextOut(hdc, 24 * cxChar, cyChar, szTop.toUTF16z, szTop.count);
            TextOut(hdc, 24 * cxChar, cyChar, szUnd.toUTF16z, szUnd.count);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DRAWITEM:
        case WM_COMMAND:
            ScrollWindow(hwnd, 0, -cyChar, &rect, &rect);

            hdc = GetDC(hwnd);
            SelectObject(hdc, GetStockObject(SYSTEM_FIXED_FONT));

            szBuffer = format(szFormat,
                              message == WM_DRAWITEM ? "WM_DRAWITEM" : "WM_COMMAND",
                              HIWORD(wParam), LOWORD(wParam),
                              HIWORD(lParam), LOWORD(lParam)).dup;

            TextOut(hdc, 24 * cxChar, cyChar * (rect.bottom / cyChar - 1),
                    szBuffer.toUTF16z, szBuffer.count);

            ReleaseDC(hwnd, hdc);
            ValidateRect(hwnd, &rect);
            break;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
