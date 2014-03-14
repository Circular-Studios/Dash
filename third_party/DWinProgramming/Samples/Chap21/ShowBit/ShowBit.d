module ShowBit;

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

string appName     = "ShowBit";
string description = "Show Bitmaps from BITLIB (Press Key)";
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

void DrawBitmap(HDC hdc, int xStart, int yStart, HBITMAP hBitmap)
{
    BITMAP bm;
    HDC hMemDC;
    POINT pt;

    hMemDC = CreateCompatibleDC(hdc);
    SelectObject(hMemDC, hBitmap);
    GetObject(hBitmap, BITMAP.sizeof, &bm);
    pt.x = bm.bmWidth;
    pt.y = bm.bmHeight;

    BitBlt(hdc, xStart, yStart, pt.x, pt.y, hMemDC, 0, 0, SRCCOPY);

    DeleteDC(hMemDC);
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HINSTANCE hLibrary;
    static ushort iCurrent = 1;
    HBITMAP hBitmap;
    HDC hdc;
    PAINTSTRUCT ps;

    switch (message)
    {
        case WM_CREATE:

            hLibrary = LoadLibrary("BITLIB.DLL");
            if (hLibrary is null)
            {
                MessageBox(hwnd, "Can't load BITLIB.DLL.", appName.toUTF16z, 0);
                return -1;
            }

            return 0;

        case WM_CHAR:

            if (hLibrary)
            {
                iCurrent++;
                InvalidateRect(hwnd, NULL, TRUE);
            }

            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            if (hLibrary)
            {
                hBitmap = LoadBitmap(hLibrary, MAKEINTRESOURCE(iCurrent));

                if (hBitmap is null)
                {
                    iCurrent = 1;
                    hBitmap  = LoadBitmap(hLibrary, MAKEINTRESOURCE(iCurrent));
                }

                if (hBitmap !is null)
                {
                    DrawBitmap(hdc, 0, 0, hBitmap);
                    DeleteObject(hBitmap);
                }
            }

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:

            if (hLibrary)
                FreeLibrary(hLibrary);

            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
