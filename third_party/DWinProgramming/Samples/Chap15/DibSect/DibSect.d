/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module DibSect;

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

string appName     = "DibSect";
string description = "DIB Section Display";
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

HBITMAP CreateDibSectionFromDibFile(string szFileName)
{
    BITMAPFILEHEADER bmfh;
    BITMAPINFO* pbmi;
    BYTE*   pBits;
    BOOL    bSuccess;
    DWORD   dwInfoSize, dwBytesRead;
    HANDLE  hFile;
    HBITMAP hBitmap;

    // Open the file: read access, prohibit write access
    hFile = CreateFile(szFileName.toUTF16z, GENERIC_READ, FILE_SHARE_READ,
                       NULL, OPEN_EXISTING, 0, NULL);

    if (hFile == INVALID_HANDLE_VALUE)
        return NULL;

    // Read in the BITMAPFILEHEADER
    bSuccess = ReadFile(hFile, &bmfh, BITMAPFILEHEADER.sizeof,
                        &dwBytesRead, NULL);

    if (!bSuccess || (dwBytesRead != BITMAPFILEHEADER.sizeof)
        || (bmfh.bfType != *cast(WORD*) "BM"))
    {
        CloseHandle(hFile);
        return NULL;
    }

    // Allocate memory for the BITMAPINFO structure & read it in
    dwInfoSize = bmfh.bfOffBits - BITMAPFILEHEADER.sizeof;

    pbmi = cast(typeof(pbmi))GC.malloc(dwInfoSize);

    bSuccess = ReadFile(hFile, pbmi, dwInfoSize, &dwBytesRead, NULL);

    if (!bSuccess || (dwBytesRead != dwInfoSize))
    {
        GC.free(pbmi);
        CloseHandle(hFile);
        return NULL;
    }

    // Create the DIB Section

    hBitmap = CreateDIBSection(NULL, pbmi, DIB_RGB_COLORS, cast(void**)&pBits, NULL, 0);

    if (hBitmap == NULL)
    {
        GC.free(pbmi);
        CloseHandle(hFile);
        return NULL;
    }

    // Read in the bitmap bits

    ReadFile(hFile, pBits, bmfh.bfSize - bmfh.bfOffBits, &dwBytesRead, NULL);

    GC.free(pbmi);
    CloseHandle(hFile);

    return hBitmap;
}

__gshared wchar[MAX_PATH] szFileName  = 0;
__gshared wchar[MAX_PATH] szTitleName = 0;
extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HBITMAP hBitmap;
    static int cxClient, cyClient;
    static OPENFILENAME ofn;
    static string szFilter = "Bitmap Files (*.BMP)\0*.bmp\0All Files (*.*)\0*.*\0\0";
    BITMAP bitmap;
    HDC hdc, hdcMem;
    PAINTSTRUCT ps;

    switch (message)
    {
        case WM_CREATE:
            ofn.hwndOwner         = hwnd;
            ofn.hInstance         = NULL;
            ofn.lpstrFilter       = szFilter.toUTF16z;
            ofn.lpstrCustomFilter = NULL;
            ofn.nMaxCustFilter    = 0;
            ofn.nFilterIndex      = 0;
            ofn.lpstrFile         = szFileName.ptr;
            ofn.nMaxFile          = MAX_PATH;
            ofn.lpstrFileTitle    = szTitleName.ptr;
            ofn.nMaxFileTitle     = MAX_PATH;
            ofn.lpstrInitialDir   = NULL;
            ofn.lpstrTitle        = NULL;
            ofn.Flags             = 0;
            ofn.nFileOffset       = 0;
            ofn.nFileExtension    = 0;
            ofn.lpstrDefExt       = "bmp";
            ofn.lCustData         = 0;
            ofn.lpfnHook          = NULL;
            ofn.lpTemplateName    = NULL;

            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_FILE_OPEN:

                    // Show the File Open dialog box

                    if (!GetOpenFileName(&ofn))
                        return 0;

                    // If there's an existing bitmap, delete it

                    if (hBitmap)
                    {
                        DeleteObject(hBitmap);
                        hBitmap = NULL;
                    }

                    // Create the DIB Section from the DIB file

                    SetCursor(LoadCursor(NULL, IDC_WAIT));
                    ShowCursor(TRUE);

                    hBitmap = CreateDibSectionFromDibFile(to!string(szFileName[]));

                    ShowCursor(FALSE);
                    SetCursor(LoadCursor(NULL, IDC_ARROW));

                    // Invalidate the client area for later update

                    InvalidateRect(hwnd, NULL, TRUE);

                    if (hBitmap == NULL)
                    {
                        MessageBox(hwnd, "Cannot load DIB file",
                                   appName.toUTF16z, MB_OK | MB_ICONEXCLAMATION);
                    }

                    return 0;
                    
                default:
            }

            break;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            if (hBitmap)
            {
                GetObject(hBitmap, BITMAP.sizeof, &bitmap);

                hdcMem = CreateCompatibleDC(hdc);
                SelectObject(hdcMem, hBitmap);

                BitBlt(hdc, 0, 0, bitmap.bmWidth, bitmap.bmHeight, hdcMem, 0, 0, SRCCOPY);

                DeleteDC(hdcMem);
            }

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:

            if (hBitmap)
                DeleteObject(hBitmap);

            PostQuitMessage(0);
            return 0;
            
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
