/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module name;

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

enum ID_TIMER = 1;
enum TWOPI    =(2 * 3.14159);
enum ID_SMALLER =    1;     // button window unique id
enum ID_LARGER  =    2;     // same
enum BTN_WIDTH  =    "(8 * cxChar)";
enum BTN_HEIGHT =    "(4 * cyChar)";
int idFocus;
WNDPROC[3] OldScroll;
HINSTANCE hInst;
enum ID_EDIT = 1;

string appName = "PopPad1";

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
                        "edit",                        // window caption
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
    static HWND hwndEdit;

    switch (message)
    {
        case WM_CREATE:
            hwndEdit = CreateWindow("edit", NULL,
                                    WS_CHILD | WS_VISIBLE | WS_HSCROLL | WS_VSCROLL |
                                    WS_BORDER | ES_LEFT | ES_MULTILINE | ES_NOHIDESEL |
                                    ES_AUTOHSCROLL | ES_AUTOVSCROLL,
                                    0, 0, 0, 0, hwnd, cast(HMENU)ID_EDIT,
                                    (cast(LPCREATESTRUCT)lParam).hInstance, NULL);
            return 0;

        case WM_SETFOCUS:
            SetFocus(hwndEdit);
            return 0;

        case WM_SIZE:
            MoveWindow(hwndEdit, 0, 0, LOWORD(lParam), HIWORD(lParam), TRUE);
            return 0;

        case WM_COMMAND:
            if (LOWORD(wParam) == ID_EDIT)
                if (HIWORD(wParam) == EN_ERRSPACE ||
                    HIWORD(wParam) == EN_MAXTEXT)
                    MessageBox(hwnd, "Edit control out of space.",
                               appName.toUTF16z, MB_OK | MB_ICONSTOP);

            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}


