/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Justify2;

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

string appName     = "Justify2";
string description = "Justified Type #2 ";
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

enum OUTWIDTH = 6;       // Width of formatted output in inches
enum LASTCHAR = 127;     // Last character code used in text

void DrawRuler(HDC hdc, RECT* prc)
{
    enum iRuleSize = [360, 72, 144, 72, 216, 72, 144, 72,
                      288, 72, 144, 72, 216, 72, 144, 72];
    int i, j;
    POINT ptClient;

    SaveDC(hdc);

    // Set Logical Twips mapping mode
    SetMapMode(hdc, MM_ANISOTROPIC);
    SetWindowExtEx(hdc, 1440, 1440, NULL);
    SetViewportExtEx(hdc, GetDeviceCaps(hdc, LOGPIXELSX),
                     GetDeviceCaps(hdc, LOGPIXELSY), NULL);

    // Move the origin to a half inch from upper left
    SetWindowOrgEx(hdc, -720, -720, NULL);

    // Find the right margin (quarter inch from right)
    ptClient.x = prc.right;
    ptClient.y = prc.bottom;
    DPtoLP(hdc, &ptClient, 1);
    ptClient.x -= 360;

    // Draw the rulers
    MoveToEx(hdc, 0,               -360, NULL);
    LineTo(hdc, OUTWIDTH * 1440, -360);
    MoveToEx(hdc, -360,               0, NULL);
    LineTo(hdc, -360,      ptClient.y);

    for (i = 0, j = 0; i <= ptClient.x && i <= OUTWIDTH * 1440;
         i += 1440 / 16, j++)
    {
        MoveToEx(hdc, i, -360, NULL);
        LineTo(hdc, i, -360 - iRuleSize [j % 16]);
    }

    for (i = 0, j = 0; i <= ptClient.y; i += 1440 / 16, j++)
    {
        MoveToEx(hdc, -360, i, NULL);
        LineTo(hdc, -360 - iRuleSize [j % 16], i);
    }

    RestoreDC(hdc, -1);
}

/*----------------------------------------------------------------------
   GetCharDesignWidths:  Gets character widths for font as large as the
                         original design size
   ----------------------------------------------------------------------*/
UINT GetCharDesignWidths(HDC hdc, UINT uFirst, UINT uLast, int* piWidths)
{
    HFONT hFont, hFontDesign;
    LOGFONT lf;
    OUTLINETEXTMETRIC otm;

    hFont = GetCurrentObject(hdc, OBJ_FONT);
    GetObject(hFont, LOGFONT.sizeof, &lf);

    // Get outline text metrics (we'll only be using a field that is
    //   independent of the DC the font is selected into)

    otm.otmSize = OUTLINETEXTMETRIC.sizeof;
    GetOutlineTextMetrics(hdc, OUTLINETEXTMETRIC.sizeof, &otm);

    // Create a new font based on the design size

    lf.lfHeight = -cast(int)otm.otmEMSquare;
    lf.lfWidth  = 0;
    hFontDesign = CreateFontIndirect(&lf);

    // Select the font into the DC and get the character widths

    SaveDC(hdc);
    SetMapMode(hdc, MM_TEXT);
    SelectObject(hdc, hFontDesign);

    GetCharWidth(hdc, uFirst, uLast, piWidths);
    SelectObject(hdc, hFont);
    RestoreDC(hdc, -1);

    // Clean up
    DeleteObject(hFontDesign);

    return otm.otmEMSquare;
}

/*---------------------------------------------------------------------
   GetScaledWidths:  Gets floating point character widths for selected
                     font size
   ---------------------------------------------------------------------*/
void GetScaledWidths(HDC hdc, double* pdWidths)
{
    double dScale;
    HFONT  hFont;
    int[LASTCHAR + 1] aiDesignWidths;
    int i;
    LOGFONT lf;
    UINT uEMSquare;

    // Call function above
    uEMSquare = GetCharDesignWidths(hdc, 0, LASTCHAR, aiDesignWidths.ptr);

    // Get LOGFONT for current font in device context
    hFont = GetCurrentObject(hdc, OBJ_FONT);
    GetObject(hFont, LOGFONT.sizeof, &lf);

    // Scale the widths and store as floating point values
    dScale = cast(double)-lf.lfHeight / cast(double)uEMSquare;

    for (i = 0; i <= LASTCHAR; i++)
        pdWidths[i] = dScale * aiDesignWidths[i];
}

/*--------------------------------------------------------------
   GetTextExtentFloat:  Calculates text width in floating point
   --------------------------------------------------------------*/
double GetTextExtentFloat(double* pdWidths, PTSTR psText, int iCount)
{
    double dWidth = 0;
    int i;

    for (i = 0; i < iCount; i++)
        dWidth += pdWidths [psText[i]];

    return dWidth;
}

/*------------------------------------------------------------------
   Justify:  Based on design units for screen/printer compatibility
   ------------------------------------------------------------------*/
void Justify(HDC hdc, PTSTR pText, RECT* prc, int iAlign)
{
    double dWidth;
    double[LASTCHAR + 1] adWidths;
    int xStart, yStart, cSpaceChars;
    PTSTR pBegin, pEnd;
    SIZE  size;

    // Fill the adWidths array with floating point character widths
    GetScaledWidths(hdc, adWidths.ptr);

    yStart = prc.top;

    do                             // for each text line
    {
        cSpaceChars = 0;           // initialize number of spaces in line

        while (*pText == ' ')      // skip over leading spaces
            pText++;

        pBegin = pText;            // set pointer to char at beginning of line

        do                         // until the line is known
        {
            pEnd = pText;          // set pointer to char at end of line

            // skip to next space
            while (*pText != '\0' && *pText++ != ' ')
            {
            }

            if (*pText == '\0')
                break;

            // after each space encountered, calculate extents
            cSpaceChars++;
            dWidth = GetTextExtentFloat(adWidths.ptr, pBegin,
                                        pText - pBegin - 1);
        }
        while (dWidth < cast(double)(prc.right - prc.left));

        cSpaceChars--;                  // discount last space at end of line

        while (*(pEnd - 1) == ' ')      // eliminate trailing spaces
        {
            pEnd--;
            cSpaceChars--;
        }

        // if end of text and no space characters, set pEnd to end
        if (*pText == '\0' || cSpaceChars <= 0)
            pEnd = pText;

        // Now get integer extents
        GetTextExtentPoint32(hdc, pBegin, pEnd - pBegin, &size);

        switch (iAlign)                 // use alignment for xStart
        {
            case IDM_ALIGN_LEFT:
                xStart = prc.left;
                break;

            case IDM_ALIGN_RIGHT:
                xStart = prc.right - size.cx;
                break;

            case IDM_ALIGN_CENTER:
                xStart = (prc.right + prc.left - size.cx) / 2;
                break;

            case IDM_ALIGN_JUSTIFIED:

                if (*pText != '\0' && cSpaceChars > 0)
                    SetTextJustification(hdc,
                                         prc.right - prc.left - size.cx,
                                         cSpaceChars);

                xStart = prc.left;
                break;
                
            default:
        }

        // display the text
        TextOut(hdc, xStart, yStart, pBegin, pEnd - pBegin);

        // prepare for next line
        SetTextJustification(hdc, 0, 0);
        yStart += size.cy;
        pText   = pEnd;
    }
    while (*pText && yStart < prc.bottom - size.cy);
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static CHOOSEFONT cf;
    static DOCINFO di = DOCINFO(DOCINFO.sizeof, "Justify2: Printing");
    static int iAlign = IDM_ALIGN_LEFT;
    static LOGFONT  lf;
    static PRINTDLG pd;
    static string szText = 
        "Call me Ishmael. Some years ago -- never "
        "mind how long precisely -- having little "
        "or no money in my purse, and nothing "
        "particular to interest me on shore, I "
        "thought I would sail about a little and "
        "see the watery part of the world. It is "
        "a way I have of driving off the spleen, "
        "and regulating the circulation. Whenever "
        "I find myself growing grim about the "
        "mouth; whenever it is a damp, drizzly "
        "November in my soul; whenever I find "
        "myself involuntarily pausing before "
        "coffin warehouses, and bringing up the "
        "rear of every funeral I meet; and "
        "especially whenever my hypos get such an "
        "upper hand of me, that it requires a "
        "strong moral principle to prevent me "
        "from deliberately stepping into the "
        "street, and methodically knocking "
        "people's hats off -- then, I account it "
        "high time to get to sea as soon as I "
        "can. This is my substitute for pistol "
        "and ball. With a philosophical flourish "
        "Cato throws himself upon his sword; I "
        "quietly take to the ship. There is "
        "nothing surprising in this. If they but "
        "knew it, almost all men in their degree, "
        "some time or other, cherish very nearly "
        "the same feelings towards the ocean with "
        "me.";
        
    BOOL  fSuccess;
    HDC   hdc, hdcPrn;
    HMENU hMenu;
    int   iSavePointSize;
    PAINTSTRUCT ps;
    RECT rect;

    switch (message)
    {
        case WM_CREATE:

            // Initialize the CHOOSEFONT structure

            hdc               = GetDC(hwnd);
            lf.lfHeight       = -GetDeviceCaps(hdc, LOGPIXELSY) / 6;
            lf.lfOutPrecision = OUT_TT_ONLY_PRECIS;
            auto str = "Times New Roman\0";
            lf.lfFaceName[0..str.length] = str.toUTF16;
            ReleaseDC(hwnd, hdc);

            cf.hwndOwner   = hwnd;
            cf.hDC         = NULL;
            cf.lpLogFont   = &lf;
            cf.iPointSize  = 120;

            // Set flags for TrueType only!

            cf.Flags = CF_INITTOLOGFONTSTRUCT | CF_SCREENFONTS |
                       CF_TTONLY | CF_EFFECTS;
            cf.rgbColors      = 0;
            cf.lCustData      = 0;
            cf.lpfnHook       = NULL;
            cf.lpTemplateName = NULL;
            cf.hInstance      = NULL;
            cf.lpszStyle      = NULL;
            cf.nFontType      = 0;
            cf.nSizeMin       = 0;
            cf.nSizeMax       = 0;

            return 0;

        case WM_COMMAND:
            hMenu = GetMenu(hwnd);

            switch (LOWORD(wParam))
            {
                case IDM_FILE_PRINT:

                    // Get printer DC
                    pd.hwndOwner   = hwnd;
                    pd.Flags       = PD_RETURNDC | PD_NOPAGENUMS | PD_NOSELECTION;

                    if (!PrintDlg(&pd))
                        return 0;

                    if (NULL == (hdcPrn = pd.hDC))
                    {
                        MessageBox(hwnd, "Cannot obtain Printer DC",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
                        return 0;
                    }

                    // Set margins for OUTWIDTH inches wide
                    rect.left = (GetDeviceCaps(hdcPrn, PHYSICALWIDTH) -
                                 GetDeviceCaps(hdcPrn, LOGPIXELSX) * OUTWIDTH) / 2
                                - GetDeviceCaps(hdcPrn, PHYSICALOFFSETX);

                    rect.right = rect.left +
                                 GetDeviceCaps(hdcPrn, LOGPIXELSX) * OUTWIDTH;

                    // Set margins of 1 inch at top and bottom
                    rect.top = GetDeviceCaps(hdcPrn, LOGPIXELSY) -
                               GetDeviceCaps(hdcPrn, PHYSICALOFFSETY);

                    rect.bottom = GetDeviceCaps(hdcPrn, PHYSICALHEIGHT) -
                                  GetDeviceCaps(hdcPrn, LOGPIXELSY) -
                                  GetDeviceCaps(hdcPrn, PHYSICALOFFSETY);

                    // Display text on printer
                    SetCursor(LoadCursor(NULL, IDC_WAIT));
                    ShowCursor(TRUE);

                    fSuccess = FALSE;

                    if ((StartDoc(hdcPrn, &di) > 0) && (StartPage(hdcPrn) > 0))
                    {
                        // Select font using adjusted lfHeight
                        iSavePointSize = lf.lfHeight;
                        lf.lfHeight    = -(GetDeviceCaps(hdcPrn, LOGPIXELSY) *
                                           cf.iPointSize) / 720;

                        SelectObject(hdcPrn, CreateFontIndirect(&lf));
                        lf.lfHeight = iSavePointSize;

                        // Set text color
                        SetTextColor(hdcPrn, cf.rgbColors);

                        // Display text
                        Justify(hdcPrn, cast(wchar*)szText.toUTF16z, &rect, iAlign);

                        if (EndPage(hdcPrn) > 0)
                        {
                            fSuccess = TRUE;
                            EndDoc(hdcPrn);
                        }
                    }

                    ShowCursor(FALSE);
                    SetCursor(LoadCursor(NULL, IDC_ARROW));

                    DeleteDC(hdcPrn);

                    if (!fSuccess)
                        MessageBox(hwnd, "Could not print text",
                                   appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);

                    return 0;

                case IDM_FONT:

                    if (ChooseFont(&cf))
                        InvalidateRect(hwnd, NULL, TRUE);

                    return 0;

                case IDM_ALIGN_LEFT:
                case IDM_ALIGN_RIGHT:
                case IDM_ALIGN_CENTER:
                case IDM_ALIGN_JUSTIFIED:
                    CheckMenuItem(hMenu, iAlign, MF_UNCHECKED);
                    iAlign = LOWORD(wParam);
                    CheckMenuItem(hMenu, iAlign, MF_CHECKED);
                    InvalidateRect(hwnd, NULL, TRUE);
                    return 0;
                
                default:
            }

            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            GetClientRect(hwnd, &rect);
            DrawRuler(hdc, &rect);

            rect.left += GetDeviceCaps(hdc, LOGPIXELSX) / 2;
            rect.top  += GetDeviceCaps(hdc, LOGPIXELSY) / 2;
            rect.right = rect.left + OUTWIDTH* GetDeviceCaps(hdc, LOGPIXELSX);

            SelectObject(hdc, CreateFontIndirect(&lf));
            SetTextColor(hdc, cf.rgbColors);

            Justify(hdc, cast(wchar*)szText.toUTF16z, &rect, iAlign);

            DeleteObject(SelectObject(hdc, GetStockObject(SYSTEM_FONT)));
            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
