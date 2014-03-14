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
import win32.commdlg;
pragma(lib, "comdlg32.lib");

import std.algorithm;
import std.array;
import std.stdio;
import std.conv;
import std.typetuple;
import std.typecons;
import std.traits;

/*
 * Demonstrates a Superclassed Button Control.
 * Click on the upper-left button to get a
 * font selection dialog and select a new font.
 *
 * Note: Superclassing is also used in the DGUI and DFL libraries.
 *
 * Copyright © 2005-2006 Ken Fitlike.
 * http://winapi.foosyerdoos.org.uk/c ode/subsuperclass/htm/superclassedit.php
 *
 * Ported to D2 by Andrej Mitrovic, 2011.
 */

// =============================================================================
// SUPERCLASSED EDIT CONTROL - Copyright © 2003,2005 Ken Fitlike
// =============================================================================
// API functions used: CallWindowProc,ChooseFont,CreateFontIndirect,
// CreateWindowEx,DefWindowProc,DeleteObject,DispatchMessage,FreeLibrary,
// GetMessage,GetClassInfoEx,GetProcAddress,GetStockObject,GetSystemMetrics,
// LoadImage,LoadLibrary,MessageBox,PostQuitMessage,RegisterClassEx,SendMessage,
// SetFocus,SetWindowTheme,ShowWindow,UpdateWindow,TranslateMessage,WinMain.
// =============================================================================
// Demonstrates window superclassing. An edit control is superclassed to give
// extra functionality in the form of an additional button that enables font
// changes to be made. 
// =============================================================================

auto toUTF16z(S) (S s)
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

// setup some edit control id's
enum
{
    IDC_SUPERCLASSED_EDIT=200
}


WNDPROC wpOldProc;

int myWinMain(HINSTANCE hInst, HINSTANCE, LPSTR, int nCmd)
{
    string classname = "SIMPLEWND";
    WNDCLASSEX wcx   ; // used for storing information about the wnd 'class'

    wcx.cbSize      = WNDCLASSEX.sizeof;
    wcx.lpfnWndProc = &WndProc;            // wnd Procedure pointer
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

    HWND hwnd = CreateWindowEx(0,                                     // extended styles
                               classname.toUTF16z,                     // name: wnd 'class'
                               "Superclassed Window - Edit",      // wnd title
                               WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN, // wnd style
                               desktopwidth / 4,                      // position:left
                               desktopheight / 4,                     // position: top
                               desktopwidth / 2,                      // width
                               desktopheight / 2,                     // height
                               null,                                     // parent wnd handle
                               null,                                     // menu handle/wnd id
                               hInst,                                 // app instance
                               null);                                    // user defined info

    if (!hwnd)
    {
        ErrMsg("Failed to create wnd");
        return -1;
    }

    ShowWindow(hwnd, nCmd);
    UpdateWindow(hwnd);

    // start message loop - windows applications are 'event driven' waiting on user,
    // application or system signals to determine what action, if any, to take. Note
    // that an error may cause GetMessage to return a negative value so, ideally,
    // this result should be tested for and appropriate action taken to deal with
    // it(the approach taken here is to simply quit the application).
    MSG msg;

    while (GetMessage(&msg, null, 0, 0) > 0)
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return cast(int)(msg.wParam);
}


// Main window message processing functions
extern(Windows)
LRESULT WndProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    switch (uMsg)
    {
        case WM_PARENTNOTIFY:
        {
            OnParentNotify(hwnd, LOWORD(wParam), cast(HWND)(lParam));
            return 0;
        }

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
    RECT rc = RECT(60, 10, 200, 70);

    // the various edit control types are created by simply varying the style bits
    CreateEdit(hwnd, cs.hInstance, ES_MULTILINE | WS_VSCROLL | WS_CLIPCHILDREN, rc,
               IDC_SUPERCLASSED_EDIT, ("Superclassed Edit"));

    return 0;
}


void OnParentNotify(HWND hwnd, UINT uMsg, HWND hChild)
{
    // handles parent window's WM_PARENTNOTIFY message
    if (uMsg == WM_CREATE)
    {
        // attempting to set the formatting rectangle in the superclassed edit
        // control's own WM_CREATE handler fails so do it here instead. Note that the
        // superclassed edit control's WM_CREATE message is issued prior to the
        // parent's WM_PARENTNOTIFY message by the system.
        SetFormattingRect(hChild);
    }
}


// superclassed edit control message functions
extern(Windows)
LRESULT EditProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    switch (uMsg)
    {
        case WM_COMMAND:
            CallWindowProc(wpOldProc, hwnd, uMsg, wParam, lParam);
            OnCommandEdit(hwnd, LOWORD(wParam), HIWORD(wParam),
                          cast(HWND)(lParam));
            return 0;

        case WM_CREATE:

            // get default creation first
            CallWindowProc(wpOldProc, hwnd, uMsg, wParam, lParam);
            return OnCreateEdit(hwnd, cast(CREATESTRUCT*)(lParam));

        default:
    }
    
    return CallWindowProc(wpOldProc, hwnd, uMsg, wParam, lParam);
}


void OnCommandEdit(HWND hwnd, int id, int nNotify, HWND hChild)
{
    // handles WM_COMMAND message of the superclassed edit control
    if (hChild && nNotify == BN_CLICKED)
    {
        HFONT hFont = ChangeFont(hwnd);

        if (hFont)
        {
            // change the superclassed edit control font and destroy the existing one
            DeleteObject(cast(HFONT)(SendMessage(hwnd, WM_SETFONT,
                                                             cast(WPARAM)(hFont), 0)));
            SetFormattingRect(hwnd);
        }

        // restore focus to parent superclassed edit control
        SetFocus(hwnd);
    }
}


int OnCreateEdit(HWND hwnd, CREATESTRUCT* cs)
{
    // handles the WM_CREATE message of the superclassed edit control; return -1 to
    // fail window creation

    // change to gui font
    SendMessage(hwnd, WM_SETFONT, cast(WPARAM)(GetStockObject(DEFAULT_GUI_FONT)), 0);

    // create a small button and place it in top-left corner of edit control
    HWND hBtn = CreateWindowEx(0, "button", null,
                               WS_CHILD | WS_VISIBLE,
                               0, 0, 10, 10,
                               hwnd,
                               null,
                               cs.hInstance, 
                               null);

    // if winxp themes are used the button will be obscured so turn off themes for
    // button control but use dynamic linking so that code still works with
    // pre-winxp systems
    HINSTANCE hLib = LoadLibrary(("UxTheme.dll"));

    if (hLib)
    {
        alias extern(Windows) HRESULT function(HWND, LPCWSTR, LPCWSTR) DllSetWindowTheme;
        auto SetWindowTheme = cast(DllSetWindowTheme)GetProcAddress(hLib, "SetWindowTheme");
        SetWindowTheme(hBtn, " ", " ");
        FreeLibrary(hLib);
    }

    // select all the text in the edit control
    SendMessage(hwnd, EM_SETSEL, 0, cast(LPARAM)(-1));
    SetFocus(hwnd);

    return 0;
}

HFONT ChangeFont(HWND hwnd)
{
    // display font common dialog and return any created font based on user
    // selection
    CHOOSEFONT cf;
    LOGFONT lf   ;

    cf.lStructSize = CHOOSEFONT.sizeof;
    cf.hwndOwner   = hwnd;
    cf.lpLogFont   = &lf;
    cf.Flags       = CF_SCREENFONTS;

    // display the font common dialog box
    if (ChooseFont(&cf))
    {
        return CreateFontIndirect(cf.lpLogFont);
    }

    return null;
}


HWND CreateEdit(HWND hParent, HINSTANCE hInst, DWORD dwStyle,
                ref RECT rc, int id, string caption)
{
    // superclass the edit control, register the new edit control class and then
    // create a control of that control class.
    WNDCLASSEX wcx;
    wcx.cbSize = wcx.sizeof;

    // fill out the WNDCLASSEX with system class info for edit control
    GetClassInfoEx(null, "edit", &wcx);

    // save important information
    wpOldProc = wcx.lpfnWndProc; // save original wndproc
    // now change information to suit requirements
    string classname = "superclassed_edit";
    wcx.lpszClassName = classname.toUTF16z; // unique wnd class name
    wcx.lpfnWndProc   = &EditProc;          // new edit wndproc
    wcx.hInstance     = hInst;

    // and register the new class with the system
    if (!RegisterClassEx(&wcx))
    {
        ErrMsg(("Failed to register edit control superclass"));
        return null;
    }

    dwStyle |= WS_CHILD | WS_VISIBLE;
    return CreateWindowEx(WS_EX_CLIENTEDGE,  // extended styles
                          classname.toUTF16z, // control 'class' name
                          caption.toUTF16z,   // control caption
                          dwStyle,           // control style
                          rc.left,           // position: left
                          rc.top,            // position: top
                          rc.right,          // width
                          rc.bottom,         // height
                          hParent,           // parent window handle
                                             // control's ID
                          cast(HMENU)(cast(INT_PTR)(id)),
                          hInst,             // application instance
                          null);                // user defined info
}


int ErrMsg(string s)
{
    return MessageBox(null, s.toUTF16z, "ERROR", MB_OK | MB_ICONEXCLAMATION);
}


void SetFormattingRect(HWND hwnd)
{
    // sets the formatting rectangle for the superclassed edit control ie the
    // dimensions used to display text.
    int MARGIN_X = 10;
    int MARGIN_Y = 10;

    RECT rc;
    SendMessage(hwnd, EM_GETRECT, 0, cast(LPARAM)(&rc));
    rc.left += MARGIN_X;
    rc.top  += MARGIN_Y;
    SendMessage(hwnd, EM_SETRECT, 0, cast(LPARAM)(&rc));
}
