/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module OwnDraw;

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

enum ID_TIMER = 1;
enum TWOPI    =(2 * PI);
enum ID_SMALLER =    1;     // button window unique id
enum ID_LARGER  =    2;     // same
enum BTN_WIDTH  =    "(8 * cxChar)";
enum BTN_HEIGHT =    "(4 * cyChar)";

struct Button
{
    int iStyle;
    immutable(char) * szText;
}

Button[] buttons =
[
    Button(BS_PUSHBUTTON,      "PUSHBUTTON"   ),
    Button(BS_DEFPUSHBUTTON,   "DEFPUSHBUTTON"),
    Button(BS_CHECKBOX,        "CHECKBOX"     ),
    Button(BS_AUTOCHECKBOX,    "AUTOCHECKBOX" ),
    Button(BS_RADIOBUTTON,     "RADIOBUTTON"  ),
    Button(BS_3STATE,          "3STATE"       ),
    Button(BS_AUTO3STATE,      "AUTO3STATE"   ),
    Button(BS_GROUPBOX,        "GROUPBOX"     ),
    Button(BS_AUTORADIOBUTTON, "AUTORADIO"    ),
    Button(BS_OWNERDRAW,       "OWNERDRAW"    ),
];

HINSTANCE hInst;

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
    string appName = "OwnDraw";

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

    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        "Owner-Draw Button Demo",      // window caption
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

void Triangle(HDC hdc, POINT[] pt)
{
    SelectObject(hdc, GetStockObject(BLACK_BRUSH));
    Polygon(hdc, pt.ptr, 3);
    SelectObject(hdc, GetStockObject(WHITE_BRUSH));
}

extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HWND hwndSmaller, hwndLarger;    // button window handles
    static int  cxClient, cyClient, cxChar, cyChar;
    int cx, cy;
    LPDRAWITEMSTRUCT pdis;
    POINT[3] pt;
    RECT  rc;

    switch (message)
    {
        case WM_CREATE:
            cxChar = LOWORD(GetDialogBaseUnits());
            cyChar = HIWORD(GetDialogBaseUnits());

            // Create the owner-draw pushbuttons
            hwndSmaller = CreateWindow("button", "",
                                        WS_CHILD | WS_VISIBLE | BS_OWNERDRAW,
                                        0, 0, mixin(BTN_WIDTH), mixin(BTN_HEIGHT),
                                        hwnd, cast(HMENU)ID_SMALLER, hInst, NULL);

            hwndLarger = CreateWindow("button", "",
                                       WS_CHILD | WS_VISIBLE | BS_OWNERDRAW,
                                       0, 0, mixin(BTN_WIDTH), mixin(BTN_HEIGHT),
                                       hwnd, cast(HMENU)ID_LARGER, hInst, NULL);
            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);

            // Move the buttons to the new center
            MoveWindow(hwndSmaller, cxClient / 2 - 3 * mixin(BTN_WIDTH) / 2,
                        cyClient / 2 - mixin(BTN_HEIGHT) / 2,
                        mixin(BTN_WIDTH), mixin(BTN_HEIGHT), TRUE);

            MoveWindow(hwndLarger,  cxClient / 2 + mixin(BTN_WIDTH) / 2,
                        cyClient / 2 - mixin(BTN_HEIGHT) / 2,
                        mixin(BTN_WIDTH), mixin(BTN_HEIGHT), TRUE);
            return 0;

        case WM_COMMAND:
            GetWindowRect(hwnd, &rc);

            // Make the window 10% smaller or larger
            switch (wParam)
            {
                case ID_SMALLER:
                    rc.left   += cxClient / 20;
                    rc.right  -= cxClient / 20;
                    rc.top    += cyClient / 20;
                    rc.bottom -= cyClient / 20;
                    break;

                case ID_LARGER:
                    rc.left   -= cxClient / 20;
                    rc.right  += cxClient / 20;
                    rc.top    -= cyClient / 20;
                    rc.bottom += cyClient / 20;
                    break;
                default:
            }

            // resize window
            MoveWindow(hwnd, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top, TRUE);
            return 0;

        case WM_DRAWITEM:   // called when a button window wants to be drawn
            // See http://msdn.microsoft.com/en-us/library/bb775802%28v=vs.85%29.aspx,
            // for DRAWITEMSTRUCT definition
            pdis = cast(LPDRAWITEMSTRUCT)lParam;

            // Fill area with white and frame it black
            FillRect(pdis.hDC,  &pdis.rcItem, cast(HBRUSH)GetStockObject(WHITE_BRUSH));
            FrameRect(pdis.hDC, &pdis.rcItem, cast(HBRUSH)GetStockObject(BLACK_BRUSH));

            // Draw inward and outward black triangles
            cx = pdis.rcItem.right  - pdis.rcItem.left;
            cy = pdis.rcItem.bottom - pdis.rcItem.top;

            switch (pdis.CtlID)
            {
                case ID_SMALLER:
                    pt[0].x = 3 * cx / 8;  pt[0].y = 1 * cy / 8;
                    pt[1].x = 5 * cx / 8;  pt[1].y = 1 * cy / 8;
                    pt[2].x = 4 * cx / 8;  pt[2].y = 3 * cy / 8;
                    Triangle(pdis.hDC, pt);

                    pt[0].x = 7 * cx / 8;  pt[0].y = 3 * cy / 8;
                    pt[1].x = 7 * cx / 8;  pt[1].y = 5 * cy / 8;
                    pt[2].x = 5 * cx / 8;  pt[2].y = 4 * cy / 8;
                    Triangle(pdis.hDC, pt);

                    pt[0].x = 5 * cx / 8;  pt[0].y = 7 * cy / 8;
                    pt[1].x = 3 * cx / 8;  pt[1].y = 7 * cy / 8;
                    pt[2].x = 4 * cx / 8;  pt[2].y = 5 * cy / 8;
                    Triangle(pdis.hDC, pt);

                    pt[0].x = 1 * cx / 8;  pt[0].y = 5 * cy / 8;
                    pt[1].x = 1 * cx / 8;  pt[1].y = 3 * cy / 8;
                    pt[2].x = 3 * cx / 8;  pt[2].y = 4 * cy / 8;
                    Triangle(pdis.hDC, pt);
                    break;

                case ID_LARGER:
                    pt[0].x = 5 * cx / 8;  pt[0].y = 3 * cy / 8;
                    pt[1].x = 3 * cx / 8;  pt[1].y = 3 * cy / 8;
                    pt[2].x = 4 * cx / 8;  pt[2].y = 1 * cy / 8;
                    Triangle(pdis.hDC, pt);

                    pt[0].x = 5 * cx / 8;  pt[0].y = 5 * cy / 8;
                    pt[1].x = 5 * cx / 8;  pt[1].y = 3 * cy / 8;
                    pt[2].x = 7 * cx / 8;  pt[2].y = 4 * cy / 8;
                    Triangle(pdis.hDC, pt);

                    pt[0].x = 3 * cx / 8;  pt[0].y = 5 * cy / 8;
                    pt[1].x = 5 * cx / 8;  pt[1].y = 5 * cy / 8;
                    pt[2].x = 4 * cx / 8;  pt[2].y = 7 * cy / 8;
                    Triangle(pdis.hDC, pt);

                    pt[0].x = 3 * cx / 8;  pt[0].y = 3 * cy / 8;
                    pt[1].x = 3 * cx / 8;  pt[1].y = 5 * cy / 8;
                    pt[2].x = 1 * cx / 8;  pt[2].y = 4 * cy / 8;
                    Triangle(pdis.hDC, pt);
                    break;
                default:
            }

            // Invert the rectangle if the button is selected
            if (pdis.itemState & ODS_SELECTED)
                InvertRect(pdis.hDC, &pdis.rcItem);

            // Draw a focus rectangle if the button has the focus
            if (pdis.itemState & ODS_FOCUS)
            {
                pdis.rcItem.left   += cx / 16;
                pdis.rcItem.top    += cy / 16;
                pdis.rcItem.right  -= cx / 16;
                pdis.rcItem.bottom -= cy / 16;

                DrawFocusRect(pdis.hDC, &pdis.rcItem);
            }

            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}


