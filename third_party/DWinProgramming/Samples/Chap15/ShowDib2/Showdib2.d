/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Showdib2;

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

string appName     = "Showdib2";
string description = "Show DIB #2";
HINSTANCE hinst;

enum GMEM_SHARE = 8192;

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

int ShowDib(HDC hdc, BITMAPINFO* pbmi, BYTE* pBits, int cxDib, int cyDib,
            int cxClient, int cyClient, WORD wShow)
{
    switch (wShow)
    {
        case IDM_SHOW_NORMAL:
            return SetDIBitsToDevice(hdc, 0, 0, cxDib, cyDib, 0, 0,
                                     0, cyDib, pBits, pbmi, DIB_RGB_COLORS);

        case IDM_SHOW_CENTER:
            return SetDIBitsToDevice(hdc, (cxClient - cxDib) / 2,
                                     (cyClient - cyDib) / 2,
                                     cxDib, cyDib, 0, 0,
                                     0, cyDib, pBits, pbmi, DIB_RGB_COLORS);

        case IDM_SHOW_STRETCH:
            SetStretchBltMode(hdc, COLORONCOLOR);

            return StretchDIBits(hdc, 0, 0, cxClient, cyClient,
                                 0, 0, cxDib, cyDib,
                                 pBits, pbmi, DIB_RGB_COLORS, SRCCOPY);

        case IDM_SHOW_ISOSTRETCH:
            SetStretchBltMode(hdc, COLORONCOLOR);
            SetMapMode(hdc, MM_ISOTROPIC);
            SetWindowExtEx(hdc, cxDib, cyDib, NULL);
            SetViewportExtEx(hdc, cxClient, cyClient, NULL);
            SetWindowOrgEx(hdc, cxDib / 2, cyDib / 2, NULL);
            SetViewportOrgEx(hdc, cxClient / 2, cyClient / 2, NULL);

            return StretchDIBits(hdc, 0, 0, cxDib, cyDib,
                                 0, 0, cxDib, cyDib,
                                 pBits, pbmi, DIB_RGB_COLORS, SRCCOPY);
        
        default:
    }

    return 0;
}

__gshared wchar[MAX_PATH] szFileName  = 0;
__gshared wchar[MAX_PATH] szTitleName = 0;
extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BITMAPFILEHEADER* pbmfh;
    static BITMAPINFO* pbmi;
    static BYTE* pBits;
    static DOCINFO di = DOCINFO(DOCINFO.sizeof, "ShowDib2: Printing");
    static int cxClient, cyClient, cxDib, cyDib;
    static PRINTDLG printdlg = PRINTDLG(PRINTDLG.sizeof);
    static WORD  wShow = IDM_SHOW_NORMAL;
    BOOL bSuccess;
    HDC  hdc, hdcPrn;
    HGLOBAL hGlobal;
    HMENU hMenu;
    int cxPage, cyPage, iEnable;
    PAINTSTRUCT ps;
    ubyte* pGlobal;

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
            hMenu = GetMenu(hwnd);

            if (pbmfh)
                iEnable = MF_ENABLED;
            else
                iEnable = MF_GRAYED;

            EnableMenuItem(hMenu, IDM_FILE_SAVE,   iEnable);
            EnableMenuItem(hMenu, IDM_FILE_PRINT,  iEnable);
            EnableMenuItem(hMenu, IDM_EDIT_CUT,    iEnable);
            EnableMenuItem(hMenu, IDM_EDIT_COPY,   iEnable);
            EnableMenuItem(hMenu, IDM_EDIT_DELETE, iEnable);
            return 0;

        case WM_COMMAND:
            hMenu = GetMenu(hwnd);

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

                    if (pbmfh is null)
                    {
                        MessageBox(hwnd, "Cannot load DIB file",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
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

                    // Save the DIB to a disk file

                    SetCursor(LoadCursor(NULL, IDC_WAIT));
                    ShowCursor(TRUE);

                    bSuccess = DibSaveImage(szFileName.ptr, pbmfh);

                    ShowCursor(FALSE);
                    SetCursor(LoadCursor(NULL, IDC_ARROW));

                    if (!bSuccess)
                        MessageBox(hwnd, "Cannot save DIB file",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);

                    return 0;

                case IDM_FILE_PRINT:

                    if (!pbmfh)
                        return 0;

                    // Get printer DC

                    printdlg.Flags = PD_RETURNDC | PD_NOPAGENUMS | PD_NOSELECTION;

                    if (!PrintDlg(&printdlg))
                        return 0;

                    if (NULL == (hdcPrn = printdlg.hDC))
                    {
                        MessageBox(hwnd, "Cannot obtain Printer DC",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
                        return 0;
                    }

                    // Check if the printer can print bitmaps

                    if (!(RC_BITBLT & GetDeviceCaps(hdcPrn, RASTERCAPS)))
                    {
                        DeleteDC(hdcPrn);
                        MessageBox(hwnd, "Printer cannot print bitmaps",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
                        return 0;
                    }

                    // Get size of printable area of page

                    cxPage = GetDeviceCaps(hdcPrn, HORZRES);
                    cyPage = GetDeviceCaps(hdcPrn, VERTRES);

                    bSuccess = FALSE;

                    // Send the DIB to the printer

                    SetCursor(LoadCursor(NULL, IDC_WAIT));
                    ShowCursor(TRUE);

                    if ((StartDoc(hdcPrn, &di) > 0) && (StartPage(hdcPrn) > 0))
                    {
                        ShowDib(hdcPrn, pbmi, pBits, cxDib, cyDib,
                                cxPage, cyPage, wShow);

                        if (EndPage(hdcPrn) > 0)
                        {
                            bSuccess = TRUE;
                            EndDoc(hdcPrn);
                        }
                    }

                    ShowCursor(FALSE);
                    SetCursor(LoadCursor(NULL, IDC_ARROW));

                    DeleteDC(hdcPrn);

                    if (!bSuccess)
                        MessageBox(hwnd, "Could not print bitmap",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);

                    return 0;

                case IDM_EDIT_COPY:
                case IDM_EDIT_CUT:

                    if (!pbmfh)
                        return 0;

                    // Make a copy of the packed DIB
                    hGlobal = GlobalAlloc(GHND | GMEM_SHARE, pbmfh.bfSize - BITMAPFILEHEADER.sizeof);
                    pGlobal = cast(typeof(pGlobal))GlobalLock(hGlobal);
                    
                    auto newlength = pbmfh.bfSize - BITMAPFILEHEADER.sizeof;
                    pGlobal[0..newlength] = (cast(BYTE*)pbmfh + BITMAPFILEHEADER.sizeof)[0..newlength];
                    GlobalUnlock(hGlobal);;                    
                    
                    // Transfer it to the clipboard
                    OpenClipboard(hwnd);
                    EmptyClipboard();
                    SetClipboardData(CF_DIB, hGlobal);
                    CloseClipboard();

                    if (LOWORD(wParam) == IDM_EDIT_COPY)
                        return 0;

                    goto case IDM_EDIT_DELETE;
                    
                case IDM_EDIT_DELETE:

                    if (pbmfh)
                    {
                        GC.free(pbmfh);
                        pbmfh = NULL;
                        InvalidateRect(hwnd, NULL, TRUE);
                    }

                    return 0;

                case IDM_SHOW_NORMAL:
                case IDM_SHOW_CENTER:
                case IDM_SHOW_STRETCH:
                case IDM_SHOW_ISOSTRETCH:
                    CheckMenuItem(hMenu, wShow, MF_UNCHECKED);
                    wShow = LOWORD(wParam);
                    CheckMenuItem(hMenu, wShow, MF_CHECKED);
                    InvalidateRect(hwnd, NULL, TRUE);
                    return 0;
                
                default:
            }

            break;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            if (pbmfh)
                ShowDib(hdc, pbmi, pBits, cxDib, cyDib,
                        cxClient, cyClient, wShow);

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
