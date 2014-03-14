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
    string appName = "SysMets3";

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
                        "Get System Metrics No. 3",         // window caption
                        WS_OVERLAPPEDWINDOW | WS_VSCROLL |
                        WS_HSCROLL,                         // window style
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
    static int cxChar, cxCaps, cyChar, cxClient, cyClient, iMaxWidth;
    HDC hdc;
    int x, y, iVertPos, iHorzPos, iPaintStart, iPaintEnd;
    PAINTSTRUCT ps;
    SCROLLINFO  si;
    TEXTMETRIC tm;

    switch(message)
    {
        case WM_CREATE:
        {
            hdc = GetDC(hwnd);
            scope(exit)
                ReleaseDC(hwnd, hdc);

            GetTextMetrics(hdc, &tm);
            cxChar = tm.tmAveCharWidth;
            cxCaps = (tm.tmPitchAndFamily & 1 ? 3 : 2) * cxChar / 2;
            cyChar = tm.tmHeight + tm.tmExternalLeading;

            // Save the width of the three columns
            iMaxWidth = 40 * cxChar + 22 * cxCaps;

            return 0;
        }

        case WM_SIZE:
        {
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);

            // Set vertical scroll bar range and page size
            si.fMask  = SIF_RANGE | SIF_PAGE;
            si.nMin   = 0;
            si.nMax   = sysMetrics.length - 1;       // actual max thumb position will be nMax - nPage
            si.nPage  = cyClient / cyChar;  // how many scroll units there are in the client-area
                                            // cyClient = height, cyChar = font height
            SetScrollInfo(hwnd, SB_VERT, &si, TRUE);

            // Set horizontal scroll bar range and page size
            si.fMask  = SIF_RANGE | SIF_PAGE;
            si.nMin   = 0;
            si.nMax   = 2 + iMaxWidth / cxChar;
            si.nPage  = cxClient / cxChar;
            SetScrollInfo(hwnd, SB_HORZ, &si, TRUE);

            return 0;
        }

        case WM_VSCROLL:
        {
            // Get all the vertical scroll bar information
            si.fMask  = SIF_ALL;
            GetScrollInfo(hwnd, SB_VERT, &si);

            // Save the position for comparison
            iVertPos = si.nPos;
            switch (LOWORD(wParam))
            {
                case SB_TOP:
                    si.nPos = si.nMin;
                    break;

                case SB_BOTTOM:
                    si.nPos = si.nMax;
                    break;

                case SB_LINEUP:
                    si.nPos -= 1;
                    break;

                case SB_LINEDOWN:
                    si.nPos += 1;
                    break;

                case SB_PAGEUP:
                    si.nPos -= si.nPage;
                    break;

                case SB_PAGEDOWN:
                    si.nPos += si.nPage;
                    break;

                case SB_THUMBTRACK:
                    si.nPos = si.nTrackPos;     // track position immediately
                    break;

                default:
                    break;
            }

            // Set the position and then retrieve it.  Due to adjustments
            // by Windows it may not be the same as the value set.
            si.fMask = SIF_POS;
            SetScrollInfo(hwnd, SB_VERT, &si, TRUE);
            GetScrollInfo(hwnd, SB_VERT, &si);

            // If the position has changed, scroll the window and update it
            if (si.nPos != iVertPos)
            {
                ScrollWindow(hwnd, 0, cyChar * (iVertPos - si.nPos), NULL, NULL);
                UpdateWindow(hwnd);
            }

            return 0;
        }

        case WM_HSCROLL:
        {
            // Get all the horizontal scroll bar information
            si.fMask  = SIF_ALL;

            // Save the position for comparison
            GetScrollInfo(hwnd, SB_HORZ, &si);
            iHorzPos = si.nPos;

            switch (LOWORD(wParam))
            {
                case SB_LINELEFT:
                    si.nPos -= 1;
                    break;

                case SB_LINERIGHT:
                    si.nPos += 1;
                    break;

                case SB_PAGELEFT:
                    si.nPos -= si.nPage;
                    break;

                case SB_PAGERIGHT:
                    si.nPos += si.nPage;
                    break;

                case SB_THUMBPOSITION:
                    si.nPos = si.nTrackPos;     // user released thumb to new position
                    break;

                default:
                    break;
            }

            // Set the position and then retrieve it.  Due to adjustments
            // by Windows it may not be the same as the value set.
            si.fMask = SIF_POS;
            SetScrollInfo(hwnd, SB_HORZ, &si, TRUE);
            GetScrollInfo(hwnd, SB_HORZ, &si);  // this will do bounds checking and retrieve (?)

            // If the position has changed, scroll the window
            if (si.nPos != iHorzPos)
            {
                ScrollWindow(hwnd, cxChar * (iHorzPos - si.nPos), 0, NULL, NULL);
            }

            return 0;
        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);
            scope(exit)
                EndPaint(hwnd, &ps);

            // Get vertical scroll bar position
            si.fMask  = SIF_POS;
            GetScrollInfo(hwnd, SB_VERT, &si);
            iVertPos = si.nPos;

            // Get horizontal scroll bar position
            GetScrollInfo(hwnd, SB_HORZ, &si);
            iHorzPos = si.nPos;

            // Find painting limits (optimization)
            iPaintStart = max(0, iVertPos + ps.rcPaint.top / cyChar);
            iPaintEnd   = min(sysMetrics.length - 1, iVertPos + ps.rcPaint.bottom / cyChar);

            auto index = iPaintStart;
            foreach (metric; sysMetrics[iPaintStart .. iPaintEnd + 1])
            {
                x = cxChar * (1 - iHorzPos);
                y = cyChar * (index - iVertPos);

                TextOut(hdc, x, y, metric.label.toUTF16z, metric.label.count);
                TextOut(hdc, x + 22 * cxCaps, y, metric.desc.toUTF16z, metric.desc.count);

                SetTextAlign(hdc, TA_RIGHT | TA_TOP);

                string value = to!string(GetSystemMetrics(metric.index));
                TextOut(hdc, x + 22 * cxCaps + 40 * cxChar, y, value.toUTF16z, value.count);
                SetTextAlign(hdc, TA_LEFT | TA_TOP);

                index++;
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
