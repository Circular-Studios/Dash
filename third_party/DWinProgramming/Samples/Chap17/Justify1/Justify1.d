/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Justify1;

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

string appName     = "Justify1";
string description = "Justified Type #1";
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

    MoveToEx(hdc, 0,          -360, NULL);
    LineTo(hdc, ptClient.x, -360);
    MoveToEx(hdc, -360,          0, NULL);
    LineTo(hdc, -360, ptClient.y);

    for (i = 0, j = 0; i <= ptClient.x; i += 1440 / 16, j++)
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

// I'll leave porting this to a better D equivalent as an exercise to the reader. :p
void Justify(HDC hdc, PTSTR pText, RECT* prc, int iAlign)
{
    int xStart, yStart, cSpaceChars;
    PTSTR pBegin, pEnd;
    SIZE  size;

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
            GetTextExtentPoint32(hdc, pBegin, pText - pBegin - 1, &size);
        }
        while (size.cx < (prc.right - prc.left));

        cSpaceChars--;                  // discount last space at end of line

        while (*(pEnd - 1) == ' ')      // eliminate trailing spaces
        {
            pEnd--;
            cSpaceChars--;
        }

        // if end of text and no space characters, set pEnd to end

        if (*pText == '\0' || cSpaceChars <= 0)
            pEnd = pText;

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
    static DOCINFO di = DOCINFO(DOCINFO.sizeof, "Justify1: Printing");
    static int iAlign = IDM_ALIGN_LEFT;
    static LOGFONT  lf;
    static PRINTDLG pd;
    static string szText =
        "You don't know about me, without you "
        "have read a book by the name of \"The "
        "Adventures of Tom Sawyer,\" but that "
        "ain't no matter. That book was made by "
        "Mr. Mark Twain, and he told the truth, "
        "mainly. There was things which he "
        "stretched, but mainly he told the truth. "
        "That is nothing. I never seen anybody "
        "but lied, one time or another, without "
        "it was Aunt Polly, or the widow, or "
        "maybe Mary. Aunt Polly -- Tom's Aunt "
        "Polly, she is -- and Mary, and the Widow "
        "Douglas, is all told about in that book "
        "-- which is mostly a true book; with "
        "some stretchers, as I said before.";
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
            GetObject(GetStockObject(SYSTEM_FONT), lf.sizeof, &lf);

            cf.hwndOwner   = hwnd;
            cf.hDC         = NULL;
            cf.lpLogFont   = &lf;
            cf.iPointSize  = 0;
            cf.Flags       = CF_INITTOLOGFONTSTRUCT | CF_SCREENFONTS |
                             CF_EFFECTS;
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
                    pd.lStructSize = PRINTDLG.sizeof;
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

                    // Set margins of 1 inch
                    rect.left = GetDeviceCaps(hdcPrn, LOGPIXELSX) -
                                GetDeviceCaps(hdcPrn, PHYSICALOFFSETX);

                    rect.top = GetDeviceCaps(hdcPrn, LOGPIXELSY) -
                               GetDeviceCaps(hdcPrn, PHYSICALOFFSETY);

                    rect.right = GetDeviceCaps(hdcPrn, PHYSICALWIDTH) -
                                 GetDeviceCaps(hdcPrn, LOGPIXELSX) -
                                 GetDeviceCaps(hdcPrn, PHYSICALOFFSETX);

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

            rect.left  += GetDeviceCaps(hdc, LOGPIXELSX) / 2;
            rect.top   += GetDeviceCaps(hdc, LOGPIXELSY) / 2;
            rect.right -= GetDeviceCaps(hdc, LOGPIXELSX) / 4;

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
