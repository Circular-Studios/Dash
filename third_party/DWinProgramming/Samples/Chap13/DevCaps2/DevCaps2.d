/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module DevCaps2;

/+
 + Note: I still haven't been able to get the device name out of a menu handle,
 + it throws on access. If you know of a workaround please submit a fix. Thanks.
 +/

import core.memory;
import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.stdio;
import std.utf : count, toUTFz;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");
pragma(lib, "winspool.lib");

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.winspool;

import resource;

string appName     = "DevCaps2";
string description = "Device Capabilities 2";
enum ID_TIMER = 1;
HINSTANCE hinst;

struct BITS
{
    int iMask;
    string description;
}

enum IDM_DEVMODE = 1000;

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
    wchar[32] szDevice;
    string szWindowText;
    static int cxChar, cyChar, nCurrentDevice = IDM_SCREEN, nCurrentInfo = IDM_BASIC;
    static DWORD dwNeeded, dwReturned;
    static PRINTER_INFO_4* pinfo4;
    static PRINTER_INFO_5* pinfo5;
    DWORD i;
    HDC hdc, hdcInfo;
    HMENU  hMenu;
    HANDLE hPrint;
    PAINTSTRUCT ps;
    TEXTMETRIC  tm;

    switch (message)
    {
        case WM_CREATE:
            hdc = GetDC(hwnd);
            SelectObject(hdc, GetStockObject(SYSTEM_FIXED_FONT));
            GetTextMetrics(hdc, &tm);
            cxChar = tm.tmAveCharWidth;
            cyChar = tm.tmHeight + tm.tmExternalLeading;
            ReleaseDC(hwnd, hdc);

            goto case WM_SETTINGCHANGE;

        case WM_SETTINGCHANGE:
            hMenu = GetSubMenu(GetMenu(hwnd), 0);

            while (GetMenuItemCount(hMenu) > 1)
                DeleteMenu(hMenu, 1, MF_BYPOSITION);

            if (GetVersion() & 0x80000000)  // Windows 98
            {
                EnumPrinters(PRINTER_ENUM_LOCAL, NULL, 5, NULL, 0, &dwNeeded, &dwReturned);
                pinfo5 = cast(typeof(pinfo5))GC.malloc(dwNeeded);
                EnumPrinters(PRINTER_ENUM_LOCAL, NULL, 5, cast(PBYTE)pinfo5, dwNeeded, &dwNeeded, &dwReturned);

                for (i = 0; i < dwReturned; i++)
                {
                    AppendMenu(hMenu, (i + 1) % 16 ? 0 : MF_MENUBARBREAK, i + 1, pinfo5[i].pPrinterName);
                }

                GC.free(pinfo5);
            }
            else  // Windows NT
            {
                EnumPrinters(PRINTER_ENUM_LOCAL, NULL, 4, NULL, 0, &dwNeeded, &dwReturned);
                pinfo4 = cast(typeof(pinfo4))GC.malloc(dwNeeded);
                EnumPrinters(PRINTER_ENUM_LOCAL, NULL, 4, cast(PBYTE)pinfo4, dwNeeded, &dwNeeded, &dwReturned);

                for (i = 0; i < dwReturned; i++)
                {
                    AppendMenu(hMenu, (i + 1) % 16 ? 0 : MF_MENUBARBREAK, i + 1, pinfo4[i].pPrinterName);
                }

                GC.free(pinfo4);
            }

            AppendMenu(hMenu, MF_SEPARATOR, 0, NULL);
            AppendMenu(hMenu, 0, IDM_DEVMODE, "Properties");

            wParam = IDM_SCREEN;
            goto case WM_COMMAND;

        case WM_COMMAND:
            hMenu = GetMenu(hwnd);

            if (LOWORD(wParam) == IDM_SCREEN ||  // IDM_SCREEN & Printers
                LOWORD(wParam) < IDM_DEVMODE)
            {
                CheckMenuItem(hMenu, nCurrentDevice, MF_UNCHECKED);
                nCurrentDevice = LOWORD(wParam);
                CheckMenuItem(hMenu, nCurrentDevice, MF_CHECKED);
            }
            else if (LOWORD(wParam) == IDM_DEVMODE)  // Properties selection
            {
                GetMenuString(hMenu, nCurrentDevice, szDevice.ptr, szDevice.length, MF_BYCOMMAND);

                if (OpenPrinter(szDevice.ptr, &hPrint, NULL))
                {
                    PrinterProperties(hwnd, hPrint);
                    ClosePrinter(hPrint);
                }
            }
            else  // info menu items
            {
                CheckMenuItem(hMenu, nCurrentInfo, MF_UNCHECKED);
                nCurrentInfo = LOWORD(wParam);
                CheckMenuItem(hMenu, nCurrentInfo, MF_CHECKED);
            }

            InvalidateRect(hwnd, NULL, TRUE);
            return 0;

        case WM_INITMENUPOPUP:

            if (lParam == 0)
                EnableMenuItem(GetMenu(hwnd), IDM_DEVMODE, (nCurrentDevice == IDM_SCREEN) ? MF_GRAYED : MF_ENABLED);

            return 0;

        case WM_PAINT:
            szWindowText = "Device Capabilities: ";

            if (nCurrentDevice == IDM_SCREEN)
            {
                hdcInfo = CreateIC("DISPLAY", NULL, NULL, NULL);
            }
            else
            {
                hMenu = GetMenu(hwnd);
                GetMenuString(hMenu, nCurrentDevice, szDevice.ptr, szDevice.length/2, MF_BYCOMMAND);
                hdcInfo = CreateIC(NULL, szDevice.ptr, NULL, NULL);
            }

            //~ szDevice;  // I can't even touch this thing without throwing.. oh well.

            hdc = BeginPaint(hwnd, &ps);
            SelectObject(hdc, GetStockObject(SYSTEM_FIXED_FONT));

            if (hdcInfo)
            {
                switch (nCurrentInfo)
                {
                    case IDM_BASIC:
                        DoBasicInfo(hdc, hdcInfo, cxChar, cyChar);
                        break;

                    case IDM_OTHER:
                        DoOtherInfo(hdc, hdcInfo, cxChar, cyChar);
                        break;

                    case IDM_CURVE:
                    case IDM_LINE:
                    case IDM_POLY:
                    case IDM_TEXT:
                        DoBitCodedCaps(hdc, hdcInfo, cxChar, cyChar, nCurrentInfo - IDM_CURVE);
                        break;

                    default:
                }

                DeleteDC(hdcInfo);
            }

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

void DoBasicInfo(HDC hdc, HDC hdcInfo, int cxChar, int cyChar)
{
    struct Info
    {
        int nIndex;
        string description;
    }

    enum infos =
    [
        Info(HORZSIZE,        "HORZSIZE        Width in millimeters:"),
        Info(VERTSIZE,        "VERTSIZE        Height in millimeters:"),
        Info(HORZRES,         "HORZRES         Width in pixels:"),
        Info(VERTRES,         "VERTRES         Height in raster lines:"),
        Info(BITSPIXEL,       "BITSPIXEL       Color bits per pixel:"),
        Info(PLANES,          "PLANES          Number of color planes:"),
        Info(NUMBRUSHES,      "NUMBRUSHES      Number of device brushes:"),
        Info(NUMPENS,         "NUMPENS         Number of device pens:"),
        Info(NUMMARKERS,      "NUMMARKERS      Number of device markers:"),
        Info(NUMFONTS,        "NUMFONTS        Number of device fonts:"),
        Info(NUMCOLORS,       "NUMCOLORS       Number of device colors:"),
        Info(PDEVICESIZE,     "PDEVICESIZE     Size of device structure:"),
        Info(ASPECTX,         "ASPECTX         Relative width of pixel:"),
        Info(ASPECTY,         "ASPECTY         Relative height of pixel:"),
        Info(ASPECTXY,        "ASPECTXY        Relative diagonal of pixel:"),
        Info(LOGPIXELSX,      "LOGPIXELSX      Horizontal dots per inch:"),
        Info(LOGPIXELSY,      "LOGPIXELSY      Vertical dots per inch:"),
        Info(SIZEPALETTE,     "SIZEPALETTE     Number of palette entries:"),
        Info(NUMRESERVED,     "NUMRESERVED     Reserved palette entries:"),
        Info(COLORRES,        "COLORRES        Actual color resolution:"),
        Info(PHYSICALWIDTH,   "PHYSICALWIDTH   Printer page pixel width:"),
        Info(PHYSICALHEIGHT,  "PHYSICALHEIGHT  Printer page pixel height:"),
        Info(PHYSICALOFFSETX, "PHYSICALOFFSETX Printer page x offset:"),
        Info(PHYSICALOFFSETY, "PHYSICALOFFSETY Printer page y offset:")
    ];

    string buffer;
    foreach (index, info; infos)
    {
        buffer = format("%-45s%8s", info.description, GetDeviceCaps(hdcInfo, info.nIndex));
        TextOut(hdc, cxChar, (index + 1) * cyChar, buffer.toUTF16z, buffer.count);
    }
}

void DoOtherInfo(HDC hdc, HDC hdcInfo, int cxChar, int cyChar)
{
    enum clips =
    [
        BITS(CP_RECTANGLE,    "CP_RECTANGLE    Can Clip To Rectangle:"),
    ];

    enum rasters =
    [
        BITS(RC_BITBLT,       "RC_BITBLT       Capable of simple BitBlt:"),
        BITS(RC_BANDING,      "RC_BANDING      Requires banding support:"),
        BITS(RC_SCALING,      "RC_SCALING      Requires scaling support:"),
        BITS(RC_BITMAP64,     "RC_BITMAP64     Supports bitmaps >64K:"),
        BITS(RC_GDI20_OUTPUT, "RC_GDI20_OUTPUT Has 2.0 output calls:"),
        BITS(RC_DI_BITMAP,    "RC_DI_BITMAP    Supports DIB to memory:"),
        BITS(RC_PALETTE,      "RC_PALETTE      Supports a palette:"),
        BITS(RC_DIBTODEV,     "RC_DIBTODEV     Supports bitmap conversion:"),
        BITS(RC_BIGFONT,      "RC_BIGFONT      Supports fonts >64K:"),
        BITS(RC_STRETCHBLT,   "RC_STRETCHBLT   Supports StretchBlt:"),
        BITS(RC_FLOODFILL,    "RC_FLOODFILL    Supports FloodFill:"),
        BITS(RC_STRETCHDIB,   "RC_STRETCHDIB   Supports StretchDIBits:")
    ];

    enum szTechs =
    [
        "DT_PLOTTER (Vector plotter)",
        "DT_RASDISPLAY (Raster display)",
        "DT_RASPRINTER (Raster printer)",
        "DT_RASCAMERA (Raster camera)",
        "DT_CHARSTREAM (Character stream)",
        "DT_METAFILE (Metafile)",
        "DT_DISPFILE (Display file)"
    ];

    string buffer;

    buffer = format("%-24s%04s", "DRIVERVERSION:", GetDeviceCaps(hdcInfo, DRIVERVERSION));
    TextOut(hdc, cxChar, cyChar, buffer.toUTF16z, buffer.count);

    buffer = format("%-24s%40s", "TECHNOLOGY:", szTechs[GetDeviceCaps(hdcInfo, TECHNOLOGY)]);
    TextOut(hdc, cxChar, 2 * cyChar, buffer.toUTF16z, buffer.count);

    buffer = "CLIPCAPS (Clipping capabilities)";
    TextOut(hdc, cxChar, 4 * cyChar, buffer.toUTF16z, buffer.count);
    foreach (index, clip; clips)
    {
        buffer = format("%-45s %3s", clip.description, (GetDeviceCaps(hdcInfo, CLIPCAPS) & clip.iMask) ? "Yes" : "No");
        TextOut(hdc, 9 * cxChar, (index + 6) * cyChar, buffer.toUTF16z, buffer.count);
    }

    buffer = "RASTERCAPS (Raster capabilities)";
    TextOut(hdc, cxChar, 8 * cyChar, buffer.toUTF16z, buffer.count);
    foreach (index, raster; rasters)
    {
        buffer = format("%-45s %3s", raster.description, (GetDeviceCaps(hdcInfo, RASTERCAPS) & raster.iMask) ? "Yes" : "No");
        TextOut(hdc, 9 * cxChar, (index + 10) * cyChar, buffer.toUTF16z, buffer.count);
    }
}

void DoBitCodedCaps(HDC hdc, HDC hdcInfo, int cxChar, int cyChar, int iType)
{
    enum curves =
    [
        BITS(CC_CIRCLES,    "CC_CIRCLES    Can do circles:"),
        BITS(CC_PIE,        "CC_PIE        Can do pie wedges:"),
        BITS(CC_CHORD,      "CC_CHORD      Can do chord arcs:"),
        BITS(CC_ELLIPSES,   "CC_ELLIPSES   Can do ellipses:"),
        BITS(CC_WIDE,       "CC_WIDE       Can do wide borders:"),
        BITS(CC_STYLED,     "CC_STYLED     Can do styled borders:"),
        BITS(CC_WIDESTYLED, "CC_WIDESTYLED Can do wide and styled borders:"),
        BITS(CC_INTERIORS,  "CC_INTERIORS  Can do interiors:")
    ];

    enum lines =
    [
        BITS(LC_POLYLINE,   "LC_POLYLINE   Can do polyline:"),
        BITS(LC_MARKER,     "LC_MARKER     Can do markers:"),
        BITS(LC_POLYMARKER, "LC_POLYMARKER Can do polymarkers"),
        BITS(LC_WIDE,       "LC_WIDE       Can do wide lines:"),
        BITS(LC_STYLED,     "LC_STYLED     Can do styled lines:"),
        BITS(LC_WIDESTYLED, "LC_WIDESTYLED Can do wide and styled lines:"),
        BITS(LC_INTERIORS,  "LC_INTERIORS  Can do interiors:")
    ];

    enum polys =
    [
        BITS(PC_POLYGON,     "PC_POLYGON     Can do alternate fill polygon:"),
        BITS(PC_RECTANGLE,   "PC_RECTANGLE   Can do rectangle:"),
        BITS(PC_WINDPOLYGON, "PC_WINDPOLYGON Can do winding number fill polygon:"),
        BITS(PC_SCANLINE,    "PC_SCANLINE    Can do scanlines:"),
        BITS(PC_WIDE,        "PC_WIDE        Can do wide borders:"),
        BITS(PC_STYLED,      "PC_STYLED      Can do styled borders:"),
        BITS(PC_WIDESTYLED,  "PC_WIDESTYLED  Can do wide and styled borders:"),
        BITS(PC_INTERIORS,   "PC_INTERIORS   Can do interiors:")
    ];

    enum texts =
    [
        BITS(TC_OP_CHARACTER,    "TC_OP_CHARACTER Can do character output precision:"),
        BITS(TC_OP_STROKE,       "TC_OP_STROKE    Can do stroke output precision:"),
        BITS(TC_CP_STROKE,       "TC_CP_STROKE    Can do stroke clip precision:"),
        BITS(TC_CR_90,           "TC_CP_90        Can do 90 degree character rotation:"),
        BITS(TC_CR_ANY,          "TC_CR_ANY       Can do any character rotation:"),
        BITS(TC_SF_X_YINDEP,     "TC_SF_X_YINDEP  Can do scaling independent of X and Y:"),
        BITS(TC_SA_DOUBLE,       "TC_SA_DOUBLE    Can do doubled character for scaling:"),
        BITS(TC_SA_INTEGER,      "TC_SA_INTEGER   Can do integer multiples for scaling:"),
        BITS(TC_SA_CONTIN,       "TC_SA_CONTIN    Can do any multiples for exact scaling:"),
        BITS(TC_EA_DOUBLE,       "TC_EA_DOUBLE    Can do double weight characters:"),
        BITS(TC_IA_ABLE,         "TC_IA_ABLE      Can do italicizing:"),
        BITS(TC_UA_ABLE,         "TC_UA_ABLE      Can do underlining:"),
        BITS(TC_SO_ABLE,         "TC_SO_ABLE      Can do strikeouts:"),
        BITS(TC_RA_ABLE,         "TC_RA_ABLE      Can do raster fonts:"),
        BITS(TC_VA_ABLE,         "TC_VA_ABLE      Can do vector fonts:")
    ];

    struct BitInfo
    {
        int iIndex;
        string title;
        BITS[] bitarray;
    }

    enum bitinfos =
    [
        BitInfo(CURVECAPS,     "CURVCAPS (Curve Capabilities)",          curves),
        BitInfo(LINECAPS,      "LINECAPS (Line Capabilities)",           lines),
        BitInfo(POLYGONALCAPS, "POLYGONALCAPS (Polygonal Capabilities)", polys),
        BitInfo(TEXTCAPS,      "TEXTCAPS (Text Capabilities)",           texts)
    ];

    static string buffer;
    auto iDevCaps = GetDeviceCaps(hdcInfo, bitinfos[iType].iIndex);

    TextOut(hdc, cxChar, cyChar, bitinfos[iType].title.toUTF16z, bitinfos[iType].title.count);

    foreach (index, bit; bitinfos[iType].bitarray)
    {
        buffer = format("%-55s %3s", bit.description, (iDevCaps & bit.iMask) ? "Yes" : "No");
        TextOut(hdc, cxChar, (index + 3) * cyChar, buffer.toUTF16z, buffer.count);
    }
}
