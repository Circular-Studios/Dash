/+
 +           Copyright Andrej Mitrovic 2011.
 +  Distributed under the Boost Software License, Version 1.0.
 +     (See accompanying file LICENSE_1_0.txt or copy at
 +           http://www.boost.org/LICENSE_1_0.txt)
 +
 + Demonstrates alpha-blending.
 +/

module AlphaBlend;

import core.memory;
import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.utf;

auto toUTF16z(S) (S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;

extern (Windows) BOOL GdiAlphaBlend(HDC, int, int, int, int, HDC, int, int, int, int, BLENDFUNCTION);

string appName     = "AlphaBlend";
string description = "AlphaBlend Demo";
HINSTANCE hinst;

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

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    hinst = hInstance;
    HACCEL hAccel;
    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    wndclass.style       = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc = &WndProc;
    wndclass.cbClsExtra  = 0;
    wndclass.cbWndExtra  = 0;
    wndclass.hInstance   = hInstance;
    wndclass.hIcon       = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor     = LoadCursor(NULL, IDC_ARROW);

    //~ wndclass.hbrBackground = cast(HBRUSH) GetStockObject(WHITE_BRUSH);
    wndclass.hbrBackground = null;  // don't send WM_ERASEBKND messages

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
    static int cxClient, cyClient, cxSource, cySource;
    int x, y;
    HDC hdc;
    PAINTSTRUCT ps;

    static HDC hdcMem;
    static HBITMAP hbmMem;
    static HANDLE  hOld;
    RECT rect;

    switch (message)
    {
        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        // When you set 'hbrBackground = null' it prevents
        // the WM_ERASEBKND message to be sent.
        case WM_ERASEBKGND:
            return 1;

        case WM_PAINT:
        {
            // Get DC for window
            hdc = BeginPaint(hwnd, &ps);

            //~ // Create an off-screen DC for double-buffering
            hdcMem = CreateCompatibleDC(hdc);
            hbmMem = CreateCompatibleBitmap(hdc, cxClient, cyClient);
            hOld   = SelectObject(hdcMem, hbmMem);

            // Draw into hdcMem
            GetClientRect(hwnd, &rect);
            FillRect(hdcMem, &rect, GetStockObject(BLACK_BRUSH));

            rect.left   += 10;
            rect.top    += 10;
            rect.right  -= 10;
            rect.bottom -= 10;
            FillRect(hdcMem, &rect, GetStockObject(WHITE_BRUSH));

            DrawAlphaBlend(hwnd, hdcMem);

            // Transfer the off-screen DC to the screen
            BitBlt(hdc, 0, 0, cxClient, cyClient, hdcMem, 0, 0, SRCCOPY);

            // Free-up the off-screen DC
            SelectObject(hdcMem, hOld);
            DeleteObject(hbmMem);
            DeleteDC(hdcMem);

            EndPaint(hwnd, &ps);
            return 0;
        }

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

void DrawAlphaBlend(HWND hWnd, HDC hdcwnd)
{
    HDC hdc;                              // handle of the DC we will create
    BLENDFUNCTION bf;                     // structure for alpha blending
    HBITMAP hbitmap;                      // bitmap handle
    BITMAPINFO bmi;                       // bitmap header
    VOID*  pvBits;                        // pointer to DIB section
    ULONG  ulWindowWidth, ulWindowHeight; // window width/height
    ULONG  ulBitmapWidth, ulBitmapHeight; // bitmap width/height
    RECT   rt;                            // used for getting window dimensions
    UINT32 x, y;                          // stepping variables
    UCHAR  ubAlpha;                       // used for doing transparent gradient
    UCHAR  ubRed;
    UCHAR  ubGreen;
    UCHAR  ubBlue;
    float  fAlphaFactor = 0;   // used to do premultiply

    // get window dimensions
    GetClientRect(hWnd, &rt);

    // calculate window width/height
    ulWindowWidth  = rt.right - rt.left;
    ulWindowHeight = rt.bottom - rt.top;

    // make sure we have at least some window size
    if (ulWindowWidth < 1 || ulWindowHeight < 1)
        return;

    // divide the window into 3 horizontal areas
    ulWindowHeight = ulWindowHeight / 3;

    // create a DC for our bitmap -- the source DC for GdiAlphaBlend
    hdc = CreateCompatibleDC(hdcwnd);

    // setup bitmap info
    // set the bitmap width and height to 60% of the width and height of each of the three horizontal areas. Later on, the blending will occur in the center of each of the three areas.
    bmi.bmiHeader.biSize        = BITMAPINFOHEADER.sizeof;
    bmi.bmiHeader.biWidth       = ulBitmapWidth = ulWindowWidth - (ulWindowWidth / 5) * 2;
    bmi.bmiHeader.biHeight      = ulBitmapHeight = ulWindowHeight - (ulWindowHeight / 5) * 2;
    bmi.bmiHeader.biPlanes      = 1;
    bmi.bmiHeader.biBitCount    = 32;      // four 8-bit components
    bmi.bmiHeader.biCompression = BI_RGB;
    bmi.bmiHeader.biSizeImage   = ulBitmapWidth * ulBitmapHeight * 4;

    // create our DIB section and select the bitmap into the dc
    hbitmap = CreateDIBSection(hdc, &bmi, DIB_RGB_COLORS, &pvBits, NULL, 0x0);
    SelectObject(hdc, hbitmap);

    // in top window area, constant alpha = 50%, but no source alpha
    // the color format for each pixel is 0xaarrggbb
    // set all pixels to blue and set source alpha to zero
    for (y = 0; y < ulBitmapHeight; y++)
        for (x = 0; x < ulBitmapWidth; x++)
            (cast(UINT32*)pvBits)[x + y * ulBitmapWidth] = 0x000000ff;

    bf.BlendOp    = AC_SRC_OVER;
    bf.BlendFlags = 0;
    bf.SourceConstantAlpha = 0x7f;  // half of 0xff = 50% transparency
    bf.AlphaFormat         = 0;     // ignore source alpha channel

    if (!GdiAlphaBlend(hdcwnd, ulWindowWidth / 5, ulWindowHeight / 5,
                       ulBitmapWidth, ulBitmapHeight,
                       hdc, 0, 0, ulBitmapWidth, ulBitmapHeight, bf))
        return;                     // alpha blend failed

    // in middle window area, constant alpha = 100% (disabled), source
    // alpha is 0 in middle of bitmap and opaque in rest of bitmap
    for (y = 0; y < ulBitmapHeight; y++)
    {
        for (x = 0; x < ulBitmapWidth; x++)
        {
            if ((x > cast(int)(ulBitmapWidth / 5)) && (x < (ulBitmapWidth - ulBitmapWidth / 5)) &&
                (y > cast(int)(ulBitmapHeight / 5)) && (y < (ulBitmapHeight - ulBitmapHeight / 5)))
                //in middle of bitmap: source alpha = 0 (transparent).
                // This means multiply each color component by 0x00.
                // Thus, after GdiAlphaBlend, we have a, 0x00 * r,
                // 0x00 * g,and 0x00 * b (which is 0x00000000)
                // for now, set all pixels to red
                (cast(UINT32*)pvBits)[x + y * ulBitmapWidth] = 0x00ff0000;
            else
                // in the rest of bitmap, source alpha = 0xff (opaque)
                // and set all pixels to blue
                (cast(UINT32*)pvBits)[x + y * ulBitmapWidth] = 0xff0000ff;
        }
    }

    bf.BlendOp             = AC_SRC_OVER;
    bf.BlendFlags          = 0;
    bf.AlphaFormat         = AC_SRC_ALPHA; // use source alpha
    bf.SourceConstantAlpha = 0xff;         // opaque (disable constant alpha)

    if (!GdiAlphaBlend(hdcwnd, ulWindowWidth / 5, ulWindowHeight / 5 + ulWindowHeight, ulBitmapWidth, ulBitmapHeight, hdc, 0, 0, ulBitmapWidth, ulBitmapHeight, bf))
        return;

    // bottom window area, use constant alpha = 75% and a changing
    // source alpha. Create a gradient effect using source alpha, and
    // then fade it even more with constant alpha
    ubRed   = 0x00;
    ubGreen = 0x00;
    ubBlue  = 0xff;

    for (y = 0; y < ulBitmapHeight; y++)
    {
        for (x = 0; x < ulBitmapWidth; x++)
        {
            // for a simple gradient, base the alpha value on the x
            // value of the pixel
            ubAlpha = cast(UCHAR)(cast(float)x / cast(float)ulBitmapWidth * 255);

            //calculate the factor by which we multiply each component
            fAlphaFactor = cast(float)ubAlpha / cast(float)0xff;

            // multiply each pixel by fAlphaFactor, so each component
            // is less than or equal to the alpha value.
            (cast(UINT32*)pvBits)[x + y * ulBitmapWidth]
                = (ubAlpha << 24) |                            //0xaa000000
                  (cast(UCHAR)(ubRed * fAlphaFactor) << 16) |  //0x00rr0000
                  (cast(UCHAR)(ubGreen * fAlphaFactor) << 8) | //0x0000gg00
                  (cast(UCHAR)(ubBlue * fAlphaFactor));        //0x000000bb
        }
    }



    bf.BlendOp             = AC_SRC_OVER;
    bf.BlendFlags          = 0;
    bf.AlphaFormat         = AC_SRC_ALPHA; // use source alpha
    bf.SourceConstantAlpha = 0xbf;         // use constant alpha, with
                                           // 75% opaqueness

    GdiAlphaBlend(hdcwnd, ulWindowWidth / 5,
                  ulWindowHeight / 5 + 2 * ulWindowHeight, ulBitmapWidth,
                  ulBitmapHeight, hdc, 0, 0, ulBitmapWidth,
                  ulBitmapHeight, bf);

    // do cleanup
    DeleteObject(hbitmap);
    DeleteDC(hdc);
}
