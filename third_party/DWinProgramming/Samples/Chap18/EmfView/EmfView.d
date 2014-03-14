/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module EmfView;

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

string appName     = "EmfView";
string description = "Enhanced Metafile Viewer";
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

    hAccel = LoadAccelerators(hInstance, appName.toUTF16z);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        if (!TranslateAccelerator(hwnd, hAccel, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return msg.wParam;
}

HPALETTE CreatePaletteFromMetaFile(HENHMETAFILE hemf)
{
    HPALETTE hPalette;
    int iNum;
    LOGPALETTE* plp;

    if (!hemf)
        return NULL;

    if (0 == (iNum = GetEnhMetaFilePaletteEntries(hemf, 0, NULL)))
        return NULL;

    plp = cast(typeof(plp))GC.malloc(LOGPALETTE.sizeof + (iNum - 1) * PALETTEENTRY.sizeof);

    plp.palVersion    = 0x0300;
    plp.palNumEntries = cast(ushort)iNum;  // hmm

    GetEnhMetaFilePaletteEntries(hemf, iNum, plp.palPalEntry.ptr);

    hPalette = CreatePalette(plp);

    GC.free(plp);

    return hPalette;
}

__gshared wchar[MAX_PATH] szFileName  = 0;
__gshared wchar[MAX_PATH] szTitleName = 0;

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static DOCINFO di = DOCINFO(DOCINFO.sizeof, "EmfView: Printing");
    static HENHMETAFILE hemf;
    static OPENFILENAME ofn;
    static PRINTDLG printdlg = PRINTDLG(PRINTDLG.sizeof);
    static string szFilter = "Enhanced Metafiles (*.EMF)\0*.emf\0All Files (*.*)\0*.*\0\0";
    BOOL bSuccess;
    ENHMETAHEADER header;
    HDC hdc, hdcPrn;
    HENHMETAFILE hemfCopy;
    HMENU hMenu;
    HPALETTE hPalette;
    int i, iLength, iEnable;
    PAINTSTRUCT ps;
    RECT  rect;
    PTSTR pBuffer;

    switch (message)
    {
        case WM_CREATE:

            // Initialize OPENFILENAME structure
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
            ofn.lpstrDefExt       = "emf";
            ofn.lCustData         = 0;
            ofn.lpfnHook          = NULL;
            ofn.lpTemplateName    = NULL;
            return 0;

        case WM_INITMENUPOPUP:
            hMenu = GetMenu(hwnd);

            iEnable = hemf ? MF_ENABLED : MF_GRAYED;

            EnableMenuItem(hMenu, IDM_FILE_SAVE_AS,    iEnable);
            EnableMenuItem(hMenu, IDM_FILE_PRINT,      iEnable);
            EnableMenuItem(hMenu, IDM_FILE_PROPERTIES, iEnable);
            EnableMenuItem(hMenu, IDM_EDIT_CUT,        iEnable);
            EnableMenuItem(hMenu, IDM_EDIT_COPY,       iEnable);
            EnableMenuItem(hMenu, IDM_EDIT_DELETE,     iEnable);

            EnableMenuItem(hMenu, IDM_EDIT_PASTE,
                           IsClipboardFormatAvailable(CF_ENHMETAFILE) ?
                           MF_ENABLED : MF_GRAYED);
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_FILE_OPEN:

                    // Show the File Open dialog box

                    ofn.Flags = 0;

                    if (!GetOpenFileName(&ofn))
                        return 0;

                    // If there's an existing EMF, get rid of it.

                    if (hemf)
                    {
                        DeleteEnhMetaFile(hemf);
                        hemf = NULL;
                    }

                    // Load the EMF into memory

                    SetCursor(LoadCursor(NULL, IDC_WAIT));
                    ShowCursor(TRUE);

                    hemf = GetEnhMetaFile(szFileName.ptr);

                    ShowCursor(FALSE);
                    SetCursor(LoadCursor(NULL, IDC_ARROW));

                    // Invalidate the client area for later update

                    InvalidateRect(hwnd, NULL, TRUE);

                    if (hemf == NULL)
                    {
                        MessageBox(hwnd, "Cannot load metafile",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
                    }

                    return 0;

                case IDM_FILE_SAVE_AS:

                    if (!hemf)
                        return 0;

                    // Show the File Save dialog box

                    ofn.Flags = OFN_OVERWRITEPROMPT;

                    if (!GetSaveFileName(&ofn))
                        return 0;

                    // Save the EMF to disk file

                    SetCursor(LoadCursor(NULL, IDC_WAIT));
                    ShowCursor(TRUE);

                    hemfCopy = CopyEnhMetaFile(hemf, szFileName.ptr);

                    ShowCursor(FALSE);
                    SetCursor(LoadCursor(NULL, IDC_ARROW));

                    if (hemfCopy)
                    {
                        DeleteEnhMetaFile(hemf);
                        hemf = hemfCopy;
                    }
                    else
                        MessageBox(hwnd, "Cannot save metafile",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);

                    return 0;

                case IDM_FILE_PRINT:

                    // Show the Print dialog box and get printer DC

                    printdlg.Flags = PD_RETURNDC | PD_NOPAGENUMS | PD_NOSELECTION;

                    if (!PrintDlg(&printdlg))
                        return 0;

                    if (NULL == (hdcPrn = printdlg.hDC))
                    {
                        MessageBox(hwnd, "Cannot obtain printer DC",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
                        return 0;
                    }

                    // Get size of printable area of page

                    rect.left   = 0;
                    rect.right  = GetDeviceCaps(hdcPrn, HORZRES);
                    rect.top    = 0;
                    rect.bottom = GetDeviceCaps(hdcPrn, VERTRES);

                    bSuccess = FALSE;

                    // Play the EMF to the printer

                    SetCursor(LoadCursor(NULL, IDC_WAIT));
                    ShowCursor(TRUE);

                    if ((StartDoc(hdcPrn, &di) > 0) && (StartPage(hdcPrn) > 0))
                    {
                        PlayEnhMetaFile(hdcPrn, hemf, &rect);

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
                        MessageBox(hwnd, "Could not print metafile",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);

                    return 0;

                case IDM_FILE_PROPERTIES:

                    if (!hemf)
                        return 0;

                    iLength = GetEnhMetaFileDescription(hemf, 0, NULL);
                    pBuffer = cast(typeof(pBuffer))GC.malloc((iLength + 256) * TCHAR.sizeof);

                    GetEnhMetaFileHeader(hemf, ENHMETAHEADER.sizeof, &header);

                    // Format header file information
                    i = wsprintf(pBuffer,
                                 "Bounds = (%i, %i) to (%i, %i) pixels\n",
                                 header.rclBounds.left, header.rclBounds.top,
                                 header.rclBounds.right, header.rclBounds.bottom);

                    i += wsprintf(pBuffer + i,
                                  "Frame = (%i, %i) to (%i, %i) mms\n",
                                  header.rclFrame.left, header.rclFrame.top,
                                  header.rclFrame.right, header.rclFrame.bottom);

                    i += wsprintf(pBuffer + i,
                                  "Resolution = (%i, %i) pixels = (%i, %i) mms\n",
                                  header.szlDevice.cx, header.szlDevice.cy,
                                  header.szlMillimeters.cx,
                                  header.szlMillimeters.cy);

                    i += wsprintf(pBuffer + i,
                                  "Size = %i, Records = %i, Handles = %i, Palette entries = %i\n",
                                  header.nBytes, header.nRecords,
                                  header.nHandles, header.nPalEntries);

                    // Include the metafile description, if present

                    if (iLength)
                    {
                        i += wsprintf(pBuffer + i, "Description = ");
                        GetEnhMetaFileDescription(hemf, iLength, pBuffer + i);
                        pBuffer [lstrlen(pBuffer)] = '\t';
                    }

                    MessageBox(hwnd, pBuffer, "Metafile Properties", MB_OK);
                    GC.free(pBuffer);
                    return 0;

                case IDM_EDIT_COPY:
                case IDM_EDIT_CUT:

                    if (!hemf)
                        return 0;

                    // Transfer metafile copy to the clipboard

                    hemfCopy = CopyEnhMetaFile(hemf, NULL);

                    OpenClipboard(hwnd);
                    EmptyClipboard();
                    SetClipboardData(CF_ENHMETAFILE, hemfCopy);
                    CloseClipboard();

                    if (LOWORD(wParam) == IDM_EDIT_COPY)
                        return 0;
                    
                    goto case;

                // fall through if IDM_EDIT_CUT
                case IDM_EDIT_DELETE:

                    if (hemf)
                    {
                        DeleteEnhMetaFile(hemf);
                        hemf = NULL;
                        InvalidateRect(hwnd, NULL, TRUE);
                    }

                    return 0;

                case IDM_EDIT_PASTE:
                    OpenClipboard(hwnd);
                    hemfCopy = GetClipboardData(CF_ENHMETAFILE);
                    CloseClipboard();

                    if (hemfCopy && hemf)
                    {
                        DeleteEnhMetaFile(hemf);
                        hemf = NULL;
                    }

                    hemf = CopyEnhMetaFile(hemfCopy, NULL);
                    InvalidateRect(hwnd, NULL, TRUE);
                    return 0;

                case IDM_APP_ABOUT:
                    MessageBox(hwnd, "Enhanced Metafile Viewer\n(c) Charles Petzold, 1998",
                               appName.toUTF16z, MB_OK);
                    return 0;

                case IDM_APP_EXIT:
                    SendMessage(hwnd, WM_CLOSE, 0, 0L);
                    return 0;
                
                default:
            }

            break;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            if (hemf)
            {
                hPalette = CreatePaletteFromMetaFile(hemf);
                if (hPalette !is null)
                {
                    SelectPalette(hdc, hPalette, FALSE);
                    RealizePalette(hdc);
                }

                GetClientRect(hwnd, &rect);
                PlayEnhMetaFile(hdc, hemf, &rect);

                if (hPalette)
                    DeleteObject(hPalette);
            }

            EndPaint(hwnd, &ps);
            return 0;

        case WM_QUERYNEWPALETTE:

            hPalette = CreatePaletteFromMetaFile(hemf);
            if (!hemf || hPalette is null)
                return FALSE;

            hdc = GetDC(hwnd);
            SelectPalette(hdc, hPalette, FALSE);
            RealizePalette(hdc);
            InvalidateRect(hwnd, NULL, FALSE);

            DeleteObject(hPalette);
            ReleaseDC(hwnd, hdc);
            return TRUE;

        case WM_PALETTECHANGED:

            if (cast(HWND)wParam == hwnd)
                break;

            hPalette = CreatePaletteFromMetaFile(hemf);
            if (!hemf || hPalette is null)
                break;

            hdc = GetDC(hwnd);
            SelectPalette(hdc, hPalette, FALSE);
            RealizePalette(hdc);
            UpdateColors(hdc);

            DeleteObject(hPalette);
            ReleaseDC(hwnd, hdc);
            break;

        case WM_DESTROY:

            if (hemf)
                DeleteEnhMetaFile(hemf);

            PostQuitMessage(0);
            return 0;
            
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
