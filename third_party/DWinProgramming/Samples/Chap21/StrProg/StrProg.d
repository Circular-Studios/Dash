module name;

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

import resource;
import StrLib;

string appName     = "StrProg";
string description = "DLL Demonstration Program";
HINSTANCE hinst;

// @BUG@ DMD assumes a module info symbol is always present when importing a module,
// however a DLL doesn't export its moduleinfo symbol, therefore we add a dummy symbol
// here to silence the linker.
extern(C) int D6StrLib12__ModuleInfoZ;

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

struct CBPARAM
{
    HDC hdc;
    int xText;
    int yText;
    int xStart;
    int yStart;
    int xIncr;
    int yIncr;
    int xMax;
    int yMax;
}

__gshared wchar[MAX_LENGTH] szString = 0;

extern (Windows)
BOOL DlgProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_INITDIALOG:
            SendDlgItemMessage(hDlg, IDC_STRING, EM_LIMITTEXT, MAX_LENGTH, 0);
            return TRUE;

        case WM_COMMAND:

            switch (wParam)
            {
                case IDOK:
                    GetDlgItemText(hDlg, IDC_STRING, szString.ptr, MAX_LENGTH);
                    EndDialog(hDlg, TRUE);
                    return TRUE;

                case IDCANCEL:
                    EndDialog(hDlg, FALSE);
                    return TRUE;
                
                default:
            }
            
        default:
    }

    return FALSE;
}

void WriteStrings(string[] strings, CBPARAM pcbp)
{
    foreach (str; strings)
    {
        TextOut(pcbp.hdc, pcbp.xText, pcbp.yText, str.toUTF16z, str.length);

        pcbp.yText += pcbp.yIncr;
        if (pcbp.yText > pcbp.yMax)
        {
            pcbp.yText = pcbp.yStart;

            if ((pcbp.xText += pcbp.xIncr) > pcbp.xMax)
                return;
        }
    }
}

wstring fromWStringz(const wchar* s)
{
    if (s is null) 
        return null;

    wchar* ptr;
    for (ptr = cast(wchar*)s; *ptr; ++ptr) {}

    return to!wstring(s[0..ptr-s]);
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HINSTANCE hInst;
    static int  cxChar, cyChar, cxClient, cyClient;
    static UINT iDataChangeMsg;
    CBPARAM cbparam;
    HDC hdc;
    PAINTSTRUCT ps;
    TEXTMETRIC  tm;

    switch (message)
    {
        case WM_CREATE:
            hInst = (cast(LPCREATESTRUCT)lParam).hInstance;
            hdc   = GetDC(hwnd);
            GetTextMetrics(hdc, &tm);
            cxChar = cast(int)tm.tmAveCharWidth;
            cyChar = cast(int)(tm.tmHeight + tm.tmExternalLeading);
            ReleaseDC(hwnd, hdc);

            // Register message for notifying instances of data changes
            iDataChangeMsg = RegisterWindowMessage("StrProgDataChange");
            return 0;

        case WM_COMMAND:

            switch (wParam)
            {
                case IDM_ENTER:

                    if (DialogBox(hInst, "EnterDlg", hwnd, &DlgProc))
                    {
                        AddString(to!string(fromWStringz(szString.ptr)));
                        PostMessage(HWND_BROADCAST, iDataChangeMsg, 0, 0);
                    }

                    break;

                case IDM_DELETE:

                    if (DialogBox(hInst, "DeleteDlg", hwnd, &DlgProc))
                    {
                        DeleteString(to!string(fromWStringz(szString.ptr)));
                        PostMessage(HWND_BROADCAST, iDataChangeMsg, 0, 0);
                    }

                    break;
                    
                default:
            }

            return 0;

        case WM_SIZE:
            cxClient = cast(int)LOWORD(lParam);
            cyClient = cast(int)HIWORD(lParam);
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            cbparam.hdc   = hdc;
            cbparam.xText = cbparam.xStart = cxChar;
            cbparam.yText = cbparam.yStart = cyChar;
            cbparam.xIncr = cxChar * MAX_LENGTH;
            cbparam.yIncr = cyChar;
            cbparam.xMax  = cbparam.xIncr * (1 + cxClient / cbparam.xIncr);
            cbparam.yMax  = cyChar * (cyClient / cyChar - 1);

            WriteStrings(GetStrings(), cbparam);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
            if (message == iDataChangeMsg)
                InvalidateRect(hwnd, NULL, TRUE);

            break;
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
