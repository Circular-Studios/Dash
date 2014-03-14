/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Apollo11;

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

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;

import DibFile;

string appName     = "Apollo11";
string description = "Apollo 11";
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

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BITMAPFILEHEADER *[2] pbmfh;
    static BITMAPINFO       *[2] pbmi;
    static BYTE             *[2] pBits;
    static int cxClient, cyClient;
    static int[2] cxDib, cyDib;
    HDC hdc;
    PAINTSTRUCT ps;

    switch (message)
    {
        case WM_CREATE:
            pbmfh[0] = DibLoadImage("Apollo11.bmp");
            pbmfh[1] = DibLoadImage("ApolloTD.bmp");

            if (pbmfh[0] == NULL || pbmfh[1] == NULL)
            {
                MessageBox(hwnd, "Cannot load DIB file", appName.toUTF16z, 0);
                return 0;
            }

            // Get pointers to the info structure && the bits
            pbmi  [0] = cast(BITMAPINFO *)(pbmfh[0] + 1);
            pbmi  [1] = cast(BITMAPINFO *)(pbmfh[1] + 1);

            pBits [0] = cast(BYTE *)pbmfh[0] + pbmfh[0].bfOffBits;
            pBits [1] = cast(BYTE *)pbmfh[1] + pbmfh[1].bfOffBits;

            // Get the DIB width and height (assume BITMAPINFOHEADER)
            // Note that cyDib is the absolute value of the header value!!!
            cxDib [0] = pbmi[0].bmiHeader.biWidth;
            cxDib [1] = pbmi[1].bmiHeader.biWidth;

            cyDib [0] = abs(pbmi[0].bmiHeader.biHeight);
            cyDib [1] = abs(pbmi[1].bmiHeader.biHeight);
            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            // Bottom-up DIB full size

            SetDIBitsToDevice(hdc,
                              0,                  // xDst
                              cyClient / 4,       // yDst
                              cxDib[0],           // cxSrc
                              cyDib[0],           // cySrc
                              0,                  // xSrc
                              0,                  // ySrc
                              0,                  // first scan line
                              cyDib[0],           // number of scan lines
                              pBits[0],
                              pbmi[0],
                              DIB_RGB_COLORS);

            // Bottom-up DIB partial

            SetDIBitsToDevice(hdc,
                              240,                // xDst
                              cyClient / 4,       // yDst
                              80,                 // cxSrc
                              166,                // cySrc
                              80,                 // xSrc
                              60,                 // ySrc
                              0,                  // first scan line
                              cyDib[0],           // number of scan lines
                              pBits[0],
                              pbmi[0],
                              DIB_RGB_COLORS);

            // Top-down DIB full size

            SetDIBitsToDevice(hdc,
                              340,                // xDst
                              cyClient / 4,       // yDst
                              cxDib[0],           // cxSrc
                              cyDib[0],           // cySrc
                              0,                  // xSrc
                              0,                  // ySrc
                              0,                  // first scan line
                              cyDib[0],           // number of scan lines
                              pBits[0],
                              pbmi[0],
                              DIB_RGB_COLORS);

            // Top-down DIB partial

            SetDIBitsToDevice(hdc,
                              580,                // xDst
                              cyClient / 4,       // yDst
                              80,                 // cxSrc
                              166,                // cySrc
                              80,                 // xSrc
                              60,                 // ySrc
                              0,                  // first scan line
                              cyDib[1],           // number of scan lines
                              pBits[1],
                              pbmi[1],
                              DIB_RGB_COLORS);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:

            if (pbmfh[0])
                GC.free(pbmfh[0]);

            if (pbmfh[1])
                GC.free(pbmfh[1]);

            PostQuitMessage(0);
            return 0;
            
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
