module Subclass;

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

/*
 * Demonstrates a Subclassed Button Control.
 * Right click to edit, left click on button
 * to exit edit mode.
 * 
 * Copyright © 2005-2006 Ken Fitlike.
 * http://winapi.foosyerdoos.org.uk/code/subsuperclass/htm/subclassbtn.php
 *
 * Ported to D2 by Andrej Mitrovic, 2011.
 */

// =============================================================================
// SUBCLASSED CONTROLS: BUTTON - Copyright © 2000,2006 Ken Fitlike
// =============================================================================
// API functions used: CallWindowProc,CreateWindowEx,DefWindowProc,
// DestroyWindow,DispatchMessage,GetClientRect,GetDC,GetMessage,
// GetSystemMetrics,GetTextExtentPoint32,GetWindowLongPtr,GetWindowText,
// InvalidateRect,LoadImage,MessageBox,PostQuitMessage,RegisterClassEx,
// ReleaseDC,SendMessage,SetFocus,SetWindowLongPtr,SetWindowText,ShowWindow,
// UpdateWindow,TranslateMessage,WinMain.
// =============================================================================
// Demonstrates subclassing of button control. This uses the traditional
// approach to window subclassing by employing the SetWindowLongPtr api
// function to change the default, system window procedure to the user-defined
// one. This technique can be used with win9x and later operating systems.
// =============================================================================

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

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

//setup control id's
enum
{
    IDC_BUTTON = 200,
    IDC_EDIT
}

int myWinMain(HINSTANCE hInst, HINSTANCE, LPSTR pStr, int nCmd)
{
    string classname = "SIMPLEWND";
    WNDCLASSEX wcx;  // used for storing information about the wnd 'class'

    wcx.cbSize      = WNDCLASSEX.sizeof;
    wcx.lpfnWndProc = &WndProc;           // wnd Procedure pointer
    wcx.hInstance   = hInst;              // app instance
    
    // use 'LoadImage' to load wnd class icon and cursor as it supersedes the
    // obsolete functions 'LoadIcon' and 'LoadCursor', although these functions will
    // still work. Because the icon and cursor are loaded from system resources ie
    // they are shared, it is not necessary to free the image resources with either
    // 'DestroyIcon' or 'DestroyCursor'.
    wcx.hIcon = cast(HICON)(LoadImage(null, IDI_APPLICATION,
                                      IMAGE_ICON, 0, 0, LR_SHARED));
    wcx.hCursor = cast(HCURSOR)(LoadImage(null, IDC_ARROW,
                                          IMAGE_CURSOR, 0, 0, LR_SHARED));
    wcx.hbrBackground = cast(HBRUSH)(COLOR_BTNFACE + 1);
    wcx.lpszClassName = classname.toUTF16z;

    // the window 'class' (not c++ class) has to be registered with the system
    // before windows of that 'class' can be created
    if (!RegisterClassEx(&wcx))
    {
        ErrMsg(("Failed to register wnd class"));
        return -1;
    }

    int desktopwidth  = GetSystemMetrics(SM_CXSCREEN);
    int desktopheight = GetSystemMetrics(SM_CYSCREEN);

    HWND hwnd = CreateWindowEx(0,                             //extended styles
                               classname.toUTF16z,            //name: wnd 'class'
                               "Subclassed Button Control",   //wnd title
                               WS_OVERLAPPEDWINDOW,           //wnd style
                               desktopwidth / 4,              //position:left
                               desktopheight / 4,             //position: top
                               desktopwidth / 2,              //width
                               desktopheight / 2,             //height
                               null,                          //parent wnd handle
                               null,                          //menu handle/wnd id
                               hInst,                         //app instance
                               null);                         //user defined info

    if (!hwnd)
    {
        ErrMsg("Failed to create wnd");
        return -1;
    }

    ShowWindow(hwnd, nCmd);
    UpdateWindow(hwnd);

    MSG msg;

    while (GetMessage(&msg, null, 0, 0) > 0)
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return cast(int)(msg.wParam);
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    switch (uMsg)
    {
        case WM_CREATE:
            return OnCreate(hwnd, cast(CREATESTRUCT*)(lParam));

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }
    
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

int OnCreate(HWND hwnd, CREATESTRUCT* cs)
{
    // handles the WM_CREATE message of the main, parent window; return -1 to fail
    // window creation
    auto rc = RECT(10, 10, 260, 40);

    // the various button types are created by simply varying the style bits
    HWND hBtn = CreateControl(hwnd, cs.hInstance, BS_DEFPUSHBUTTON, rc, IDC_BUTTON,
                              ("Right-click to edit this caption"), ("button"));

    // subclass the button control
    WNDPROC OldBtnProc = cast(WNDPROC)(cast(LONG_PTR)(
                                           SetWindowLongPtr(hBtn, GWLP_WNDPROC,
                                                            cast(LONG_PTR)(&BtnProc))));

    // store the original, default window procedure of the button as the button
    // control's user data
    SetWindowLongPtr(hBtn, GWLP_USERDATA, cast(LONG_PTR)(OldBtnProc));

    SetFocus(hBtn);
    return 0;
}

HWND CreateControl(HWND hParent, HINSTANCE hInst, DWORD dwStyle,
                   RECT rc, int id, wstring caption,
                   wstring classname)
{
    dwStyle |= WS_CHILD | WS_VISIBLE;
    return CreateWindowEx(0,                  // extended styles
                          classname.toUTF16z, // control 'class' name
                          caption.toUTF16z,   // control caption
                          dwStyle,            // control style
                          rc.left,            // position: left
                          rc.top,             // position: top
                          rc.right,           // width
                          rc.bottom,          // height
                          hParent,            // parent window handle
                                              // control's ID
                          cast(HMENU)(cast(INT_PTR)(id)),
                          hInst,              // application instance
                          null);              // user defined info
}

int ErrMsg(string s)
{
    return MessageBox(null, s.toUTF16z, ("ERROR"), MB_OK | MB_ICONEXCLAMATION);
}

// subclassed button window procedure and message handling functions
extern (Windows)
LRESULT BtnProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    // This is the subclass window procedure for the button. If the mouse is
    // right-clicked on the button then a single line, flat edit control is created
    // and the button caption copied into it. Any other mouse message (except
    // movement) on the button results in the edit's text being copied as the button
    // caption. The edit control is then destroyed.
    static HWND hEdit;

    // retrieve the previously stored original button window procedure
    static WNDPROC OrigBtnProc;
    bool inited;

    if (!inited)
    {
        OrigBtnProc = cast(WNDPROC)(cast(LONG_PTR)(GetWindowLongPtr(hwnd, GWLP_USERDATA)));
        inited      = true;
    }

    switch (uMsg)
    {
        // if any of the following mouse events occur, check if the edit control
        // exists. If it does then copy its text to the button caption before
        // destroying the edit control.
        case WM_CHAR:
        {
            writeln(wParam);
            break;
        }
            
        case WM_LBUTTONDOWN:
        case WM_MBUTTONDOWN:
        case WM_LBUTTONDBLCLK:
        case WM_MBUTTONDBLCLK:
        case WM_RBUTTONDBLCLK:
        {
            OnMouseClick(hwnd, hEdit);

            // ensure default message handling occurs
            return CallWindowProc(OrigBtnProc, hwnd, uMsg, wParam, lParam);
        }

        // mouse button right-click event
        case WM_RBUTTONDOWN:
        {
            if (!IsWindow(hEdit))
            {
                hEdit = OnRightClick(hwnd);
            }

            return 0;
        }

        default:
    }
    
    return CallWindowProc(OrigBtnProc, hwnd, uMsg, wParam, lParam);
}

void OnMouseClick(HWND hwnd, HWND hEdit)
{
    // event handler for all mouse click messages except WM_RBUTTONDOWN
    // (right-click)
    // check if the edit control exists. If it does then copy its text to the button
    // caption before destroying the edit control.

    if (IsWindow(hEdit))
    {
        enum MAX_TXT_LEN = 64;

        // get the edit text
        wchar[MAX_TXT_LEN] tmp;
        tmp[] = 0;

        if (GetWindowText(hEdit, &tmp[0], MAX_TXT_LEN))
        {
            SetWindowText(hwnd, &tmp[0]);
        }

        DestroyWindow(hEdit);
        InvalidateRect(hwnd, null, 1); // ensure button is completely redrawn
    }
}

HWND OnRightClick(HWND hwnd)
{
    // mouse button right-click event handler. Return handle of the edit control
    // get the button text and its dimensions
    enum MAX_TXT_LEN = 64;
    wchar[MAX_TXT_LEN] tmp;
    tmp[] = 0;

    int t = GetWindowText(hwnd, &tmp[0], MAX_TXT_LEN);

    SIZE sz;
    HDC  hdc = GetDC(hwnd);
    GetTextExtentPoint32(hdc, &tmp[0], t + 1, &sz);
    ReleaseDC(hwnd, hdc);

    // to ensure edit control is created with a usable minimum width
    // get width of eg. 4 characters.
    int nMin = (sz.cx / (cast(int)(tmp.length))) * 4;

    if (sz.cx < nMin)
    {
        sz.cx = nMin;
    }

    sz.cy += 4; // ensure a decent border around edit control's text
    // get button dimensions and adjust those values based on text
    // dimensions to calculate edit control's dimensions.
    RECT rc;
    GetClientRect(hwnd, &rc);
    rc.top = (rc.bottom - sz.cy) / 2;

    rc.left   = (rc.right - sz.cx) / 2;
    rc.right  = sz.cx;
    rc.bottom = sz.cy;

    // create a flat, single line edit control and ensure its width has a
    // reasonable minimum value.
    HINSTANCE hInst = cast(HINSTANCE)cast(LONG_PTR) GetWindowLongPtr(hwnd, GWLP_HINSTANCE);
    HWND hEdit      = CreateControl(hwnd, hInst, WS_BORDER | ES_AUTOHSCROLL, rc, IDC_EDIT,
                                    tmp[0 .. wcslen(tmp.ptr)].idup, "edit");

    // highlight the text and set focus on the edit control
    SendMessage(hEdit, EM_SETSEL, 0, cast(LPARAM)(-1));
    SetFocus(hEdit);
    return hEdit;
}
