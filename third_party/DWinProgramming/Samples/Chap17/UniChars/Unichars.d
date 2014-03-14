/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module name;

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
pragma(lib, "comdlg32.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.commdlg;

import resource;

string appName     = "UniChars";
string description = "Unicode Characters";
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
    static CHOOSEFONT cf;
    static int iPage;
    static LOGFONT lf;
    HDC hdc;
    int cxChar, cyChar, x, y, i, cxLabels;
    PAINTSTRUCT ps;
    SIZE  size;
    string szBuffer;
    TEXTMETRIC tm;
    WCHAR ch;

    switch (message)
    {
        case WM_CREATE:
            hdc         = GetDC(hwnd);
            lf.lfHeight = -GetDeviceCaps(hdc, LOGPIXELSY) / 6;   // 12 points
            auto str = "Lucida Sans Unicode\0";
            lf.lfFaceName[0..str.length] = str.toUTF16;
            ReleaseDC(hwnd, hdc);

            cf.hwndOwner = hwnd;
            cf.lpLogFont = &lf;
            cf.Flags     = CF_INITTOLOGFONTSTRUCT | CF_SCREENFONTS;

            SetScrollRange(hwnd, SB_VERT, 0, 255, FALSE);
            SetScrollPos(hwnd, SB_VERT, iPage,  TRUE );
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_FONT:

                    if (ChooseFont(&cf))
                        InvalidateRect(hwnd, NULL, TRUE);

                    return 0;

                default:
            }

            return 0;

        case WM_VSCROLL:

            switch (LOWORD(wParam))
            {
                case SB_LINEUP:
                    iPage -=  1;  break;

                case SB_LINEDOWN:
                    iPage +=  1;  break;

                case SB_PAGEUP:
                    iPage -= 16;  break;

                case SB_PAGEDOWN:
                    iPage += 16;  break;

                case SB_THUMBPOSITION:
                    iPage = HIWORD(wParam);  break;

                default:
                    return 0;
            }

            iPage = max(0, min(iPage, 255));

            SetScrollPos(hwnd, SB_VERT, iPage, TRUE);
            InvalidateRect(hwnd, NULL, TRUE);
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            SelectObject(hdc, CreateFontIndirect(&lf));

            GetTextMetrics(hdc, &tm);
            cxChar = tm.tmMaxCharWidth;
            cyChar = tm.tmHeight + tm.tmExternalLeading;

            cxLabels = 0;

            for (i = 0; i < 16; i++)
            {
                szBuffer = format(" 000%1X: ", i);
                GetTextExtentPoint(hdc, szBuffer.toUTF16z, 7, &size);

                cxLabels = max(cxLabels, size.cx);
            }

            for (y = 0; y < 16; y++)
            {
                szBuffer = format(" %03X_: ", 16 * iPage + y);
                TextOut(hdc, 0, y * cyChar, szBuffer.toUTF16z, 7);

                for (x = 0; x < 16; x++)
                {
                    ch = cast(WCHAR)(256 * iPage + 16 * y + x);
                    TextOut(hdc, x * cxChar + cxLabels, y * cyChar, &ch, 1);
                }
            }

            DeleteObject(SelectObject(hdc, GetStockObject(SYSTEM_FONT)));
            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
