/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module About2;

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

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;

import resource;

string appName     = "About2";
string description = "About Box Demo Program";
enum ID_TIMER = 1;
HINSTANCE hinst;

int iCurrentColor = IDC_BLACK, iCurrentFigure = IDC_RECT;

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
    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(hInstance, appName.toUTF16z);
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
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    PAINTSTRUCT ps;
    static HINSTANCE hInstance;

    switch (message)
    {
        case WM_CREATE:
            hInstance = (cast(LPCREATESTRUCT)lParam).hInstance;
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_APP_ABOUT:

                    if (DialogBox(hInstance, "AboutBox", hwnd, &AboutDlgProc))
                        InvalidateRect(hwnd, NULL, TRUE);

                    break;
                    
                default:
            }

            return 0;

        case WM_PAINT:
            BeginPaint(hwnd, &ps);
            scope (exit) EndPaint(hwnd, &ps);

            PaintWindow(hwnd, iCurrentColor, iCurrentFigure);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern (Windows)
BOOL AboutDlgProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HWND hCtrlBlock;
    static int  iColor, iFigure;

    switch (message)
    {
        case WM_INITDIALOG:
            iColor  = iCurrentColor;
            iFigure = iCurrentFigure;

            CheckRadioButton(hDlg, IDC_BLACK, IDC_WHITE,   iColor);
            CheckRadioButton(hDlg, IDC_RECT,  IDC_ELLIPSE, iFigure);

            hCtrlBlock = GetDlgItem(hDlg, IDC_PAINT);

            SetFocus(GetDlgItem(hDlg, iColor));
            return FALSE;

        case WM_COMMAND:
        {
            switch (LOWORD(wParam))
            {
                case IDOK:
                    iCurrentColor  = iColor;
                    iCurrentFigure = iFigure;
                    EndDialog(hDlg, TRUE);
                    return TRUE;

                case IDCANCEL:
                    EndDialog(hDlg, FALSE);
                    return TRUE;

                case IDC_BLACK:
                case IDC_RED:
                case IDC_GREEN:
                case IDC_YELLOW:
                case IDC_BLUE:
                case IDC_MAGENTA:
                case IDC_CYAN:
                case IDC_WHITE:
                    iColor = LOWORD(wParam);
                    CheckRadioButton(hDlg, IDC_BLACK, IDC_WHITE, LOWORD(wParam));
                    PaintTheBlock(hCtrlBlock, iColor, iFigure);
                    return TRUE;

                case IDC_RECT:
                case IDC_ELLIPSE:
                    iFigure = LOWORD(wParam);
                    CheckRadioButton(hDlg, IDC_RECT, IDC_ELLIPSE, LOWORD(wParam));
                    PaintTheBlock(hCtrlBlock, iColor, iFigure);
                    return TRUE;

                default:
            }

            break;
        }

        case WM_PAINT:
            PaintTheBlock(hCtrlBlock, iColor, iFigure);
            break;

        default:
    }

    return FALSE;
}

void PaintWindow(HWND hwnd, int iColor, int iFigure)
{
    auto crColor = [RGB(  0,   0, 0), RGB(  0,   0, 255),
                    RGB(  0, 255, 0), RGB(  0, 255, 255),
                    RGB(255,   0, 0), RGB(255,   0, 255),
                    RGB(255, 255, 0), RGB(255, 255, 255)];

    HBRUSH hBrush;
    HDC  hdc;
    RECT rect;

    hdc = GetDC(hwnd);
    GetClientRect(hwnd, &rect);
    hBrush = CreateSolidBrush(crColor[iColor - IDC_BLACK]);
    hBrush = cast(HBRUSH)SelectObject(hdc, hBrush);

    if (iFigure == IDC_RECT)
        Rectangle(hdc, rect.left, rect.top, rect.right, rect.bottom);
    else
        Ellipse(hdc, rect.left, rect.top, rect.right, rect.bottom);

    DeleteObject(SelectObject(hdc, hBrush));
    ReleaseDC(hwnd, hdc);
}

void PaintTheBlock(HWND hCtrl, int iColor, int iFigure)
{
    InvalidateRect(hCtrl, NULL, TRUE);
    UpdateWindow(hCtrl);
    PaintWindow(hCtrl, iColor, iFigure);
}
