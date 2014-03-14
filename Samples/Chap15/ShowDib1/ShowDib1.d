/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module ShowDib1;

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
import DibFile;

string appName     = "ShowDib1";
string description = "Show DIB #1";
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

__gshared wchar[MAX_PATH] szFileName  = 0;
__gshared wchar[MAX_PATH] szTitleName = 0;

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BITMAPFILEHEADER* pbmfh;
    static BITMAPINFO* pbmi;
    static BYTE* pBits;
    static int cxClient, cyClient, cxDib, cyDib;
    BOOL bSuccess;
    HDC  hdc;
    PAINTSTRUCT ps;

    switch (message)
    {
        case WM_CREATE:
            DibFileInitialize(hwnd);
            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_INITMENUPOPUP:
            EnableMenuItem(cast(HMENU)wParam, IDM_FILE_SAVE,
                           pbmfh ? MF_ENABLED : MF_GRAYED);
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_FILE_OPEN:

                    // Show the File Open dialog box

                    if (!DibFileOpenDlg(hwnd, szFileName.ptr, szTitleName.ptr))
                        return 0;

                    // If there's an existing DIB, GC.free the memory

                    if (pbmfh)
                    {
                        GC.free(pbmfh);
                        pbmfh = NULL;
                    }

                    // Load the entire DIB into memory
                    SetCursor(LoadCursor(NULL, IDC_WAIT));
                    ShowCursor(TRUE);

                    pbmfh = DibLoadImage(to!string(szFileName[]));

                    ShowCursor(FALSE);
                    SetCursor(LoadCursor(NULL, IDC_ARROW));

                    // Invalidate the client area for later update

                    InvalidateRect(hwnd, NULL, TRUE);

                    if (pbmfh == NULL)
                    {
                        MessageBox(hwnd, "Cannot load DIB file",
                                   appName.toUTF16z, 0);
                        return 0;
                    }

                    // Get pointers to the info structure & the bits
                    pbmi  = cast(BITMAPINFO*)(pbmfh + 1);
                    pBits = cast(BYTE*)pbmfh + pbmfh.bfOffBits;

                    // Get the DIB width and height
                    if (pbmi.bmiHeader.biSize == BITMAPCOREHEADER.sizeof)
                    {
                        cxDib = (cast(BITMAPCOREHEADER*)pbmi).bcWidth;
                        cyDib = (cast(BITMAPCOREHEADER*)pbmi).bcHeight;
                    }
                    else
                    {
                        cxDib =      pbmi.bmiHeader.biWidth;
                        cyDib = abs(pbmi.bmiHeader.biHeight);
                    }

                    return 0;

                case IDM_FILE_SAVE:

                    // Show the File Save dialog box

                    if (!DibFileSaveDlg(hwnd, szFileName.ptr, szTitleName.ptr))
                        return 0;

                    // Save the DIB to memory

                    SetCursor(LoadCursor(NULL, IDC_WAIT));
                    ShowCursor(TRUE);

                    bSuccess = DibSaveImage(szFileName.ptr, pbmfh);

                    ShowCursor(FALSE);
                    SetCursor(LoadCursor(NULL, IDC_ARROW));

                    if (!bSuccess)
                        MessageBox(hwnd, "Cannot save DIB file",
                                   appName.toUTF16z, 0);

                    return 0;

                default:
            }

            break;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            if (pbmfh)
                SetDIBitsToDevice(hdc,
                                  0,         // xDst
                                  0,         // yDst
                                  cxDib,     // cxSrc
                                  cyDib,     // cySrc
                                  0,         // xSrc
                                  0,         // ySrc
                                  0,         // first scan line
                                  cyDib,     // number of scan lines
                                  pBits,
                                  pbmi,
                                  DIB_RGB_COLORS);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:

            if (pbmfh)
                GC.free(pbmfh);

            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
