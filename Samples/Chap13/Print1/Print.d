/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Print;

import core.memory;
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
pragma(lib, "winspool.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.winspool;

string appName     = "Print1";
string description = "Print Program 1";
enum ID_TIMER = 1;
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

void PageGDICalls(HDC hdcPrn, int cxPage, int cyPage)
{
    string szTextStr = "Hello, Printer!";

    Rectangle(hdcPrn, 0, 0, cxPage, cyPage);

    MoveToEx(hdcPrn, 0, 0, NULL);
    LineTo(hdcPrn, cxPage, cyPage);
    MoveToEx(hdcPrn, cxPage, 0, NULL);
    LineTo(hdcPrn, 0, cyPage);

    SaveDC(hdcPrn);

    SetMapMode(hdcPrn, MM_ISOTROPIC);
    SetWindowExtEx(hdcPrn, 1000, 1000, NULL);
    SetViewportExtEx(hdcPrn, cxPage / 2, -cyPage / 2, NULL);
    SetViewportOrgEx(hdcPrn, cxPage / 2,  cyPage / 2, NULL);

    Ellipse(hdcPrn, -500, 500, 500, -500);

    SetTextAlign(hdcPrn, TA_BASELINE | TA_CENTER);
    TextOut(hdcPrn, 0, 0, szTextStr.toUTF16z, szTextStr.count);

    RestoreDC(hdcPrn, -1);
}

extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int cxClient, cyClient;
    HDC hdc;
    HMENU hMenu;
    PAINTSTRUCT ps;

    switch (message)
    {
        case WM_CREATE:
            hMenu = GetSystemMenu(hwnd, false);
            AppendMenu(hMenu, MF_SEPARATOR, 0, NULL);
            AppendMenu(hMenu, 0, 1, "&Print");
            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_SYSCOMMAND:

            if (wParam == 1)
            {
                if (!PrintMyPage(hwnd))
                    MessageBox(hwnd, "Could not print page!", 
                               appName.toUTF16z, MB_OK | MB_ICONEXCLAMATION);

                return 0;
            }

            break;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            PageGDICalls(hdc, cxClient, cyClient);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

bool PrintMyPage(HWND hwnd)
{
    static DOCINFO di = DOCINFO(DOCINFO.sizeof, "Print1: Printing");
    bool bSuccess     = true;  // signaling success in advance is a pretty bad idea
    HDC  hdcPrn;
    int  xPage, yPage;

    hdcPrn = GetPrinterDC();
    if (hdcPrn is null)
        return false;
    
    scope(exit) DeleteDC(hdcPrn);

    xPage = GetDeviceCaps(hdcPrn, HORZRES);
    yPage = GetDeviceCaps(hdcPrn, VERTRES);

    if (StartDoc(hdcPrn, &di) > 0)
    {
        if (StartPage(hdcPrn) > 0)
        {
            PageGDICalls(hdcPrn, xPage, yPage);

            if (EndPage(hdcPrn) > 0)
                EndDoc(hdcPrn);
            else
                bSuccess = false;
        }
    }
    else
        bSuccess = false;
    
    return bSuccess;
}

HDC GetPrinterDC()
{
    DWORD dwNeeded, dwReturned;
    HDC hdc;
    PRINTER_INFO_4* pinfo4;
    PRINTER_INFO_5* pinfo5;

    if (GetVersion() & 0x80000000)           // Windows 98
    {
        EnumPrinters(PRINTER_ENUM_DEFAULT, NULL, 5, NULL, 0, &dwNeeded, &dwReturned);

        pinfo5 = cast(typeof(pinfo5))GC.malloc(dwNeeded);
        EnumPrinters(PRINTER_ENUM_DEFAULT, NULL, 5, cast(PBYTE)pinfo5, dwNeeded, &dwNeeded, &dwReturned);
        hdc = CreateDC(NULL, pinfo5.pPrinterName, NULL, NULL);
        GC.free(pinfo5);
    }
    else                                     // Windows NT
    {
        EnumPrinters(PRINTER_ENUM_LOCAL, NULL, 4, NULL, 0, &dwNeeded, &dwReturned);
        pinfo4 = cast(typeof(pinfo4))GC.malloc(dwNeeded);
        EnumPrinters(PRINTER_ENUM_LOCAL, NULL, 4, cast(PBYTE)pinfo4, dwNeeded, &dwNeeded, &dwReturned);
        hdc = CreateDC(NULL, pinfo4.pPrinterName, NULL, NULL);
        GC.free(pinfo4);
    }

    return hdc;
}
