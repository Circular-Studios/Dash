module drop_target.main;

/**
    The project implements IDropTarget and receives a Drag & Drop operation.
    It uses an Edit control and allows dragging text into this application
    from another application.
 */

import core.runtime;
import core.stdc.stdlib;
import core.stdc.string;

import std.conv;
import std.exception;
import std.stdio;
import std.string;

pragma(lib, "comctl32.lib");
pragma(lib, "ole32.lib");
pragma(lib, "gdi32.lib");

import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;
import win32.wingdi;
import win32.winuser;
import win32.wtypes;

import utils.com;

import drop_target.target;
import drop_target.resource;

extern (Windows)
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    int result;

    void exceptionHandler(Throwable e)
    {
        throw e;
    }

    try
    {
        Runtime.initialize(&exceptionHandler);
        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, iCmdShow);
        Runtime.terminate(&exceptionHandler);
    }
    catch (Throwable o)
    {
        MessageBox(null, o.toString().toStringz, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

enum APPNAME = "IDropTarget";

HWND hwndMain;
HWND hwndEdit;
HINSTANCE hInstance;
char[200] szTextBuffer;

int myWinMain(HINSTANCE hInst, HINSTANCE hPrev, LPSTR lpCmdLine, int nShowCmd)
{
    enforce(OleInitialize(null) == S_OK);
    scope (exit)
        OleUninitialize();

    MSG msg;
    hInstance = hInst;

    InitMainWnd();
    CreateMainWnd();

    while (GetMessage(&msg, null, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}

void InitMainWnd()
{
    WNDCLASSEX wc;

    wc.lpfnWndProc   = &WndProc;
    wc.lpszClassName = APPNAME;
    wc.lpszMenuName  = MAKEINTRESOURCE(IDR_MENU1);
    wc.hInstance     = hInstance;

    RegisterClassEx(&wc);
}

void CreateMainWnd()
{
    hwndMain = CreateWindowEx(0, APPNAME, APPNAME,
                              WS_VISIBLE | WS_OVERLAPPEDWINDOW,
                              CW_USEDEFAULT, CW_USEDEFAULT, 512, 200, null, null,
                              hInstance, null);
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    static IDropTarget pDropTarget;

    switch (msg)
    {
        case WM_CREATE:

            hwndEdit = CreateWindowEx(WS_EX_CLIENTEDGE, "EDIT", "",
                                      WS_CHILD | WS_VISIBLE | ES_MULTILINE | ES_WANTRETURN | WS_VSCROLL,
                                      0, 0, 0, 0, hwnd, null, hInstance, null);

            SendMessage(hwndEdit, WM_SETFONT, cast(WPARAM)GetStockObject(ANSI_FIXED_FONT), 0);

            // make the Edit control into a DropTarget
            RegisterDropWindow(hwndEdit, &pDropTarget);

            SetFocus(hwndEdit);

            return TRUE;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_FILE_EXIT:
                    CloseWindow(hwnd);
                    return 0;

                case IDM_FILE_ABOUT:
                    MessageBox(hwnd, "IDropTarget Test Application\r\n\r\n"
                               "Copyright(c) 2004 by Catch22 Productions\t\r\n"
                               "Written by J Brown.\r\n\r\n"
                               "Homepage at www.catch22.net", APPNAME, MB_ICONINFORMATION);
                    return 0;

                default:
            }

            break;

        case WM_CLOSE:

            // shut program down
            UnregisterDropWindow(hwndEdit, pDropTarget);
            DestroyWindow(hwnd);
            PostQuitMessage(0);
            return 0;

        case WM_SIZE:

            // resize editbox to fit in main window
            MoveWindow(hwndEdit, 0, 0, LOWORD(lParam), HIWORD(lParam), TRUE);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, msg, wParam, lParam);
}
