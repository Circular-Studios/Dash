/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module PopPad2;

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

import resource;

string appName = "PopPad2";
enum ID_TIMER = 1;
enum ID_EDIT  = 1;
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
    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon (hInstance, appName.toUTF16z);
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
                        "description",                 // window caption
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

auto AskConfirmation(HWND hwnd)
{
    return MessageBox(hwnd,  "Really want to close PopPad2?", appName.toUTF16z, MB_YESNO | MB_ICONQUESTION);
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HWND hwndEdit;
    int iSelect, iEnable;

    switch (message)
    {
        case WM_CREATE:
            hwndEdit = CreateWindow( "edit", NULL,
                                     WS_CHILD | WS_VISIBLE | WS_HSCROLL | WS_VSCROLL |
                                     WS_BORDER | ES_LEFT | ES_MULTILINE |
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

        case WM_INITMENUPOPUP:

            if (lParam == 1)
            {
                EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_UNDO,
                               SendMessage(hwndEdit, EM_CANUNDO, 0, 0) ?
                               MF_ENABLED : MF_GRAYED);

                EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_PASTE,
                               IsClipboardFormatAvailable(CF_TEXT) ?
                               MF_ENABLED : MF_GRAYED);

                iSelect = SendMessage(hwndEdit, EM_GETSEL, 0, 0);

                if (HIWORD(iSelect) == LOWORD(iSelect))
                    iEnable = MF_GRAYED;
                else
                    iEnable = MF_ENABLED;

                EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_CUT,   iEnable);
                EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_COPY,  iEnable);
                EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_CLEAR, iEnable);
                return 0;
            }

            break;

        case WM_COMMAND:

            if (lParam)
            {
                if (LOWORD(lParam) == ID_EDIT &&
                   (HIWORD(wParam) == EN_ERRSPACE ||
                    HIWORD(wParam) == EN_MAXTEXT))
                    MessageBox(hwnd, "Edit control out of space.", appName.toUTF16z, MB_OK | MB_ICONSTOP);

                return 0;
            }
            else
                switch (LOWORD(wParam))
                {
                    case IDM_FILE_NEW:
                    case IDM_FILE_OPEN:
                    case IDM_FILE_SAVE:
                    case IDM_FILE_SAVE_AS:
                    case IDM_FILE_PRINT:
                        MessageBeep(0);
                        return 0;

                    case IDM_APP_EXIT:
                        SendMessage(hwnd, WM_CLOSE, 0, 0);
                        return 0;

                    case IDM_EDIT_UNDO:
                        SendMessage(hwndEdit, WM_UNDO, 0, 0);
                        return 0;

                    case IDM_EDIT_CUT:
                        SendMessage(hwndEdit, WM_CUT, 0, 0);
                        return 0;

                    case IDM_EDIT_COPY:
                        SendMessage(hwndEdit, WM_COPY, 0, 0);
                        return 0;

                    case IDM_EDIT_PASTE:
                        SendMessage(hwndEdit, WM_PASTE, 0, 0);
                        return 0;

                    case IDM_EDIT_CLEAR:
                        SendMessage(hwndEdit, WM_CLEAR, 0, 0);
                        return 0;

                    case IDM_EDIT_SELECT_ALL:
                        SendMessage(hwndEdit, EM_SETSEL, 0, -1);
                        return 0;

                    case IDM_HELP_HELP:
                        MessageBox(hwnd, "Help not yet implemented!",
                                   appName.toUTF16z, MB_OK | MB_ICONEXCLAMATION);
                        return 0;

                    case IDM_APP_ABOUT:
                        MessageBox(hwnd, "POPPAD2 (c) Charles Petzold, 1998",
                                   appName.toUTF16z, MB_OK | MB_ICONINFORMATION);
                        return 0;

                    default:
                }

            break;

        case WM_CLOSE:

            if (IDYES == AskConfirmation(hwnd))
                DestroyWindow(hwnd);

            return 0;

        case WM_QUERYENDSESSION:

            if (IDYES == AskConfirmation(hwnd))
                return 1;
            else
                return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
