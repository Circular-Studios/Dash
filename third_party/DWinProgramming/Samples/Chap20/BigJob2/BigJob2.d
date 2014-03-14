/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module BigJob2;

/+
 + Warning: This app keeps running in the background after exit.
 + Probably something to do with WaitForSingleObject.
 + 
 +/

import core.memory;
import core.runtime;
import core.thread;
import std.concurrency;
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
pragma(lib, "winmm.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.commdlg;
import win32.mmsystem;

alias win32.winuser.MessageBox MessageBox;

string appName     = "BigJob2";
string description = "Multithreading Demo";
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

enum REP = 10_000_000;
enum STATUS_READY    = 0;
enum STATUS_WORKING  = 1;
enum STATUS_DONE     = 2;
enum WM_CALC_DONE    = (WM_USER + 0);
enum WM_CALC_ABORTED = (WM_USER + 1);

struct PARAMS
{
    HWND hwnd;
    HANDLE hEvent;
    BOOL bContinue;
}

// used to be volatile
__gshared PARAMS params;

void ThreadFunc()
{
    double A = 1.0;
    INT  i;
    LONG lTime;

    while (true)
    {
        WaitForSingleObject(params.hEvent, INFINITE);
    
        lTime = GetCurrentTime();

        for (i = 0; i < REP && params.bContinue; i++)
            A = tan(atan(exp(log(sqrt(A * A))))) + 1.0;

        if (i == REP)
        {
            lTime = GetCurrentTime() - lTime;
            PostMessage(params.hwnd, WM_CALC_DONE, 0, lTime);
        }
        else
        {
            PostMessage(params.hwnd, WM_CALC_ABORTED, 0, 0);
        }
    }
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HANDLE hEvent;
    static INT  iStatus;
    static LONG lTime;
    static string[] szMessage = ["Ready (left mouse button begins)",
                                 "Working (right mouse button ends)",
                                 "%s repetitions in %s msec"];
    HDC hdc;
    PAINTSTRUCT ps;
    RECT  rect;
    string szBuffer;

    switch (message)
    {
        case WM_CREATE:
            hEvent = CreateEvent (NULL, FALSE, FALSE, NULL);

            params.hwnd = hwnd;
            params.hEvent = hEvent;
            params.bContinue = FALSE;

            spawn(&ThreadFunc);

            return 0;        
        
        case WM_LBUTTONDOWN:
            if (iStatus == STATUS_WORKING)
            {
                MessageBeep(0);
                return 0;
            }

            iStatus = STATUS_WORKING;

            params.bContinue = TRUE;

            SetEvent(params.hEvent);

            InvalidateRect(hwnd, NULL, TRUE);
            return 0;

        case WM_RBUTTONDOWN:
            params.bContinue = FALSE;
            return 0;

        case WM_CALC_DONE:
            lTime   = lParam;
            iStatus = STATUS_DONE;
            InvalidateRect(hwnd, NULL, TRUE);
            return 0;

        case WM_CALC_ABORTED:
            iStatus = STATUS_READY;
            InvalidateRect(hwnd, NULL, TRUE);
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            GetClientRect(hwnd, &rect);

            szBuffer = format(szMessage[iStatus], REP, lTime);
            DrawText(hdc, szBuffer.toUTF16z, -1, &rect, DT_SINGLELINE | DT_CENTER | DT_VCENTER);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            ExitProcess(0);
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
