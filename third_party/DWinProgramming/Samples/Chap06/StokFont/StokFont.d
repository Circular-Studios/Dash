/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module StokFont;

import core.runtime;
import core.thread;
import std.algorithm : min, max;
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

struct StockFont
{
    int idStockFont;
    string szStockFont;
}

extern(Windows)
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
    catch(Throwable o)
    {
        MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    string appName = "StokFont";

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
    wndclass.hbrBackground = cast(HBRUSH)GetStockObject(WHITE_BRUSH);

    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        "Stock Fonts",                 // window caption
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

extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    enum stockfont =
    [
        StockFont(OEM_FIXED_FONT,       "OEM_FIXED_FONT"),
        StockFont(ANSI_FIXED_FONT,      "ANSI_FIXED_FONT"),
        StockFont(ANSI_VAR_FONT,        "ANSI_VAR_FONT"),
        StockFont(SYSTEM_FONT,          "SYSTEM_FONT"),
        StockFont(DEVICE_DEFAULT_FONT,  "DEVICE_DEFAULT_FONT"),
        StockFont(SYSTEM_FIXED_FONT,    "SYSTEM_FIXED_FONT"),
        StockFont(DEFAULT_GUI_FONT,     "DEFAULT_GUI_FONT")
    ];

    static int iFont;
    wchar[256] szFaceName;
    string szBuffer;
    TEXTMETRIC tm;
    int cxGrid, cyGrid;

    static int cLinesMax, cLines;
    static int cxClientMax, cyClientMax, cxClient, cyClient, cxChar, cyChar;
    static MSG[] msgArr;
    static int  msgCount;
    static RECT rectScroll;

    enum szTop = "Message        Key       Char     Repeat Scan Ext ALT Prev Tran";
    enum szUnd = "_______        ___       ____     ______ ____ ___ ___ ____ ____";
    enum szFormat = ["%-13s %3s %-15s%1s%6s %4s %3s %3s %4s %4s",
                     "%-13s            0x%04X%1s%s %6s %4s %3s %3s %4s %4s"];
    enum szYes  = "Yes";
    enum szNo   = "No";
    enum szDown = "Down";
    enum szUp   = "Up";
    enum szMessage =
    [
        "WM_KEYDOWN",    "WM_KEYUP",
        "WM_CHAR",       "WM_DEADCHAR",
        "WM_SYSKEYDOWN", "WM_SYSKEYUP",
        "WM_SYSCHAR",    "WM_SYSDEADCHAR"
    ];

    HDC hdc;
    int iType;
    PAINTSTRUCT ps;
    char[32]  szKeyName;
    char[] keyName;
    int keyLength;

    switch (message)
    {
        case WM_CREATE:
            SetScrollRange(hwnd, SB_VERT, 0, stockfont.length - 1, TRUE);
            return 0;

        case WM_DISPLAYCHANGE:
            InvalidateRect(hwnd, NULL, TRUE);
            return 0;

        case WM_VSCROLL:
            switch(LOWORD(wParam))
            {
                case SB_TOP:
                    iFont = 0;
                    break;

                case SB_BOTTOM:
                    iFont = stockfont.length - 1;
                    break;

                case SB_LINEUP:
                case SB_PAGEUP:
                    iFont -= 1;
                    break;

                case SB_LINEDOWN:
                case SB_PAGEDOWN:
                    iFont += 1;
                    break;

                case SB_THUMBPOSITION:
                    iFont = HIWORD(wParam);
                    break;

                default:
            }

            iFont = max(0, min(stockfont.length - 1, iFont));
            SetScrollPos(hwnd, SB_VERT, iFont, TRUE);
            InvalidateRect(hwnd, NULL, TRUE);
            return 0;

        case WM_KEYDOWN:
        {
            switch(wParam)
            {
                case VK_HOME:
                    SendMessage(hwnd, WM_VSCROLL, SB_TOP, 0);
                    break;

                case VK_END:
                    SendMessage(hwnd, WM_VSCROLL, SB_BOTTOM, 0);
                    break;

                case VK_PRIOR:
                case VK_LEFT:
                case VK_UP:
                    SendMessage(hwnd, WM_VSCROLL, SB_LINEUP, 0);
                    break;

                case VK_NEXT:
                case VK_RIGHT:
                case VK_DOWN:
                    SendMessage(hwnd, WM_VSCROLL, SB_PAGEDOWN, 0);
                    break;

                default:
            }

            return 0;
        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);
            scope(exit) EndPaint(hwnd, &ps);

            SelectObject(hdc, GetStockObject(stockfont[iFont].idStockFont));
            auto newlength = GetTextFace(hdc, szFaceName.length, szFaceName.ptr);

            GetTextMetrics(hdc, &tm);
            cxGrid = max(3 * tm.tmAveCharWidth, 2 * tm.tmMaxCharWidth);
            cyGrid = tm.tmHeight + 3;

            szBuffer = format("%s: Face Name = %s, CharSet = %s",
                              stockfont[iFont].szStockFont,
                              szFaceName[0..newlength-1],
                              tm.tmCharSet);

            TextOut(hdc, 0, 0, szBuffer.toUTF16z, szBuffer.count);

            SetTextAlign(hdc, TA_TOP | TA_CENTER);

            // vertical and horizontal lines
            foreach (index; 0 .. 17)
            {
                MoveToEx(hdc,(index + 2) * cxGrid,  2 * cyGrid, NULL);
                LineTo  (hdc,(index + 2) * cxGrid, 19 * cyGrid);

                MoveToEx(hdc,      cxGrid,(index + 3) * cyGrid, NULL);
                LineTo  (hdc, 18 * cxGrid,(index + 3) * cyGrid);
            }

            // vertical and horizontal headings
            foreach (index; 0 .. 16)
            {
                szBuffer = format("%X-", index);
                TextOut(hdc,(2 * index + 5) * cxGrid / 2, 2 * cyGrid + 2, szBuffer.toUTF16z, szBuffer.count);
                TextOut(hdc, 3 * cxGrid / 2,(index + 3) * cyGrid + 2, szBuffer.toUTF16z, szBuffer.count);
            }

            // draw chars
            int temp;
            foreach (y; 0 .. 16)
            foreach (x; 0 .. 16)
            {
                temp = 16 * x + y;
                TextOut(hdc,(2 * x + 5) * cxGrid / 2, (y + 3) * cyGrid + 2, to!wstring(cast(char)temp).ptr, 1);
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


