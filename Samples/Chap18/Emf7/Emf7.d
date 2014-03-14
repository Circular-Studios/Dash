/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Emf7;

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

string appName     = "Emf7";
string description = "Enhanced Metafile #7";
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
int EnhMetaFileProc(HDC hdc, HANDLETABLE* pHandleTable,
                    const ENHMETARECORD* pEmfRecord,
                    int iHandles, LPARAM pData)
{
    HBRUSH hBrush;
    HPEN hPen;
    LOGBRUSH lb;

    if (pEmfRecord.iType != EMR_HEADER && pEmfRecord.iType != EMR_EOF)

        PlayEnhMetaFileRecord(hdc, pHandleTable, pEmfRecord, iHandles);

    if (pEmfRecord.iType == EMR_RECTANGLE)
    {
        hBrush = SelectObject(hdc, GetStockObject(NULL_BRUSH));

        lb.lbStyle = BS_SOLID;
        lb.lbColor = RGB(0, 255, 0);
        lb.lbHatch = 0;

        hPen = SelectObject(hdc,
                            ExtCreatePen(PS_SOLID | PS_GEOMETRIC, 5, &lb, 0, NULL));

        Ellipse(hdc, 100, 100, 200, 200);

        DeleteObject(SelectObject(hdc, hPen));
        SelectObject(hdc, hBrush);
    }

    return TRUE;
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    ENHMETAHEADER emh;
    HDC hdc, hdcEMF;
    HENHMETAFILE hemfOld, hemf;
    PAINTSTRUCT  ps;
    RECT rect;

    switch (message)
    {
        case WM_CREATE:

            // Retrieve existing metafile and header

            hemfOld = GetEnhMetaFile(r"..\emf3\emf3.emf");

            GetEnhMetaFileHeader(hemfOld, ENHMETAHEADER.sizeof, &emh);

            // Create a new metafile DC

            hdcEMF = CreateEnhMetaFile(NULL, "emf7.emf", NULL,
                                       "EMF7\0EMF Demo #7\0");

            // Enumerate the existing metafile

            // @BUG@ WindowsAPI callbacks are not defined properly:
            //     alias int function(HANDLE, HANDLETABLE*, const(ENHMETARECORD)*, int, int)
            //
            // should be:
            //     alias extern(Windows) int function(HANDLE hdc, HANDLETABLE* pHandleTable, ENHMETARECORD* pEmfRecord, int iHandles, int pData)            
            EnumEnhMetaFile(hdcEMF, hemfOld, cast(int function(HANDLE, HANDLETABLE*, const(ENHMETARECORD)*, int, int))&EnhMetaFileProc, NULL,
                            cast(RECT*)&emh.rclBounds);

            // Clean up

            hemf = CloseEnhMetaFile(hdcEMF);

            DeleteEnhMetaFile(hemfOld);
            DeleteEnhMetaFile(hemf);
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            GetClientRect(hwnd, &rect);

            rect.left   =     rect.right / 4;
            rect.right  = 3 * rect.right / 4;
            rect.top    =     rect.bottom / 4;
            rect.bottom = 3 * rect.bottom / 4;

            hemf = GetEnhMetaFile("emf7.emf");

            PlayEnhMetaFile(hdc, hemf, &rect);
            DeleteEnhMetaFile(hemf);
            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
