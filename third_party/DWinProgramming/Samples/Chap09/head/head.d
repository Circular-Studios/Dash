/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module head;

/+
 + todo: needs refactor due to wstring shenanigans.
 +/

import core.runtime;
import core.thread;
import std.conv;
import std.file;
import std.math;
import std.range;
import std.string;
import std.utf : count, toUTFz, UTFException;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;

enum ID_LIST =  1;
enum ID_TEXT =  2;
enum MAXREAD =  8192;
enum DIRATTR = (DDL_READWRITE | DDL_READONLY | DDL_HIDDEN | DDL_SYSTEM | DDL_DIRECTORY | DDL_ARCHIVE | DDL_DRIVES);
enum DTFLAGS = (DT_WORDBREAK | DT_EXPANDTABS | DT_NOCLIP | DT_NOPREFIX);

enum ID_TIMER = 1;
enum TWOPI    = (2 * PI);
enum ID_SMALLER =    1;     // button window unique id
enum ID_LARGER  =    2;     // same
enum BTN_WIDTH  =    "(8 * cxChar)";
enum BTN_HEIGHT =    "(4 * cyChar)";
int idFocus;

WNDPROC OldList;
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
    string appName = "head";

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
    wndclass.hbrBackground = cast(HBRUSH) (COLOR_BTNFACE + 1);

    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        "head",                        // window caption
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
    static BOOL  bValidFile;
    static HWND  hwndList, hwndText;
    static RECT  rect;
    static char[] szFile;
    //~ HANDLE hFile;
    HDC hdc;
    int cxChar, cyChar;
    PAINTSTRUCT ps;
    wchar[MAX_PATH + 1] szBuffer;

    switch (message)
    {
        case WM_CREATE:
            cxChar = LOWORD(GetDialogBaseUnits());
            cyChar = HIWORD(GetDialogBaseUnits());

            rect.left = 56 * cxChar;
            rect.top  =  3 * cyChar;

            hwndList = CreateWindow("listbox", NULL,
                                    WS_CHILDWINDOW | WS_VISIBLE | LBS_STANDARD,
                                    cxChar, cyChar * 3,
                                    cxChar * 48 + GetSystemMetrics(SM_CXVSCROLL),
                                    cyChar * 24,
                                    hwnd, cast(HMENU)ID_LIST,
                                    cast(HINSTANCE)GetWindowLongPtr(hwnd, GWL_HINSTANCE),
                                    NULL);

            GetCurrentDirectory(MAX_PATH + 1, szBuffer.ptr);

            hwndText = CreateWindow("static", szBuffer.ptr,
                                    WS_CHILDWINDOW | WS_VISIBLE | SS_LEFT,
                                    cxChar, cyChar, cxChar * MAX_PATH, cyChar,
                                    hwnd, cast(HMENU)ID_TEXT,
                                    cast(HINSTANCE)GetWindowLongPtr(hwnd, GWL_HINSTANCE),
                                    NULL);

            OldList = cast(WNDPROC)SetWindowLongPtr(hwndList, GWL_WNDPROC,
                                                 cast(LPARAM)&ListProc);

            SendMessage(hwndList, LB_DIR, DIRATTR, cast(LPARAM)"*.*".toUTF16z);
            return 0;

        case WM_SIZE:
            rect.right  = LOWORD(lParam);
            rect.bottom = HIWORD(lParam);
            return 0;

        case WM_SETFOCUS:
            SetFocus(hwndList);
            return 0;

        case WM_COMMAND:

            if (LOWORD(wParam) == ID_LIST && HIWORD(wParam) == LBN_DBLCLK)
            {
                int i = SendMessage(hwndList, LB_GETCURSEL, 0, 0);
                if (i == LB_ERR)
                    break;

                SendMessage(hwndList, LB_GETTEXT, i, cast(LPARAM)szBuffer.ptr);
                auto filename = to!string(szBuffer[0..wcslen(szBuffer.ptr)]);

                if (filename == "[..]")
                {
                    bValidFile = false;
                    SetCurrentDirectory((getcwd() ~ r"\..\").toUTF16z);
                    SetWindowText(hwndText, getcwd.toUTF16z);
                    SendMessage(hwndList, LB_RESETCONTENT, 0, 0);
                    SendMessage(hwndList, LB_DIR, DIRATTR, cast(LPARAM)"*.*".toUTF16z);
                }
                else if (filename[0] == '[' && filename[$-1] == ']')
                {
                    bValidFile = false;
                    if (filename[1] == '-')
                    {
                        // drive
                        SetCurrentDirectory((filename[2 .. $-2].toUpper ~ r":\").toUTF16z);
                        SetWindowText(hwndText, getcwd.toUTF16z);
                        SendMessage(hwndList, LB_RESETCONTENT, 0, 0);
                        SendMessage(hwndList, LB_DIR, DIRATTR, cast(LPARAM)"*.*".toUTF16z);
                    }
                    else
                    {
                        // dir
                        SetCurrentDirectory((getcwd ~ r"\" ~ filename[1 .. $-1]).toUTF16z);
                        SetWindowText(hwndText, getcwd.toUTF16z);
                        SendMessage(hwndList, LB_RESETCONTENT, 0, 0);
                        SendMessage(hwndList, LB_DIR, DIRATTR, cast(LPARAM)"*.*".toUTF16z);
                    }
                }
                else if (filename.isFile)
                {
                    bValidFile = true;
                    szFile = std.path.buildPath(getcwd, filename).dup;
                    SetWindowText(hwndText, szFile.toUTF16z);
                }

                InvalidateRect(hwnd, NULL, TRUE);
            }

            return 0;

        case WM_PAINT:
            if (!bValidFile)
                break;

            auto hFile = to!string(szFile);

            char[] buffer;
            try
            {
                buffer = readText(hFile).dup;
            }
            catch (FileException exc)
            {
                break;
            }
            catch (UTFException exc)
            {
                break;
            }

            hdc = BeginPaint(hwnd, &ps);
            SelectObject(hdc, GetStockObject(SYSTEM_FIXED_FONT));
            SetTextColor(hdc, GetSysColor(COLOR_BTNTEXT));
            SetBkColor  (hdc, GetSysColor(COLOR_BTNFACE));

            DrawText(hdc, buffer.toUTF16z, buffer.count, &rect, DTFLAGS);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern (Windows)
LRESULT ListProc(HWND hwnd, UINT message,
                 WPARAM wParam, LPARAM lParam)
{
    if (message == WM_KEYDOWN && wParam == VK_RETURN)
        SendMessage(GetParent(hwnd), WM_COMMAND, MAKELONG(1, LBN_DBLCLK), cast(LPARAM)hwnd);

    return CallWindowProc(OldList, hwnd, message, wParam, lParam);
}


