/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module SeqDisp;

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

string appName     = "SeqDisp";
string description = "DIB Sequential Display";
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
    static BITMAPINFO* pbmi;
    static BYTE* pBits;
    static int cxDib, cyDib, cBits;
    static OPENFILENAME ofn;
    static string szFilter = "Bitmap Files (*.BMP)\0*.bmp\0All Files (*.*)\0*.*\0\0";
    BITMAPFILEHEADER bmfh;
    BOOL   bSuccess, bTopDown;
    DWORD  dwBytesRead;
    HANDLE hFile;
    HDC hdc;
    HMENU hMenu;
    int iInfoSize, iBitsSize, iRowLength, y;
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
            ofn.lpstrDefExt       =  "bmp";
            ofn.lCustData         = 0;
            ofn.lpfnHook          = NULL;
            ofn.lpTemplateName    = NULL;
            return 0;

        case WM_COMMAND:
            hMenu = GetMenu(hwnd);

            switch (LOWORD(wParam))
            {
                case IDM_FILE_OPEN:

                    // Display File Open dialog

                    if (!GetOpenFileName(&ofn))
                        return 0;

                    // Get rid of old DIB

                    if (pbmi)
                    {
                        GC.free(pbmi);
                        pbmi = NULL;
                    }

                    if (pBits)
                    {
                        GC.free(pBits);
                        pBits = NULL;
                    }

                    // Generate WM_PAINT message to erase background
                    InvalidateRect(hwnd, NULL, TRUE);
                    UpdateWindow(hwnd);

                    // Open the file
                    hFile = CreateFile(szFileName.ptr, GENERIC_READ,
                                       FILE_SHARE_READ, NULL, OPEN_EXISTING,
                                       FILE_FLAG_SEQUENTIAL_SCAN, NULL);

                    if (hFile == INVALID_HANDLE_VALUE)
                    {
                        MessageBox(hwnd,  "Cannot open file.",
                                   appName.toUTF16z, MB_ICONWARNING | MB_OK);
                        return 0;
                    }

                    // Read in the BITMAPFILEHEADER
                    bSuccess = ReadFile(hFile, &bmfh, BITMAPFILEHEADER.sizeof,
                                        &dwBytesRead, NULL);

                    if (!bSuccess || dwBytesRead != BITMAPFILEHEADER.sizeof)
                    {
                        MessageBox(hwnd,  "Cannot read file.",
                                   appName.toUTF16z, MB_ICONWARNING | MB_OK);
                        CloseHandle(hFile);
                        return 0;
                    }

                    // Check that it's a bitmap
                    if (bmfh.bfType != *cast(WORD*) "BM")
                    {
                        MessageBox(hwnd,  "File is not a bitmap.",
                                   appName.toUTF16z, MB_ICONWARNING | MB_OK);
                        CloseHandle(hFile);
                        return 0;
                    }

                    // Allocate memory for header and bits
                    iInfoSize = bmfh.bfOffBits - BITMAPFILEHEADER.sizeof;
                    iBitsSize = bmfh.bfSize - bmfh.bfOffBits;

                    pbmi  = cast(typeof(pbmi))GC.malloc(iInfoSize);
                    pBits = cast(typeof(pBits))GC.malloc(iBitsSize);

                    if (pbmi == NULL || pBits == NULL)
                    {
                        MessageBox(hwnd,  "Cannot allocate memory.",
                                   appName.toUTF16z, MB_ICONWARNING | MB_OK);

                        if (pbmi)
                            GC.free(pbmi);

                        if (pBits)
                            GC.free(pBits);

                        CloseHandle(hFile);
                        return 0;
                    }

                    // Read in the Information Header

                    bSuccess = ReadFile(hFile, pbmi, iInfoSize,
                                        &dwBytesRead, NULL);

                    if (!bSuccess || cast(int)dwBytesRead != iInfoSize)
                    {
                        MessageBox(hwnd,  "Cannot read file.",
                                   appName.toUTF16z, MB_ICONWARNING | MB_OK);

                        if (pbmi)
                            GC.free(pbmi);

                        if (pBits)
                            GC.free(pBits);

                        CloseHandle(hFile);
                        return 0;
                    }

                    // Get the DIB width and height
                    bTopDown = FALSE;

                    if (pbmi.bmiHeader.biSize == BITMAPCOREHEADER.sizeof)
                    {
                        cxDib = (cast(BITMAPCOREHEADER*)pbmi).bcWidth;
                        cyDib = (cast(BITMAPCOREHEADER*)pbmi).bcHeight;
                        cBits = (cast(BITMAPCOREHEADER*)pbmi).bcBitCount;
                    }
                    else
                    {
                        if (pbmi.bmiHeader.biHeight < 0)
                            bTopDown = TRUE;

                        cxDib =      pbmi.bmiHeader.biWidth;
                        cyDib = abs(pbmi.bmiHeader.biHeight);
                        cBits =      pbmi.bmiHeader.biBitCount;

                        if (pbmi.bmiHeader.biCompression != BI_RGB &&
                            pbmi.bmiHeader.biCompression != BI_BITFIELDS)
                        {
                            MessageBox(hwnd,  "File is compressed.",
                                       appName.toUTF16z, MB_ICONWARNING | MB_OK);

                            if (pbmi)
                                GC.free(pbmi);

                            if (pBits)
                                GC.free(pBits);

                            CloseHandle(hFile);
                            return 0;
                        }
                    }

                    // Get the row length
                    iRowLength = ((cxDib * cBits + 31) & ~31) >> 3;

                    // Read and display
                    SetCursor(LoadCursor(NULL, IDC_WAIT));
                    ShowCursor(TRUE);

                    hdc = GetDC(hwnd);

                    for (y = 0; y < cyDib; y++)
                    {
                        ReadFile(hFile, pBits + y * iRowLength, iRowLength,
                                 &dwBytesRead, NULL);

                        SetDIBitsToDevice(hdc,
                                          0,      // xDst
                                          0,      // yDst
                                          cxDib,  // cxSrc
                                          cyDib,  // cySrc
                                          0,      // xSrc
                                          0,      // ySrc
                                          bTopDown ? cyDib - y - 1 : y,

                                          // first scan line
                                          1,      // number of scan lines
                                          pBits + y * iRowLength,
                                          pbmi,
                                          DIB_RGB_COLORS);
                    }

                    ReleaseDC(hwnd, hdc);
                    CloseHandle(hFile);
                    ShowCursor(FALSE);
                    SetCursor(LoadCursor(NULL, IDC_ARROW));
                    return 0;
                    
                default:
            }

            break;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            if (pbmi && pBits)
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

            if (pbmi)
                GC.free(pbmi);

            if (pBits)
                GC.free(pBits);

            PostQuitMessage(0);
            return 0;
            
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
