/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module MDIDemo;

import core.memory;
import core.runtime;
import core.thread;
import core.stdc.config;
import std.algorithm : min, max;
import std.conv;
import std.math;
import std.random;
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

string appName     = "MDIDemo";
string description = "MDI Demonstration";
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
    HACCEL hAccel;
    HWND hwndFrame, hwndClient;
    MSG  msg;
    WNDCLASS wndclass;

    hinst = hInstance;

    // Register the frame window class
    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &FrameWndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH)(COLOR_APPWORKSPACE + 1);
    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = szFrameClass.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!",
                   appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    // Register the Hello child window class

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &HelloWndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = HANDLE.sizeof;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH)GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = szHelloClass.toUTF16z;

    RegisterClass(&wndclass);

    // Register the Rect child window class

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &RectWndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = HANDLE.sizeof;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH)GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = szRectClass.toUTF16z;

    RegisterClass(&wndclass);

    // Obtain handles to three possible menus & submenus

    hMenuInit  = LoadMenu(hInstance, "MdiMenuInit");
    hMenuHello = LoadMenu(hInstance, "MdiMenuHello");
    hMenuRect  = LoadMenu(hInstance, "MdiMenuRect");

    hMenuInitWindow  = GetSubMenu(hMenuInit,   INIT_MENU_POS);
    hMenuHelloWindow = GetSubMenu(hMenuHello, HELLO_MENU_POS);
    hMenuRectWindow  = GetSubMenu(hMenuRect,   RECT_MENU_POS);

    // Load accelerator table

    hAccel = LoadAccelerators(hInstance, appName.toUTF16z);

    // Create the frame window

    hwndFrame = CreateWindow(szFrameClass.toUTF16z, "MDI Demonstration",
                             WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
                             CW_USEDEFAULT, CW_USEDEFAULT,
                             CW_USEDEFAULT, CW_USEDEFAULT,
                             NULL, hMenuInit, hInstance, NULL);

    hwndClient = GetWindow(hwndFrame, GW_CHILD);

    ShowWindow(hwndFrame, iCmdShow);
    UpdateWindow(hwndFrame);

    // Enter the modified message loop
    while (GetMessage(&msg, NULL, 0, 0))
    {
        if (!TranslateMDISysAccel(hwndClient, &msg) &&
            !TranslateAccelerator(hwndFrame, hAccel, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    // Clean up by deleting unattached menus
    DestroyMenu(hMenuHello);
    DestroyMenu(hMenuRect);

    return msg.wParam;
}

enum INIT_MENU_POS  = 0;
enum HELLO_MENU_POS = 2;
enum RECT_MENU_POS  = 1;

enum IDM_FIRSTCHILD = 50000;

// structure for storing data unique to each Hello child window
struct HELLODATA
{
    UINT iColor;
    COLORREF clrText;
}

alias HELLODATA* PHELLODATA;

// structure for storing data unique to each Rect child window
struct RECTDATA
{
    short cxClient;
    short cyClient;
}
alias RECTDATA* PRECTDATA;

string szFrameClass = "MdiFrame";
string szHelloClass = "MdiHelloChild";
string szRectClass  = "MdiRectChild";
HMENU  hMenuInit, hMenuHello, hMenuRect;
HMENU  hMenuInitWindow, hMenuHelloWindow, hMenuRectWindow;

extern (Windows)
LRESULT FrameWndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HWND hwndClient;
    CLIENTCREATESTRUCT clientcreate;
    HWND hwndChild;
    MDICREATESTRUCT mdicreate;

    switch (message)
    {
        case WM_CREATE:        // Create the client window

            clientcreate.hWindowMenu  = hMenuInitWindow;
            clientcreate.idFirstChild = IDM_FIRSTCHILD;

            hwndClient = CreateWindow("MDICLIENT", NULL,
                                      WS_CHILD | WS_CLIPCHILDREN | WS_VISIBLE,
                                      0, 0, 0, 0, hwnd, cast(HMENU) 1, hinst,
                                      cast(PSTR)&clientcreate);
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_FILE_NEWHELLO: // Create a Hello child window

                    mdicreate.szClass = szHelloClass.toUTF16z;
                    mdicreate.szTitle = "Hello";
                    mdicreate.hOwner  = hinst;
                    mdicreate.x       = CW_USEDEFAULT;
                    mdicreate.y       = CW_USEDEFAULT;
                    mdicreate.cx      = CW_USEDEFAULT;
                    mdicreate.cy      = CW_USEDEFAULT;
                    mdicreate.style   = 0;
                    mdicreate.lParam  = 0;

                    hwndChild = cast(HWND)SendMessage(hwndClient,
                                                  WM_MDICREATE, 0,
                                                  cast(LPARAM)cast(LPMDICREATESTRUCT)&mdicreate);
                    return 0;

                case IDM_FILE_NEWRECT:  // Create a Rect child window

                    mdicreate.szClass = szRectClass.toUTF16z;
                    mdicreate.szTitle = "Rectangles";
                    mdicreate.hOwner  = hinst;
                    mdicreate.x       = CW_USEDEFAULT;
                    mdicreate.y       = CW_USEDEFAULT;
                    mdicreate.cx      = CW_USEDEFAULT;
                    mdicreate.cy      = CW_USEDEFAULT;
                    mdicreate.style   = 0;
                    mdicreate.lParam  = 0;

                    hwndChild = cast(HWND)SendMessage(hwndClient,
                                                  WM_MDICREATE, 0,
                                                  cast(LPARAM)cast(LPMDICREATESTRUCT)&mdicreate);
                    return 0;

                case IDM_FILE_CLOSE:    // Close the active window

                    hwndChild = cast(HWND)SendMessage(hwndClient,
                                                  WM_MDIGETACTIVE, 0, 0);

                    if (SendMessage(hwndChild, WM_QUERYENDSESSION, 0, 0))
                        SendMessage(hwndClient, WM_MDIDESTROY,
                                    cast(WPARAM)hwndChild, 0);

                    return 0;

                case IDM_APP_EXIT:      // Exit the program

                    SendMessage(hwnd, WM_CLOSE, 0, 0);
                    return 0;

                // messages for arranging windows

                case IDM_WINDOW_TILE:
                    SendMessage(hwndClient, WM_MDITILE, 0, 0);
                    return 0;

                case IDM_WINDOW_CASCADE:
                    SendMessage(hwndClient, WM_MDICASCADE, 0, 0);
                    return 0;

                case IDM_WINDOW_ARRANGE:
                    SendMessage(hwndClient, WM_MDIICONARRANGE, 0, 0);
                    return 0;

                case IDM_WINDOW_CLOSEALL: // Attempt to close all children

                    EnumChildWindows(hwndClient, &CloseEnumProc, 0);
                    return 0;

                default:       // Pass to active child...

                    hwndChild = cast(HWND)SendMessage(hwndClient,
                                                  WM_MDIGETACTIVE, 0, 0);

                    if (IsWindow(hwndChild))
                        SendMessage(hwndChild, WM_COMMAND, wParam, lParam);

                    break;    // ...and then to DefFrameProc
            }

            break;

        case WM_QUERYENDSESSION:
        case WM_CLOSE:                   // Attempt to close all children

            SendMessage(hwnd, WM_COMMAND, IDM_WINDOW_CLOSEALL, 0);

            if (NULL != GetWindow(hwndClient, GW_CHILD))
                return 0;

            break;  // i.e., call DefFrameProc

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    // Pass unprocessed messages to DefFrameProc (not DefWindowProc)
    return DefFrameProc(hwnd, hwndClient, message, wParam, lParam);
}

extern (Windows)
BOOL CloseEnumProc(HWND hwnd, LPARAM lParam)
{
    if (GetWindow(hwnd, GW_OWNER))           // Check for icon title
        return TRUE;

    SendMessage(GetParent(hwnd), WM_MDIRESTORE, cast(WPARAM)hwnd, 0);

    if (!SendMessage(hwnd, WM_QUERYENDSESSION, 0, 0))
        return TRUE;

    SendMessage(GetParent(hwnd), WM_MDIDESTROY, cast(WPARAM)hwnd, 0);
    return TRUE;
}

extern (Windows)
LRESULT HelloWndProc(HWND hwnd, UINT message,
                     WPARAM wParam, LPARAM lParam)
{
    auto clrTextArray = [RGB(0,   0, 0), RGB(255, 0,   0),
                         RGB(0, 255, 0), RGB(  0, 0, 255),
                         RGB(255, 255, 255)];
    static HWND hwndClient, hwndFrame;
    HDC hdc;
    HMENU hMenu;
    PHELLODATA  pHelloData;
    PAINTSTRUCT ps;
    RECT rect;

    switch (message)
    {
        case WM_CREATE:

            // Allocate memory for window private data

            pHelloData = cast(PHELLODATA)HeapAlloc(GetProcessHeap(),
                                               HEAP_ZERO_MEMORY, HELLODATA.sizeof);

            pHelloData.iColor  = IDM_COLOR_BLACK;
            pHelloData.clrText = RGB(0, 0, 0);
            SetWindowLongPtr(hwnd, 0, cast(c_long)pHelloData);

            // Save some window handles

            hwndClient = GetParent(hwnd);
            hwndFrame  = GetParent(hwndClient);
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_COLOR_BLACK:
                case IDM_COLOR_RED:
                case IDM_COLOR_GREEN:
                case IDM_COLOR_BLUE:
                case IDM_COLOR_WHITE:

                    // Change the text color

                    pHelloData = cast(PHELLODATA)GetWindowLongPtr(hwnd, 0);

                    hMenu = GetMenu(hwndFrame);

                    CheckMenuItem(hMenu, pHelloData.iColor, MF_UNCHECKED);
                    pHelloData.iColor = wParam;
                    CheckMenuItem(hMenu, pHelloData.iColor, MF_CHECKED);

                    pHelloData.clrText = clrTextArray[wParam - IDM_COLOR_BLACK];

                    InvalidateRect(hwnd, NULL, FALSE);
                    break;

                default:
            }

            return 0;

        case WM_PAINT:

            // Paint the window

            hdc = BeginPaint(hwnd, &ps);

            pHelloData = cast(PHELLODATA)GetWindowLongPtr(hwnd, 0);
            SetTextColor(hdc, pHelloData.clrText);

            GetClientRect(hwnd, &rect);

            DrawText(hdc, "Hello, World!", -1, &rect,
                 DT_SINGLELINE | DT_CENTER | DT_VCENTER);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_MDIACTIVATE:

            // Set the Hello menu if gaining focus

            if (lParam == cast(LPARAM)hwnd)
                SendMessage(hwndClient, WM_MDISETMENU,
                            cast(WPARAM)hMenuHello, cast(LPARAM)hMenuHelloWindow);

            // Check or uncheck menu item

            pHelloData = cast(PHELLODATA)GetWindowLongPtr(hwnd, 0);
            CheckMenuItem(hMenuHello, pHelloData.iColor,
                          (lParam == cast(LPARAM)hwnd) ? MF_CHECKED : MF_UNCHECKED);

            // Set the Init menu if losing focus

            if (lParam != cast(LPARAM)hwnd)
                SendMessage(hwndClient, WM_MDISETMENU, cast(WPARAM)hMenuInit,
                            cast(LPARAM)hMenuInitWindow);

            DrawMenuBar(hwndFrame);
            return 0;

        case WM_QUERYENDSESSION:
        case WM_CLOSE:

            if (IDOK != MessageBox(hwnd, "OK to close window?",
                                   "Hello",
                                   MB_ICONQUESTION | MB_OKCANCEL))
                return 0;

            break;  // i.e., call DefMDIChildProc

        case WM_DESTROY:
            pHelloData = cast(PHELLODATA)GetWindowLongPtr(hwnd, 0);
            HeapFree(GetProcessHeap(), 0, pHelloData);
            return 0;

        default:
    }

    // Pass unprocessed message to DefMDIChildProc

    return DefMDIChildProc(hwnd, message, wParam, lParam);
}

extern (Windows)
LRESULT RectWndProc(HWND hwnd, UINT message,
                    WPARAM wParam, LPARAM lParam)
{
    static HWND hwndClient, hwndFrame;
    HBRUSH hBrush;
    HDC hdc;
    PRECTDATA pRectData;
    PAINTSTRUCT ps;
    int xLeft, xRight, yTop, yBottom;
    short nRed, nGreen, nBlue;

    switch (message)
    {
        case WM_CREATE:

            // Allocate memory for window private data
            pRectData = cast(PRECTDATA)HeapAlloc(GetProcessHeap(),
                                             HEAP_ZERO_MEMORY, RECTDATA.sizeof);

            SetWindowLongPtr(hwnd, 0, cast(c_long)pRectData);

            // Start the timer going
            SetTimer(hwnd, 1, 250, NULL);

            // Save some window handles
            hwndClient = GetParent(hwnd);
            hwndFrame  = GetParent(hwndClient);
            return 0;

        case WM_SIZE:          // If not minimized, save the window size

            if (wParam != SIZE_MINIMIZED)
            {
                pRectData = cast(PRECTDATA)GetWindowLongPtr(hwnd, 0);

                pRectData.cxClient = LOWORD(lParam);
                pRectData.cyClient = HIWORD(lParam);
            }

            break;       // WM_SIZE must be processed by DefMDIChildProc

        case WM_TIMER:         // Display a random rectangle

            pRectData = cast(PRECTDATA)GetWindowLongPtr(hwnd, 0);

            xLeft   = uniform(0, pRectData.cxClient);
            xRight  = uniform(0, pRectData.cxClient);
            yTop    = uniform(0, pRectData.cyClient);
            yBottom = uniform(0, pRectData.cyClient);
            nRed    = cast(short)uniform(0, 255);
            nGreen  = cast(short)uniform(0, 255);
            nBlue   = cast(short)uniform(0, 255);

            hdc    = GetDC(hwnd);
            hBrush = CreateSolidBrush(RGB(cast(ubyte)nRed, cast(ubyte)nGreen, cast(ubyte)nBlue));
            SelectObject(hdc, hBrush);

            Rectangle(hdc, min(xLeft, xRight), min(yTop, yBottom),
                      max(xLeft, xRight), max(yTop, yBottom));

            ReleaseDC(hwnd, hdc);
            DeleteObject(hBrush);
            return 0;

        case WM_PAINT:         // Clear the window

            InvalidateRect(hwnd, NULL, TRUE);
            hdc = BeginPaint(hwnd, &ps);
            EndPaint(hwnd, &ps);
            return 0;

        case WM_MDIACTIVATE:   // Set the appropriate menu

            if (lParam == cast(LPARAM)hwnd)
                SendMessage(hwndClient, WM_MDISETMENU, cast(WPARAM)hMenuRect,
                            cast(LPARAM)hMenuRectWindow);
            else
                SendMessage(hwndClient, WM_MDISETMENU, cast(WPARAM)hMenuInit,
                            cast(LPARAM)hMenuInitWindow);

            DrawMenuBar(hwndFrame);
            return 0;

        case WM_DESTROY:
            pRectData = cast(PRECTDATA)GetWindowLongPtr(hwnd, 0);
            HeapFree(GetProcessHeap(), 0, pRectData);
            KillTimer(hwnd, 1);
            return 0;

        default:
    }

    // Pass unprocessed message to DefMDIChildProc
    return DefMDIChildProc(hwnd, message, wParam, lParam);
}
