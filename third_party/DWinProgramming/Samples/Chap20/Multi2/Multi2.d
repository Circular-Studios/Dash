/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Multi2;

import core.memory;
import core.runtime;
import core.thread;
import std.concurrency;
import std.conv;
import std.math;
import std.random;
import std.range;
import std.string;
import std.utf : count, toUTFz;

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

string appName     = "Multi2";
string description = "Multitasking Demo";
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

struct PARAMS
{
    HWND hwnd;
    int cxClient;
    int cyClient;
    int cyChar;
    BOOL bKill;
}

/+
 + In the original C example an address of a static variable from one thread is sent
 + to a new thread and then this is used for messaging (WTH?).
 + Enjoy: http://msdn.microsoft.com/en-us/library/kdzttdcb%28v=vs.80%29.aspx
 +/
__gshared PARAMS params1;
__gshared PARAMS params2;
__gshared PARAMS params3;
__gshared PARAMS params4;

int CheckBottom(HWND hwnd, int cyClient, int cyChar, int iLine)
{
    if (iLine * cyChar + cyChar > cyClient)
    {
        InvalidateRect(hwnd, NULL, TRUE);
        UpdateWindow(hwnd);
        iLine = 0;
    }

    return iLine;
}

// ------------------------------------------------
// Window 1: Display increasing sequence of numbers
// ------------------------------------------------
void Thread1()
{
    HDC hdc;
    int iNum = 0, iLine = 0;
    string szBuffer;

    while (!params1.bKill)
    {
        if (iNum < 0)
            iNum = 0;

        iLine = CheckBottom(params1.hwnd, params1.cyClient,
                            params1.cyChar, iLine);

        hdc = GetDC(params1.hwnd);

        szBuffer = format("%s", iNum++);
        TextOut(hdc, 0, iLine * params1.cyChar, szBuffer.toUTF16z, szBuffer.count);

        ReleaseDC(params1.hwnd, hdc);
        iLine++;
    }
}

extern (Windows)
LRESULT WndProc1(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_CREATE:
            params1.hwnd   = hwnd;
            params1.cyChar = HIWORD(GetDialogBaseUnits());
            spawn(&Thread1);
            return 0;

        case WM_SIZE:
            params1.cyClient = HIWORD(lParam);
            return 0;

        case WM_DESTROY:
            params1.bKill = TRUE;
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

// ------------------------------------------------------
// Window 2: Display increasing sequence of prime numbers
// ------------------------------------------------------
void Thread2()
{
    HDC hdc;
    int iNum = 1, iLine = 0, i, iSqrt;
    string szBuffer;

    while (!params2.bKill)
    {
        do
        {
            if (++iNum < 0)
                iNum = 0;

            iSqrt = cast(int)sqrt(cast(float)iNum);

            for (i = 2; i <= iSqrt; i++)
                if (iNum % i == 0)
                    break;

        } while (i <= iSqrt);

        iLine = CheckBottom(params2.hwnd, params2.cyClient,
                            params2.cyChar, iLine);

        hdc = GetDC(params2.hwnd);

        szBuffer = format("%s", iNum);
        TextOut(hdc, 0, iLine * params2.cyChar, szBuffer.toUTF16z, szBuffer.count);

        ReleaseDC(params2.hwnd, hdc);
        iLine++;
    }
}

extern (Windows)
LRESULT WndProc2(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_CREATE:
            params2.hwnd   = hwnd;
            params2.cyChar = HIWORD(GetDialogBaseUnits());
            spawn(&Thread2);
            return 0;

        case WM_SIZE:
            params2.cyClient = HIWORD(lParam);
            return 0;

        case WM_DESTROY:
            params2.bKill = TRUE;
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

// Window 3: Display increasing sequence of Fibonacci numbers
// ----------------------------------------------------------
void Thread3()
{
    HDC hdc;
    int iNum = 0, iNext = 1, iLine = 0, iTemp;
    string szBuffer;

    while (!params3.bKill)
    {
        if (iNum < 0)
        {
            iNum  = 0;
            iNext = 1;
        }

        iLine = CheckBottom(params3.hwnd, params3.cyClient,
                            params3.cyChar, iLine);

        hdc = GetDC(params3.hwnd);

        szBuffer = format("%s", iNum);
        TextOut(hdc, 0, iLine * params3.cyChar, szBuffer.toUTF16z, szBuffer.count);        

        ReleaseDC(params3.hwnd, hdc);
        iTemp  = iNum;
        iNum   = iNext;
        iNext += iTemp;
        iLine++;
    }
}

extern (Windows)
LRESULT WndProc3(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_CREATE:
            params3.hwnd   = hwnd;
            params3.cyChar = HIWORD(GetDialogBaseUnits());
            spawn(&Thread3);
            return 0;

        case WM_SIZE:
            params3.cyClient = HIWORD(lParam);
            return 0;

        case WM_DESTROY:
            params3.bKill = TRUE;
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

// -----------------------------------------
// Window 4: Display circles of random radii
// -----------------------------------------
void Thread4()
{
    HDC hdc;
    int iDiameter;

    while (!params4.bKill)
    {
        InvalidateRect(params4.hwnd, NULL, TRUE);
        UpdateWindow(params4.hwnd);

        iDiameter = uniform(0, (max(1, min(params4.cxClient, params4.cyClient))));

        hdc = GetDC(params4.hwnd);

        Ellipse(hdc, (params4.cxClient - iDiameter) / 2,
                (params4.cyClient - iDiameter) / 2,
                (params4.cxClient + iDiameter) / 2,
                (params4.cyClient + iDiameter) / 2);

        ReleaseDC(params4.hwnd, hdc);
    }
}

extern (Windows)
LRESULT WndProc4(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_CREATE:
            params4.hwnd   = hwnd;
            params4.cyChar = HIWORD(GetDialogBaseUnits());
            spawn(&Thread4);
            return 0;

        case WM_SIZE:
            params4.cxClient = LOWORD(lParam);
            params4.cyClient = HIWORD(lParam);
            return 0;

        case WM_DESTROY:
            params4.bKill = TRUE;
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

// -----------------------------------
// Main window to create child windows
// -----------------------------------
extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HWND[4] hwndChild;
    static string[] szChildClass = ["Child1", "Child2", "Child3", "Child4"];
    static WNDPROC[] ChildProc = [&WndProc1, &WndProc2, &WndProc3, &WndProc4];
    HINSTANCE hInstance;
    int i, cxClient, cyClient;
    WNDCLASS wndclass;

    switch (message)
    {
        case WM_CREATE:
            hInstance = cast(HINSTANCE)GetWindowLongPtr(hwnd, GWL_HINSTANCE);

            wndclass.style         = CS_HREDRAW | CS_VREDRAW;
            wndclass.cbClsExtra    = 0;
            wndclass.cbWndExtra    = 0;
            wndclass.hInstance     = hInstance;
            wndclass.hIcon         = NULL;
            wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
            wndclass.hbrBackground = cast(HBRUSH)GetStockObject(WHITE_BRUSH);
            wndclass.lpszMenuName  = NULL;

            for (i = 0; i < 4; i++)
            {
                wndclass.lpfnWndProc   = ChildProc[i];
                wndclass.lpszClassName = szChildClass[i].toUTF16z;

                RegisterClass(&wndclass);

                hwndChild[i] = CreateWindow(szChildClass[i].toUTF16z, NULL,
                                            WS_CHILDWINDOW | WS_BORDER | WS_VISIBLE,
                                            0, 0, 0, 0,
                                            hwnd, cast(HMENU)i, hInstance, NULL);
            }

            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);

            for (i = 0; i < 4; i++)
                MoveWindow(hwndChild[i], (i % 2) * cxClient / 2,
                           (i > 1) * cyClient / 2,
                           cxClient / 2, cyClient / 2, TRUE);

            return 0;

        case WM_CHAR:

            if (wParam == '\x1B')
                DestroyWindow(hwnd);

            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
