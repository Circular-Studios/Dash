/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module SysMets1;

import core.runtime;
import std.algorithm : max, min;
import std.string;
import std.conv;
import std.utf : count, toUTFz;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;

struct SysMetrics
{
    int    index;
    string label;
    string desc;
}

enum sysMetrics =
[
    SysMetrics(SM_CXSCREEN,             "SM_CXSCREEN",              "Screen width in pixels"),
    SysMetrics(SM_CYSCREEN,             "SM_CYSCREEN",              "Screen height in pixels"),
    SysMetrics(SM_CXVSCROLL,            "SM_CXVSCROLL",             "Vertical scroll width"),
    SysMetrics(SM_CYHSCROLL,            "SM_CYHSCROLL",             "Horizontal scroll height"),
    SysMetrics(SM_CYCAPTION,            "SM_CYCAPTION",             "Caption bar height"),
    SysMetrics(SM_CXBORDER,             "SM_CXBORDER",              "Window border width"),
    SysMetrics(SM_CYBORDER,             "SM_CYBORDER",              "Window border height"),
    SysMetrics(SM_CXFIXEDFRAME,         "SM_CXFIXEDFRAME",          "Dialog window frame width"),
    SysMetrics(SM_CYFIXEDFRAME,         "SM_CYFIXEDFRAME",          "Dialog window frame height"),
    SysMetrics(SM_CYVTHUMB,             "SM_CYVTHUMB",              "Vertical scroll thumb height"),
    SysMetrics(SM_CXHTHUMB,             "SM_CXHTHUMB",              "Horizontal scroll thumb width"),
    SysMetrics(SM_CXICON,               "SM_CXICON",                "Icon width"),
    SysMetrics(SM_CYICON,               "SM_CYICON",                "Icon height"),
    SysMetrics(SM_CXCURSOR,             "SM_CXCURSOR",              "Cursor width"),
    SysMetrics(SM_CYCURSOR,             "SM_CYCURSOR",              "Cursor height"),
    SysMetrics(SM_CYMENU,               "SM_CYMENU",                "Menu bar height"),
    SysMetrics(SM_CXFULLSCREEN,         "SM_CXFULLSCREEN",          "Full screen client area width"),
    SysMetrics(SM_CYFULLSCREEN,         "SM_CYFULLSCREEN",          "Full screen client area height"),
    SysMetrics(SM_CYKANJIWINDOW,        "SM_CYKANJIWINDOW",         "Kanji window height"),
    SysMetrics(SM_MOUSEPRESENT,         "SM_MOUSEPRESENT",          "Mouse present flag"),
    SysMetrics(SM_CYVSCROLL,            "SM_CYVSCROLL",             "Vertical scroll arrow height"),
    SysMetrics(SM_CXHSCROLL,            "SM_CXHSCROLL",             "Horizontal scroll arrow width"),
    SysMetrics(SM_DEBUG,                "SM_DEBUG",                 "Debug version flag"),
    SysMetrics(SM_SWAPBUTTON,           "SM_SWAPBUTTON",            "Mouse buttons swapped flag"),
    SysMetrics(SM_CXMIN,                "SM_CXMIN",                 "Minimum window width"),
    SysMetrics(SM_CYMIN,                "SM_CYMIN",                 "Minimum window height"),
    SysMetrics(SM_CXSIZE,               "SM_CXSIZE",                "Min/Max/Close button width"),
    SysMetrics(SM_CYSIZE,               "SM_CYSIZE",                "Min/Max/Close button height"),
    SysMetrics(SM_CXSIZEFRAME,          "SM_CXSIZEFRAME",           "Window sizing frame width"),
    SysMetrics(SM_CYSIZEFRAME,          "SM_CYSIZEFRAME",           "Window sizing frame height"),
    SysMetrics(SM_CXMINTRACK,           "SM_CXMINTRACK",            "Minimum window tracking width"),
    SysMetrics(SM_CYMINTRACK,           "SM_CYMINTRACK",            "Minimum window tracking height"),
    SysMetrics(SM_CXDOUBLECLK,          "SM_CXDOUBLECLK",           "Double click x tolerance"),
    SysMetrics(SM_CYDOUBLECLK,          "SM_CYDOUBLECLK",           "Double click y tolerance"),
    SysMetrics(SM_CXICONSPACING,        "SM_CXICONSPACING",         "Horizontal icon spacing"),
    SysMetrics(SM_CYICONSPACING,        "SM_CYICONSPACING",         "Vertical icon spacing"),
    SysMetrics(SM_MENUDROPALIGNMENT,    "SM_MENUDROPALIGNMENT",     "Left or right menu drop"),
    SysMetrics(SM_PENWINDOWS,           "SM_PENWINDOWS",            "Pen extensions installed"),
    SysMetrics(SM_DBCSENABLED,          "SM_DBCSENABLED",           "Double-Byte Char Set enabled"),
    SysMetrics(SM_CMOUSEBUTTONS,        "SM_CMOUSEBUTTONS",         "Number of mouse buttons"),
    SysMetrics(SM_SECURE,               "SM_SECURE",                "Security present flag"),
    SysMetrics(SM_CXEDGE,               "SM_CXEDGE",                "3-D border width"),
    SysMetrics(SM_CYEDGE,               "SM_CYEDGE",                "3-D border height"),
    SysMetrics(SM_CXMINSPACING,         "SM_CXMINSPACING",          "Minimized window spacing width"),
    SysMetrics(SM_CYMINSPACING,         "SM_CYMINSPACING",          "Minimized window spacing height"),
    SysMetrics(SM_CXSMICON,             "SM_CXSMICON",              "Small icon width"),
    SysMetrics(SM_CYSMICON,             "SM_CYSMICON",              "Small icon height"),
    SysMetrics(SM_CYSMCAPTION,          "SM_CYSMCAPTION",           "Small caption height"),
    SysMetrics(SM_CXSMSIZE,             "SM_CXSMSIZE",              "Small caption button width"),
    SysMetrics(SM_CYSMSIZE,             "SM_CYSMSIZE",              "Small caption button height"),
    SysMetrics(SM_CXMENUSIZE,           "SM_CXMENUSIZE",            "Menu bar button width"),
    SysMetrics(SM_CYMENUSIZE,           "SM_CYMENUSIZE",            "Menu bar button height"),
    SysMetrics(SM_ARRANGE,              "SM_ARRANGE",               "How minimized windows arranged"),
    SysMetrics(SM_CXMINIMIZED,          "SM_CXMINIMIZED",           "Minimized window width"),
    SysMetrics(SM_CYMINIMIZED,          "SM_CYMINIMIZED",           "Minimized window height"),
    SysMetrics(SM_CXMAXTRACK,           "SM_CXMAXTRACK",            "Maximum draggable width"),
    SysMetrics(SM_CYMAXTRACK,           "SM_CYMAXTRACK",            "Maximum draggable height"),
    SysMetrics(SM_CXMAXIMIZED,          "SM_CXMAXIMIZED",           "Width of maximized window"),
    SysMetrics(SM_CYMAXIMIZED,          "SM_CYMAXIMIZED",           "Height of maximized window"),
    SysMetrics(SM_NETWORK,              "SM_NETWORK",               "Network present flag"),
    SysMetrics(SM_CLEANBOOT,            "SM_CLEANBOOT",             "How system was booted"),
    SysMetrics(SM_CXDRAG,               "SM_CXDRAG",                "Avoid drag x tolerance"),
    SysMetrics(SM_CYDRAG,               "SM_CYDRAG",                "Avoid drag y tolerance"),
    SysMetrics(SM_SHOWSOUNDS,           "SM_SHOWSOUNDS",            "Present sounds visually"),
    SysMetrics(SM_CXMENUCHECK,          "SM_CXMENUCHECK",           "Menu check-mark width"),
    SysMetrics(SM_CYMENUCHECK,          "SM_CYMENUCHECK",           "Menu check-mark hight"),
    SysMetrics(SM_SLOWMACHINE,          "SM_SLOWMACHINE",           "Slow processor flag"),
    SysMetrics(SM_MIDEASTENABLED,       "SM_MIDEASTENABLED",        "Hebrew and Arabic enabled flag"),
    SysMetrics(SM_MOUSEWHEELPRESENT,    "SM_MOUSEWHEELPRESENT",     "Mouse wheel present flag"),
    SysMetrics(SM_XVIRTUALSCREEN,       "SM_XVIRTUALSCREEN",        "Virtual screen x origin"),
    SysMetrics(SM_YVIRTUALSCREEN,       "SM_YVIRTUALSCREEN",        "Virtual screen y origin"),
    SysMetrics(SM_CXVIRTUALSCREEN,      "SM_CXVIRTUALSCREEN",       "Virtual screen width"),
    SysMetrics(SM_CYVIRTUALSCREEN,      "SM_CYVIRTUALSCREEN",       "Virtual screen height"),
    SysMetrics(SM_CMONITORS,            "SM_CMONITORS",             "Number of monitors"),
    SysMetrics(SM_SAMEDISPLAYFORMAT,    "SM_SAMEDISPLAYFORMAT",     "Same color format flag")
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
    string appName = "SysMets2";

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

    hwnd = CreateWindow(appName.toUTF16z,                   // window class name
                        "Get System Metrics No. 2",         // window caption
                        WS_OVERLAPPEDWINDOW | WS_VSCROLL,   // window style
                        CW_USEDEFAULT,                      // initial x position
                        CW_USEDEFAULT,                      // initial y position
                        CW_USEDEFAULT,                      // initial x size
                        CW_USEDEFAULT,                      // initial y size
                        NULL,                               // parent window handle
                        NULL,                               // window menu handle
                        hInstance,                          // program instance handle
                        NULL);                              // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int cxChar, cxCaps, cyChar, cyClient, iVScrollPos;
    int i, y;
    HDC hdc;
    PAINTSTRUCT ps;
    RECT rect;
    TEXTMETRIC tm;

    switch (message)
    {
        case WM_CREATE:
        {
            hdc = GetDC(hwnd);
            scope(exit) ReleaseDC(hwnd, hdc);

            GetTextMetrics(hdc, &tm);   // Dimensions of the system font don't change
                                        // during a Windows session
            cxChar = tm.tmAveCharWidth;
            cxCaps = (tm.tmPitchAndFamily & 1 ? 3 : 2) * cxChar / 2;
            cyChar = tm.tmHeight + tm.tmExternalLeading;

            SetScrollRange(hwnd, SB_VERT, 0, sysMetrics.length - 1, FALSE);
            SetScrollPos(hwnd, SB_VERT, iVScrollPos, TRUE);

            return 0;
        }

        case WM_SIZE:
        {
            cyClient = HIWORD(lParam);
            return 0;
        }

        case WM_VSCROLL:
        {
            switch (LOWORD(wParam))
            {
                case SB_LINEUP:
                iVScrollPos -= 1;
                break;

                case SB_LINEDOWN:
                iVScrollPos += 1;
                break;

                case SB_PAGEUP:
                iVScrollPos -= cyClient / cyChar;
                break;

                case SB_PAGEDOWN:
                iVScrollPos += cyClient / cyChar;
                break;

                case SB_THUMBPOSITION:
                iVScrollPos = HIWORD (wParam);
                break;

                default:
            }

            iVScrollPos = max(0, min(iVScrollPos, sysMetrics.length - 1));

            if (iVScrollPos != GetScrollPos (hwnd, SB_VERT))
            {
                SetScrollPos(hwnd, SB_VERT, iVScrollPos, TRUE);
                InvalidateRect(hwnd, NULL, TRUE);
            }
            return 0;

        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);
            scope(exit) EndPaint(hwnd, &ps);

            foreach (index, metric; sysMetrics)
            {
                y = cyChar * (index - iVScrollPos);

                TextOut(hdc, 0, y, metric.label.toUTF16z, metric.label.count);
                TextOut(hdc, 22 * cxCaps, y, metric.desc.toUTF16z, metric.desc.count);

                string value = to!string(GetSystemMetrics(metric.index));

                // right-align
                SetTextAlign(hdc, TA_RIGHT | TA_TOP);
                TextOut(hdc, 22 * cxCaps + 40 * cxChar, y, value.toUTF16z, value.count);

                // restore alignment
                SetTextAlign(hdc, TA_LEFT | TA_TOP);
            }
            return 0;
        }

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
