/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module DibHeads;

import core.memory;
import core.runtime;
import core.thread;
import std.algorithm : min, max;
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

string appName     = "DibHeads";
string description = "DIB Headers";
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

enum WINVER = 0x0500;   // ?

void hwndPrint(A, B, C...)(A hwnd, B szFormat, C values)
{
    static if (C.length < 1)
    {
        string szBuffer = szFormat;
    }
    else
    {
        string szBuffer = format(szFormat, values);
    }

    SendMessage (hwnd, EM_SETSEL, cast(WPARAM) -1, cast(LPARAM) -1);
    SendMessage (hwnd, EM_REPLACESEL, FALSE, cast(LPARAM)szBuffer.toUTF16z);
    SendMessage (hwnd, EM_SCROLLCARET, 0, 0);            
    
}

void DisplayDibHeaders(HWND hwnd, string szFileName)
{
    static string[] szInfoName = ["BITMAPCOREHEADER",
                                  "BITMAPINFOHEADER",
                                  "BITMAPV4HEADER",
                                  "BITMAPV5HEADER"];
    
    static string[] szCompression = ["BI_RGB", "BI_RLE8",
                                      "BI_RLE4",
                                      "BI_BITFIELDS",
                                      "unknown"];
    BITMAPCOREHEADER* pbmch;
    BITMAPFILEHEADER* pbmfh;
    BITMAPV5HEADER* pbmih;
    BOOL   bSuccess;
    DWORD  dwFileSize, dwHighSize, dwBytesRead;
    HANDLE hFile;
    int i;
    PBYTE  pFile;
    TCHAR* szV;

    // Display the file name
    hwndPrint(hwnd, "File: %s\r\n\r\n", szFileName);

    // Open the file
    hFile = CreateFile(szFileName.toUTF16z, GENERIC_READ, FILE_SHARE_READ, NULL,
                       OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL);

    if (hFile == INVALID_HANDLE_VALUE)
    {
        hwndPrint(hwnd, "Cannot open file.\r\n\r\n");
        return;
    }

    // Get the size of the file
    dwFileSize = GetFileSize(hFile, &dwHighSize);

    if (dwHighSize)
    {
        hwndPrint(hwnd, "Cannot deal with >4G files.\r\n\r\n");
        CloseHandle(hFile);
        return;
    }

    // Allocate memory for the file
    pFile = cast(typeof(pFile))GC.malloc(dwFileSize);

    if (!pFile)
    {
        hwndPrint(hwnd, "Cannot allocate memory.\r\n\r\n");
        CloseHandle(hFile);
        return;
    }

    // Read the file
    SetCursor(LoadCursor(NULL, IDC_WAIT));
    ShowCursor(TRUE);

    bSuccess = ReadFile(hFile, pFile, dwFileSize, &dwBytesRead, NULL);

    ShowCursor(FALSE);
    SetCursor(LoadCursor(NULL, IDC_ARROW));

    if (!bSuccess || (dwBytesRead != dwFileSize))
    {
        hwndPrint(hwnd, "Could not read file.\r\n\r\n");
        CloseHandle(hFile);
        GC.free(pFile);
        return;
    }

    // Close the file
    CloseHandle(hFile);

    // Display file size
    hwndPrint(hwnd, "File size = %s bytes\r\n\r\n", dwFileSize);

    // Display BITMAPFILEHEADER structure
    pbmfh = cast(BITMAPFILEHEADER*)pFile;

    hwndPrint(hwnd, "BITMAPFILEHEADER\r\n");
    hwndPrint(hwnd, "\t.bfType = 0x%x\r\n", pbmfh.bfType);
    hwndPrint(hwnd, "\t.bfSize = %s\r\n", pbmfh.bfSize);
    hwndPrint(hwnd, "\t.bfReserved1 = %s\r\n", pbmfh.bfReserved1);
    hwndPrint(hwnd, "\t.bfReserved2 = %s\r\n", pbmfh.bfReserved2);
    hwndPrint(hwnd, "\t.bfOffBits = %s\r\n\r\n", pbmfh.bfOffBits);

    // Determine which information structure we have
    pbmih = cast(BITMAPV5HEADER*)(pFile + BITMAPFILEHEADER.sizeof);

    switch (pbmih.bV5Size)
    {
        case BITMAPCOREHEADER.sizeof:
            i = 0;                       
            break;

        case BITMAPINFOHEADER.sizeof:
            i = 1;  
            szV = "i"w.dup.ptr;  
            break;

        case BITMAPV4HEADER.sizeof:
            i = 2;  
            szV = "V4"w.dup.ptr;  
            break;

        case BITMAPV5HEADER.sizeof:
            i = 3;  
            szV = "V5"w.dup.ptr;  
            break;

        default:
            hwndPrint(hwnd, "Unknown header size of %s.\r\n\r\n", pbmih.bV5Size);
            GC.free(pFile);
            return;
    }

    hwndPrint(hwnd, "%s\r\n", szInfoName[i]);

    // Display the BITMAPCOREHEADER fields

    if (pbmih.bV5Size == BITMAPCOREHEADER.sizeof)
    {
        pbmch = cast(BITMAPCOREHEADER*)pbmih;

        hwndPrint(hwnd, "\t.bcSize = %s\r\n", pbmch.bcSize);
        hwndPrint(hwnd, "\t.bcWidth = %s\r\n", pbmch.bcWidth);
        hwndPrint(hwnd, "\t.bcHeight = %s\r\n", pbmch.bcHeight);
        hwndPrint(hwnd, "\t.bcPlanes = %s\r\n", pbmch.bcPlanes);
        hwndPrint(hwnd, "\t.bcBitCount = %s\r\n\r\n", pbmch.bcBitCount);
        GC.free(pFile);
        return;
    }

    // Display the BITMAPINFOHEADER fields

    hwndPrint(hwnd, "\t.b%sSize = %s\r\n", szV, pbmih.bV5Size);
    hwndPrint(hwnd, "\t.b%sWidth = %s\r\n", szV, pbmih.bV5Width);
    hwndPrint(hwnd, "\t.b%sHeight = %s\r\n", szV, pbmih.bV5Height);
    hwndPrint(hwnd, "\t.b%sPlanes = %s\r\n", szV, pbmih.bV5Planes);
    hwndPrint(hwnd, "\t.b%sBitCount = %s\r\n", szV, pbmih.bV5BitCount);
    hwndPrint(hwnd, "\t.b%sCompression = %s\r\n", szV,
           szCompression [min(4, pbmih.bV5Compression)]);

    hwndPrint(hwnd, "\t.b%sSizeImage = %s\r\n", szV, pbmih.bV5SizeImage);
    hwndPrint(hwnd, "\t.b%sXPelsPerMeter = %s\r\n", szV,
           pbmih.bV5XPelsPerMeter);
    hwndPrint(hwnd, "\t.b%sYPelsPerMeter = %s\r\n", szV,
           pbmih.bV5YPelsPerMeter);
    hwndPrint(hwnd, "\t.b%sClrUsed = %s\r\n", szV, pbmih.bV5ClrUsed);
    hwndPrint(hwnd, "\t.b%sClrImportant = %s\r\n\r\n", szV,
           pbmih.bV5ClrImportant);

    if (pbmih.bV5Size == BITMAPINFOHEADER.sizeof)
    {
        if (pbmih.bV5Compression == BI_BITFIELDS)
        {
            hwndPrint(hwnd, "Red Mask   = %08x\r\n",
                   pbmih.bV5RedMask);
            hwndPrint(hwnd, "Green Mask = %08x\r\n",
                   pbmih.bV5GreenMask);
            hwndPrint(hwnd, "Blue Mask  = %08x\r\n\r\n",
                   pbmih.bV5BlueMask);
        }

        GC.free(pFile);
        return;
    }

    // Display additional BITMAPV4HEADER fields
    hwndPrint(hwnd, "\t.b%sRedMask   = %08x\r\n", szV,
           pbmih.bV5RedMask);
    hwndPrint(hwnd, "\t.b%sGreenMask = %08x\r\n", szV,
           pbmih.bV5GreenMask);
    hwndPrint(hwnd, "\t.b%sBlueMask  = %08x\r\n", szV,
           pbmih.bV5BlueMask);
    hwndPrint(hwnd, "\t.b%sAlphaMask = %08x\r\n", szV,
           pbmih.bV5AlphaMask);
    hwndPrint(hwnd, "\t.b%sCSType = %s\r\n", szV,
           pbmih.bV5CSType);
    hwndPrint(hwnd, "\t.b%sEndpoints.ciexyzRed.ciexyzX   = %08x\r\n", szV,
           pbmih.bV5Endpoints.ciexyzRed.ciexyzX);
    hwndPrint(hwnd, "\t.b%sEndpoints.ciexyzRed.ciexyzY   = %08x\r\n", szV,
           pbmih.bV5Endpoints.ciexyzRed.ciexyzY);
    hwndPrint(hwnd, "\t.b%sEndpoints.ciexyzRed.ciexyzZ   = %08x\r\n", szV,
           pbmih.bV5Endpoints.ciexyzRed.ciexyzZ);
    hwndPrint(hwnd, "\t.b%sEndpoints.ciexyzGreen.ciexyzX = %08x\r\n", szV,
           pbmih.bV5Endpoints.ciexyzGreen.ciexyzX);
    hwndPrint(hwnd, "\t.b%sEndpoints.ciexyzGreen.ciexyzY = %08x\r\n", szV,
           pbmih.bV5Endpoints.ciexyzGreen.ciexyzY);
    hwndPrint(hwnd, "\t.b%sEndpoints.ciexyzGreen.ciexyzZ = %08x\r\n", szV,
           pbmih.bV5Endpoints.ciexyzGreen.ciexyzZ);
    hwndPrint(hwnd, "\t.b%sEndpoints.ciexyzBlue.ciexyzX  = %08x\r\n", szV,
           pbmih.bV5Endpoints.ciexyzBlue.ciexyzX);
    hwndPrint(hwnd, "\t.b%sEndpoints.ciexyzBlue.ciexyzY  = %08x\r\n", szV,
           pbmih.bV5Endpoints.ciexyzBlue.ciexyzY);
    hwndPrint(hwnd, "\t.b%sEndpoints.ciexyzBlue.ciexyzZ  = %08x\r\n", szV,
           pbmih.bV5Endpoints.ciexyzBlue.ciexyzZ);
    hwndPrint(hwnd, "\t.b%sGammaRed   = %08x\r\n", szV,
           pbmih.bV5GammaRed);
    hwndPrint(hwnd, "\t.b%sGammaGreen = %08x\r\n", szV,
           pbmih.bV5GammaGreen);
    hwndPrint(hwnd, "\t.b%sGammaBlue  = %08x\r\n\r\n", szV,
           pbmih.bV5GammaBlue);

    if (pbmih.bV5Size == BITMAPV4HEADER.sizeof)
    {
        GC.free(pFile);
        return;
    }

    // Display additional BITMAPV5HEADER fields

    hwndPrint(hwnd, "\t.b%sIntent = %s\r\n", szV, pbmih.bV5Intent);
    hwndPrint(hwnd, "\t.b%sProfileData = %s\r\n", szV,
           pbmih.bV5ProfileData);
    hwndPrint(hwnd, "\t.b%sProfileSize = %s\r\n", szV,
           pbmih.bV5ProfileSize);
    hwndPrint(hwnd, "\t.b%sReserved = %s\r\n\r\n", szV,
           pbmih.bV5Reserved);

    GC.free(pFile);
    return;
}

__gshared wchar[MAX_PATH] szFileName  = 0;
__gshared wchar[MAX_PATH] szTitleName = 0;

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HWND hwndEdit;
    static OPENFILENAME ofn;
    static string szFilter = "Bitmap Files (*.BMP)\0*.bmp\0All Files (*.*)\0*.*\0\0";

    switch (message)
    {
        case WM_CREATE:
            hwndEdit = CreateWindow("edit", NULL,
                                    WS_CHILD | WS_VISIBLE | WS_BORDER |
                                    WS_VSCROLL | WS_HSCROLL |
                                    ES_MULTILINE | ES_AUTOVSCROLL | ES_READONLY,
                                    0, 0, 0, 0, hwnd, cast(HMENU) 1,
                                    (cast(LPCREATESTRUCT)lParam).hInstance, NULL);

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
            MoveWindow(hwndEdit, 0, 0, LOWORD(lParam), HIWORD(lParam), TRUE);
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_FILE_OPEN:

                    if (GetOpenFileName(&ofn))
                        DisplayDibHeaders(hwndEdit, to!string(szFileName[]));

                    return 0;
                    
                default:
            }

            break;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
