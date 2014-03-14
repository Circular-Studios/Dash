/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module KeyView1;

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
    string appName = "KeyView1";

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
                        "Keyboard Message Viewer #1",  // window caption
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
    static int cLinesMax, cLines;
    static int cxClientMax, cyClientMax, cxClient, cyClient, cxChar, cyChar;
    static MSG[] msgArr;
    static int msgCount;
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
    string szBuffer;
    wchar[32] szKeyName;
    wchar[] keyName;
    int keyLength;
    TEXTMETRIC tm;

    switch (message)
    {
        case WM_CREATE:
        case WM_DISPLAYCHANGE:
        {
            // Get maximum size of client area
            cxClientMax = GetSystemMetrics(SM_CXMAXIMIZED);
            cyClientMax = GetSystemMetrics(SM_CYMAXIMIZED);

            hdc = GetDC(hwnd);
            scope(exit) ReleaseDC(hwnd, hdc);

            // Get character size for fixed-pitch font
            SelectObject(hdc, GetStockObject(SYSTEM_FIXED_FONT));
            GetTextMetrics(hdc, &tm);
            cxChar = tm.tmAveCharWidth;
            cyChar = tm.tmHeight;
            cLinesMax = cyClientMax / cyChar;
            cLines = 0;
            goto case WM_SIZE;
        }

        case WM_SIZE:
        {
            if (message == WM_SIZE)
            {
                cxClient = LOWORD(lParam);
                cyClient = HIWORD(lParam);
            }

            // Calculate scrolling rectangle
            rectScroll.left   = 0;
            rectScroll.right  = cxClient;
            rectScroll.top    = cyChar;
            rectScroll.bottom = cyChar * (cyClient / cyChar);

            InvalidateRect(hwnd, NULL, TRUE);
            return 0;
        }

        case WM_KEYDOWN:
        case WM_KEYUP:
        case WM_CHAR:
        case WM_DEADCHAR:
        case WM_SYSKEYDOWN:
        case WM_SYSKEYUP:
        case WM_SYSCHAR:
        case WM_SYSDEADCHAR:
        {
            msgArr ~= MSG(hwnd, message, wParam, lParam);
            cLines = min(cLines + 1, cLinesMax);

            // Scroll up
            ScrollWindow(hwnd, 0, -cyChar, &rectScroll, &rectScroll);
            break;
        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);
            scope(exit) EndPaint(hwnd, &ps);

            SelectObject(hdc, GetStockObject(SYSTEM_FIXED_FONT));
            SetBkMode(hdc, TRANSPARENT);
            TextOut(hdc, 0, 0, szTop.toUTF16z, szTop.count);
            TextOut(hdc, 0, 0, szUnd.toUTF16z, szUnd.count);

            foreach (index, myMsg; lockstep(iota(0, min(cLines, cyClient / cyChar - 1)), retro(msgArr)))
            {
                iType = myMsg.message == WM_CHAR ||
                        myMsg.message == WM_SYSCHAR ||
                        myMsg.message == WM_DEADCHAR ||
                        myMsg.message == WM_SYSDEADCHAR;


                keyLength = GetKeyNameText(myMsg.lParam, szKeyName.ptr, szKeyName.length);
                keyName = szKeyName[0..keyLength];

                szBuffer = format(szFormat[iType],
                                  szMessage[myMsg.message - WM_KEYFIRST],
                                  myMsg.wParam,
                                  (iType ? "" : keyName.dup),
                                  (iType ? to!string(cast(char*)&myMsg.wParam) : ""),
                                  LOWORD(myMsg.lParam),
                                  HIWORD(myMsg.lParam) & 0xFF,
                                  (0x01000000 & myMsg.lParam ? szYes  : szNo),
                                  (0x20000000 & myMsg.lParam ? szYes  : szNo),
                                  (0x40000000 & myMsg.lParam ? szDown : szUp),
                                  (0x80000000 & myMsg.lParam ? szUp   : szDown)
                );

                TextOut(hdc, 0, (cyClient / cyChar - 1 - index) * cyChar, szBuffer.toUTF16z, szBuffer.count);
            }

            return 0;
        }

        case WM_DESTROY:
        {
            PostQuitMessage(0);
            return 0;
        }

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
