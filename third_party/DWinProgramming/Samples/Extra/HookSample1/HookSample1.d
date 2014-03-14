module HookSample1;

/*
 * See http://msdn.microsoft.com/en-us/library/ms644960%28v=VS.85%29.aspx
 * Ported to D2 by Andrej Mitrovic, 2011.
 *
 * Minor todo: Horizontal area behind text should be blitted entirely.
 */

pragma(lib, "gdi32.lib");

import core.memory;
import core.runtime;
import core.thread;
import core.stdc.string;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.utf;

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;

import std.algorithm;
import std.array;
import std.stdio;
import std.conv;
import std.typetuple;
import std.typecons;
import std.traits;

alias std.utf.count count;

import resource;

auto toUTF16z(S)(S s) { return toUTFz!(const(wchar)*)(s); }

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
        MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

int ErrMsg(string s) 
{
    return MessageBox(null, s.toUTF16z, ("ERROR"), MB_OK | MB_ICONEXCLAMATION);
}

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    string appName = "HookSample1";
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
    wndclass.hbrBackground = cast(HBRUSH)GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = appName.toUTF16z;
    wndclass.lpszClassName = appName.toUTF16z;

    if(!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,      // window class name
                         "The Hello Program",  // window caption
                         WS_OVERLAPPEDWINDOW,  // window style
                         CW_USEDEFAULT,        // initial x position
                         CW_USEDEFAULT,        // initial y position
                         CW_USEDEFAULT,        // initial x size
                         CW_USEDEFAULT,        // initial y size
                         NULL,                 // parent window handle
                         NULL,                 // window menu handle
                         hInstance,            // program instance handle
                         NULL);                // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

enum NUMHOOKS = 7;

struct MYHOOKDATA
{
    int nType;  // hook type (WH_CALLWNDPROC, etc)
    HOOKPROC hkprc;
    HHOOK hhook;
}

MYHOOKDATA[NUMHOOKS] myhookdata;

HWND gh_hwndMain;

extern(Windows) 
LRESULT WndProc(HWND hwndMain, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    static BOOL[NUMHOOKS] afHooks;
    static HMENU hmenu;
    int index;

    gh_hwndMain = hwndMain;

    switch (uMsg)
    {
        case WM_CREATE:

            // Save the menu handle
            hmenu = GetMenu(hwndMain);

            // Initialize structures with hook data. The menu-item identifiers are
            // defined as 0 through 6 in the header file app.h. They can be used to
            // identify array elements both here and during the WM_COMMAND message.
            myhookdata[IDM_CALLWNDPROC].nType = WH_CALLWNDPROC;
            myhookdata[IDM_CALLWNDPROC].hkprc = &CallWndProc;
            myhookdata[IDM_CBT].nType         = WH_CBT;
            myhookdata[IDM_CBT].hkprc         = &CBTProc;
            myhookdata[IDM_DEBUG].nType       = WH_DEBUG;
            myhookdata[IDM_DEBUG].hkprc       = &DebugProc;
            myhookdata[IDM_GETMESSAGE].nType  = WH_GETMESSAGE;
            myhookdata[IDM_GETMESSAGE].hkprc  = &GetMsgProc;
            myhookdata[IDM_KEYBOARD].nType    = WH_KEYBOARD;
            myhookdata[IDM_KEYBOARD].hkprc    = &KeyboardProc;
            myhookdata[IDM_MOUSE].nType       = WH_MOUSE;
            myhookdata[IDM_MOUSE].hkprc       = &MouseProc;
            myhookdata[IDM_MSGFILTER].nType   = WH_MSGFILTER;
            myhookdata[IDM_MSGFILTER].hkprc   = &MessageProc;

            return 0;

        case WM_COMMAND:
        {
            switch (LOWORD(wParam))
            {
                // The user selected a hook command from the menu.
                case IDM_CALLWNDPROC:
                case IDM_CBT:
                case IDM_DEBUG:
                case IDM_GETMESSAGE:
                case IDM_KEYBOARD:
                case IDM_MOUSE:
                case IDM_MSGFILTER:
                {
                    // Use the menu-item identifier as an index
                    // into the array of structures with hook data.
                    index = LOWORD(wParam);

                    if (!afHooks[index])
                    {
                        // If the selected type of hook procedure isn't
                        // installed yet, install it and check the
                        // associated menu item.                        
                        myhookdata[index].hhook = SetWindowsHookEx(
                            myhookdata[index].nType,
                            myhookdata[index].hkprc,
                            cast(HINSTANCE)null,    // DLL handle, must be null for current thread handlers
                            GetCurrentThreadId());  // Thread ID, or 0 if used for all desktop threads
                        
                        // SetWindowsHookEx: http://msdn.microsoft.com/en-us/library/ms644990%28v=VS.85%29.aspx
                        
                        CheckMenuItem(hmenu, index, MF_BYCOMMAND | MF_CHECKED);
                        afHooks[index] = TRUE;
                    }
                    else                        
                    {
                        // If the selected type of hook procedure is
                        // already installed, remove it and remove the
                        // check mark from the associated menu item.                        
                        UnhookWindowsHookEx(myhookdata[index].hhook);
                        CheckMenuItem(hmenu, index, MF_BYCOMMAND | MF_UNCHECKED);
                        afHooks[index] = FALSE;
                    }
                    break;
                }

                case IDM_APP_EXIT:
                    SendMessage(hwndMain, WM_CLOSE, 0, 0);
                    return 0;                
                
                default:
                    return DefWindowProc(hwndMain, uMsg, wParam, lParam);
            }

            break;
        }

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;        
        
        
        default:
            return DefWindowProc(hwndMain, uMsg, wParam, lParam);
    }

    return 0;
}

void LookUpTheMessage(PMSG pMsg, out string buffer)
{
    buffer = to!string(*pMsg);
}

/****************************************************************
   WH_CALLWNDPROC hook procedure
****************************************************************/
extern(Windows)
LRESULT CallWndProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    string szMsg;
    HDC  hdc;
    static int c = 0;
    size_t  cch;
    HRESULT hResult;

    if (nCode < 0)  // do not process message
        return CallNextHookEx(myhookdata[IDM_CALLWNDPROC].hhook, nCode, wParam, lParam);

    // Call an application-defined function that converts a message
    // constant to a string and copies it to a buffer.
    LookUpTheMessage(cast(PMSG)lParam, szMsg);

    hdc = GetDC(gh_hwndMain);

    switch (nCode)
    {
        case HC_ACTION:
            auto buffer = format("CALLWNDPROC - tsk: %s, msg: %s, %s times   ", wParam, szMsg, c++);
            TextOut(hdc, 2, 15, buffer.toUTF16z, buffer.count);
            break;

        default:
            break;
    }

    ReleaseDC(gh_hwndMain, hdc);

    return CallNextHookEx(myhookdata[IDM_CALLWNDPROC].hhook, nCode, wParam, lParam);
}

/****************************************************************
   WH_GETMESSAGE hook procedure
****************************************************************/
extern(Windows) 
LRESULT GetMsgProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    string szMSGBuf;
    string szRem;
    string szMsg;
    HDC  hdc;
    static int c = 0;
    size_t  cch;
    HRESULT hResult;

    if (nCode < 0) // do not process message
        return CallNextHookEx(myhookdata[IDM_GETMESSAGE].hhook, nCode, wParam, lParam);

    switch (nCode)
    {
        case HC_ACTION:

            switch (wParam)
            {
                case PM_REMOVE:
                    szRem = "PM_REMOVE";
                    break;

                case PM_NOREMOVE:
                    szRem = "PM_NOREMOVE";
                    break;

                default:
                    szRem = "Unknown";
            }

            // Call an application-defined function that converts a
            // message constant to a string and copies it to a
            // buffer.

            LookUpTheMessage(cast(PMSG)lParam, szMsg);

            hdc     = GetDC(gh_hwndMain);
            szMSGBuf = format("GETMESSAGE - wParam: %s, msg: %s, %s times   ", szRem, szMsg, c++);
            TextOut(hdc, 2, 35, szMSGBuf.toUTF16z, szMSGBuf.count);
            break;

        default:
            break;
    }

    ReleaseDC(gh_hwndMain, hdc);

    return CallNextHookEx(myhookdata[IDM_GETMESSAGE].hhook, nCode, wParam, lParam);
}

/****************************************************************
   WH_DEBUG hook procedure
****************************************************************/
extern(Windows) 
LRESULT DebugProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    string szBuf;
    HDC  hdc;
    static int c = 0;
    size_t  cch;
    HRESULT hResult;

    if (nCode < 0)  // do not process message
        return CallNextHookEx(myhookdata[IDM_DEBUG].hhook, nCode,
                              wParam, lParam);

    hdc = GetDC(gh_hwndMain);

    switch (nCode)
    {
        case HC_ACTION:
            szBuf = format("DEBUG - nCode: %s, tsk: %s, %s times   ", nCode, wParam, c++);
            TextOut(hdc, 2, 55, szBuf.toUTF16z, szBuf.count);
            break;

        default:
            break;
    }

    ReleaseDC(gh_hwndMain, hdc);

    return CallNextHookEx(myhookdata[IDM_DEBUG].hhook, nCode, wParam, lParam);
}

/****************************************************************
   WH_CBT hook procedure
****************************************************************/
extern(Windows)
LRESULT CBTProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    string szBuf;
    string szCode;
    HDC  hdc;
    static int c = 0;
    size_t  cch;
    HRESULT hResult;

    if (nCode < 0)  // do not process message
        return CallNextHookEx(myhookdata[IDM_CBT].hhook, nCode, wParam, lParam);

    hdc = GetDC(gh_hwndMain);

    //~ switch (nCode)  // todo: probably wrong
    switch (wParam)
    {
        case HCBT_ACTIVATE:
            szCode = "HCBT_ACTIVATE";
            break;

        case HCBT_CLICKSKIPPED:
            szCode = "HCBT_CLICKSKIPPED";
            break;

        case HCBT_CREATEWND:
            szCode = "HCBT_CREATEWND";
            break;

        case HCBT_DESTROYWND:
            szCode = "HCBT_DESTROYWND";
            break;

        case HCBT_KEYSKIPPED:
            szCode = "HCBT_KEYSKIPPED";
            break;

        case HCBT_MINMAX:
            szCode = "HCBT_MINMAX";
            break;

        case HCBT_MOVESIZE:
            szCode = "HCBT_MOVESIZE";
            break;

        case HCBT_QS:
            szCode = "HCBT_QS";
            break;

        case HCBT_SETFOCUS:
            szCode = "HCBT_SETFOCUS";
            break;

        case HCBT_SYSCOMMAND:
            szCode = "HCBT_SYSCOMMAND";
            break;

        default:
            szCode = "Unknown";
            break;
    }

    szBuf = format("CBT -  nCode: %s, tsk: %s, %s times   ", szCode, wParam, c++);
    TextOut(hdc, 2, 75, szBuf.toUTF16z, szBuf.count);
    ReleaseDC(gh_hwndMain, hdc);

    return CallNextHookEx(myhookdata[IDM_CBT].hhook, nCode, wParam, lParam);
}

/****************************************************************
   WH_MOUSE hook procedure
****************************************************************/
extern(Windows) 
LRESULT MouseProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    string szBuf;
    string szMsg;
    HDC  hdc;
    static int c = 0;
    size_t  cch;
    HRESULT hResult;

    if (nCode < 0)  // do not process the message
        return CallNextHookEx(myhookdata[IDM_MOUSE].hhook, nCode,
                              wParam, lParam);

    // Call an application-defined function that converts a message
    // constant to a string and copies it to a buffer.

    LookUpTheMessage(cast(PMSG)lParam, szMsg);

    hdc     = GetDC(gh_hwndMain);
    szBuf = format("MOUSE - nCode: %s, msg: %s, x: %s, y: %s, %s times   ",
                   nCode, szMsg, LOWORD(lParam), HIWORD(lParam), c++);
    
    TextOut(hdc, 2, 95, szBuf.toUTF16z, szBuf.count);
    ReleaseDC(gh_hwndMain, hdc);

    return CallNextHookEx(myhookdata[IDM_MOUSE].hhook, nCode, wParam, lParam);
}

/****************************************************************
   WH_KEYBOARD hook procedure
****************************************************************/
extern(Windows)
LRESULT KeyboardProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    string szBuf;
    HDC  hdc;
    static int c = 0;
    size_t  cch;
    HRESULT hResult;

    if (nCode < 0)  // do not process message
        return CallNextHookEx(myhookdata[IDM_KEYBOARD].hhook, nCode, wParam, lParam);

    szBuf = format("KEYBOARD - nCode: %s, vk: %s, %s times ", nCode, wParam, c++);
    hdc     = GetDC(gh_hwndMain);
    
    TextOut(hdc, 2, 115, szBuf.toUTF16z, szBuf.count);
    ReleaseDC(gh_hwndMain, hdc);

    return CallNextHookEx(myhookdata[IDM_KEYBOARD].hhook, nCode, wParam, lParam);
}

/****************************************************************
   WH_MSGFILTER hook procedure
****************************************************************/

extern(Windows)
LRESULT MessageProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    string szBuf;
    string szMsg;
    string szCode;
    HDC  hdc;
    static int c = 0;
    size_t  cch;
    HRESULT hResult;

    if (nCode < 0)  // do not process message
        return CallNextHookEx(myhookdata[IDM_MSGFILTER].hhook, nCode,
                              wParam, lParam);

    switch (nCode)
    {
        case MSGF_DIALOGBOX:
            szCode = "MSGF_DIALOGBOX";
            break;

        case MSGF_MENU:
            szCode = "MSGF_MENU";
            break;

        case MSGF_SCROLLBAR:
            szCode = "MSGF_SCROLLBAR";
            break;

        default:
            szCode = format("Unknown: %s", nCode);
            break;
    }

    // Call an application-defined function that converts a message
    // constant to a string and copies it to a buffer.

    LookUpTheMessage(cast(PMSG)lParam, szMsg);

    hdc     = GetDC(gh_hwndMain);
    szBuf = format("MSGFILTER  nCode: %s, msg: %s, %s times    ", szCode, szMsg, c++);
    
    TextOut(hdc, 2, 135, szBuf.toUTF16z, szBuf.count);
    ReleaseDC(gh_hwndMain, hdc);

    return CallNextHookEx(myhookdata[IDM_MSGFILTER].hhook, nCode, wParam, lParam);
}
