/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Multi1;

import core.memory;
import core.runtime;
import core.thread;
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

string appName     = "Multi1";
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

int cyChar;

int CheckBottom(HWND hwnd, int cyClient, int iLine)
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
extern (Windows)
LRESULT WndProc1(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int iNum, iLine, cyClient;
    HDC hdc;
    string szBuffer;

    switch (message)
    {
        case WM_SIZE:
            cyClient = HIWORD(lParam);
            return 0;

        case WM_TIMER:

            if (iNum < 0)
                iNum = 0;

            iLine = CheckBottom(hwnd, cyClient, iLine);
            hdc   = GetDC(hwnd);

            szBuffer = format("%s", iNum++);
            TextOut(hdc, 0, iLine * cyChar, szBuffer.toUTF16z, szBuffer.count);

            ReleaseDC(hwnd, hdc);
            iLine++;
            return 0;
            
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

// ------------------------------------------------------
// Window 2: Display increasing sequence of prime numbers
// ------------------------------------------------------
extern (Windows)
LRESULT WndProc2(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int iNum = 1, iLine, cyClient;
    HDC hdc;
    int i, iSqrt;
    string szBuffer;

    switch (message)
    {
        case WM_SIZE:
            cyClient = HIWORD(lParam);
            return 0;

        case WM_TIMER:

            do
            {
                if (++iNum < 0)
                    iNum = 0;

                iSqrt = cast(int)sqrt(cast(float)iNum);

                for (i = 2; i <= iSqrt; i++)
                    if (iNum % i == 0)
                        break;

            }
            while (i <= iSqrt);

            iLine = CheckBottom(hwnd, cyClient, iLine);
            hdc   = GetDC(hwnd);

            szBuffer = format("%s", iNum);
            TextOut(hdc, 0, iLine * cyChar, szBuffer.toUTF16z, szBuffer.count);

            ReleaseDC(hwnd, hdc);
            iLine++;
            return 0;
            
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

// ----------------------------------------------------------
// Window 3: Display increasing sequence of Fibonacci numbers
// ----------------------------------------------------------
extern (Windows)
LRESULT WndProc3(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int iNum = 0, iNext = 1, iLine, cyClient;
    HDC hdc;
    int iTemp;
    string szBuffer;

    switch (message)
    {
        case WM_SIZE:
            cyClient = HIWORD(lParam);
            return 0;

        case WM_TIMER:

            if (iNum < 0)
            {
                iNum  = 0;
                iNext = 1;
            }

            iLine = CheckBottom(hwnd, cyClient, iLine);
            hdc   = GetDC(hwnd);

            szBuffer = format("%s", iNum);
            TextOut(hdc, 0, iLine * cyChar, szBuffer.toUTF16z, szBuffer.count);

            ReleaseDC(hwnd, hdc);
            iTemp  = iNum;
            iNum   = iNext;
            iNext += iTemp;
            iLine++;
            return 0;
            
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

// -----------------------------------------
// Window 4: Display circles of random radii
// -----------------------------------------
extern (Windows)
LRESULT WndProc4(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int cxClient, cyClient;
    HDC hdc;
    int iDiameter;

    switch (message)
    {
        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_TIMER:
            InvalidateRect(hwnd, NULL, TRUE);
            UpdateWindow(hwnd);

            iDiameter = uniform(0, (max(1, min(cxClient, cyClient))));
            hdc       = GetDC(hwnd);

            Ellipse(hdc, (cxClient - iDiameter) / 2,
                    (cyClient - iDiameter) / 2,
                    (cxClient + iDiameter) / 2,
                    (cyClient + iDiameter) / 2);

            ReleaseDC(hwnd, hdc);
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
    static HWND hwndChild[4];
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

            cyChar = HIWORD(GetDialogBaseUnits());
            SetTimer(hwnd, 1, 10, NULL);
            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);

            for (i = 0; i < 4; i++)
                MoveWindow(hwndChild[i], (i % 2) * cxClient / 2,
                           (i > 1) * cyClient / 2,
                           cxClient / 2, cyClient / 2, TRUE);

            return 0;

        case WM_TIMER:

            for (i = 0; i < 4; i++)
                SendMessage(hwndChild[i], WM_TIMER, wParam, lParam);

            return 0;

        case WM_CHAR:

            if (wParam == '\x1B')
                DestroyWindow(hwnd);

            return 0;

        case WM_DESTROY:
            KillTimer(hwnd, 1);
            PostQuitMessage(0);
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
