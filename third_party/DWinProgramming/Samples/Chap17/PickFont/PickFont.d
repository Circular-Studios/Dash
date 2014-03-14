/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module PickFont;

import core.memory;
import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.utf : count, toUTFz;

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

string appName     = "PickFont";
string description = "PickFont: Create Logical Font";
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
                        WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,           // window style
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
        if (hdlg == null || !IsDialogMessage(hdlg, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return msg.wParam;
}

struct DLGPARAMS
{
    int iDevice, iMapMode;
    BOOL fMatchAspect;
    BOOL fAdvGraphics;
    LOGFONT lf;
    TEXTMETRIC tm;
    TCHAR[LF_FULLFACESIZE] szFaceName;
}

// Formatting for BCHAR fields of TEXTMETRIC structure
enum BCHARFORM = "0x%04X";

HWND hdlg;

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static DLGPARAMS dp;
    dstring szText = "ABCDE abcde ÀÁÂÃÄÅ àáâãäå";
    HDC hdc;
    PAINTSTRUCT ps;
    RECT rect;

    switch (message)
    {
        case WM_CREATE:
            dp.iDevice = IDM_DEVICE_SCREEN;
            hdlg = CreateDialogParam((cast(LPCREATESTRUCT)lParam).hInstance,
                                     appName.toUTF16z, hwnd, &DlgProc, cast(LPARAM)&dp);
            return 0;

        case WM_SETFOCUS:
            SetFocus(hdlg);
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_DEVICE_SCREEN:
                case IDM_DEVICE_PRINTER:
                    CheckMenuItem(GetMenu(hwnd), dp.iDevice, MF_UNCHECKED);
                    dp.iDevice = LOWORD(wParam);
                    CheckMenuItem(GetMenu(hwnd), dp.iDevice, MF_CHECKED);
                    SendMessage(hwnd, WM_COMMAND, IDOK, 0);
                    return 0;
                
                default:
            }

            break;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            // Set graphics mode so escapement works in Windows NT

            SetGraphicsMode(hdc, dp.fAdvGraphics ? GM_ADVANCED : GM_COMPATIBLE);

            // Set the mapping mode and the mapper flag

            MySetMapMode(hdc, dp.iMapMode);
            SetMapperFlags(hdc, dp.fMatchAspect);

            // Find the point to begin drawing text

            GetClientRect(hdlg, &rect);
            rect.bottom += 1;
            DPtoLP(hdc, cast(PPOINT)&rect, 2);

            // Create and select the font; display the text

            SelectObject(hdc, CreateFontIndirect(&dp.lf));
            TextOut(hdc, rect.left, rect.bottom, to!string(szText).toUTF16z, szText.count);

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

extern (Windows)
BOOL DlgProc(HWND hdlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    static DLGPARAMS* pdp;
    static PRINTDLG pd = PRINTDLG(PRINTDLG.sizeof);
    HDC hdcDevice;
    HFONT hFont;

    switch (message)
    {
        case WM_INITDIALOG:

            // Save pointer to dialog-parameters structure in WndProc
            pdp = cast(DLGPARAMS*)lParam;

            SendDlgItemMessage(hdlg, IDC_LF_FACENAME, EM_LIMITTEXT,
                               LF_FACESIZE - 1, 0);

            CheckRadioButton(hdlg, IDC_OUT_DEFAULT, IDC_OUT_OUTLINE,
                             IDC_OUT_DEFAULT);

            CheckRadioButton(hdlg, IDC_DEFAULT_QUALITY, IDC_PROOF_QUALITY,
                             IDC_DEFAULT_QUALITY);

            CheckRadioButton(hdlg, IDC_DEFAULT_PITCH, IDC_VARIABLE_PITCH,
                             IDC_DEFAULT_PITCH);

            CheckRadioButton(hdlg, IDC_FF_DONTCARE, IDC_FF_DECORATIVE,
                             IDC_FF_DONTCARE);

            CheckRadioButton(hdlg, IDC_MM_TEXT, IDC_MM_LOGTWIPS,
                             IDC_MM_TEXT);

            SendMessage(hdlg, WM_COMMAND, IDOK, 0);
            
            goto case;
        
        
        case WM_SETFOCUS:
            SetFocus(GetDlgItem(hdlg, IDC_LF_HEIGHT));
            return FALSE;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDC_CHARSET_HELP:
                    MessageBox(hdlg,
                               "0 = Ansi\n"
                               "1 = Default\n"
                               "2 = Symbol\n"
                               "128 = Shift JIS (Japanese)\n"
                               "129 = Hangul (Korean)\n"
                               "130 = Johab (Korean)\n"
                               "134 = GB 2312 (Simplified Chinese)\n"
                               "136 = Chinese Big 5 (Traditional Chinese)\n"
                               "177 = Hebrew\n"
                               "178 = Arabic\n"
                               "161 = Greek\n"
                               "162 = Turkish\n"
                               "163 = Vietnamese\n"
                               "204 = Russian\n"
                               "222 = Thai\n"
                               "238 = East European\n"
                               "255 = OEM",
                               appName.toUTF16z, MB_OK | MB_ICONINFORMATION);
                    return TRUE;

                // These radio buttons set the lfOutPrecision field

                case IDC_OUT_DEFAULT:
                    pdp.lf.lfOutPrecision = OUT_DEFAULT_PRECIS;
                    return TRUE;

                case IDC_OUT_STRING:
                    pdp.lf.lfOutPrecision = OUT_STRING_PRECIS;
                    return TRUE;

                case IDC_OUT_CHARACTER:
                    pdp.lf.lfOutPrecision = OUT_CHARACTER_PRECIS;
                    return TRUE;

                case IDC_OUT_STROKE:
                    pdp.lf.lfOutPrecision = OUT_STROKE_PRECIS;
                    return TRUE;

                case IDC_OUT_TT:
                    pdp.lf.lfOutPrecision = OUT_TT_PRECIS;
                    return TRUE;

                case IDC_OUT_DEVICE:
                    pdp.lf.lfOutPrecision = OUT_DEVICE_PRECIS;
                    return TRUE;

                case IDC_OUT_RASTER:
                    pdp.lf.lfOutPrecision = OUT_RASTER_PRECIS;
                    return TRUE;

                case IDC_OUT_TT_ONLY:
                    pdp.lf.lfOutPrecision = OUT_TT_ONLY_PRECIS;
                    return TRUE;

                case IDC_OUT_OUTLINE:
                    pdp.lf.lfOutPrecision = OUT_OUTLINE_PRECIS;
                    return TRUE;

                // These three radio buttons set the lfQuality field

                case IDC_DEFAULT_QUALITY:
                    pdp.lf.lfQuality = DEFAULT_QUALITY;
                    return TRUE;

                case IDC_DRAFT_QUALITY:
                    pdp.lf.lfQuality = DRAFT_QUALITY;
                    return TRUE;

                case IDC_PROOF_QUALITY:
                    pdp.lf.lfQuality = PROOF_QUALITY;
                    return TRUE;

                // These three radio buttons set the lower nibble
                //   of the lfPitchAndFamily field

                case IDC_DEFAULT_PITCH:
                    pdp.lf.lfPitchAndFamily = cast(BYTE)
                                                   ((0xF0 & pdp.lf.lfPitchAndFamily) | DEFAULT_PITCH);
                    return TRUE;

                case IDC_FIXED_PITCH:
                    pdp.lf.lfPitchAndFamily = cast(BYTE)
                                                   ((0xF0 & pdp.lf.lfPitchAndFamily) | FIXED_PITCH);
                    return TRUE;

                case IDC_VARIABLE_PITCH:
                    pdp.lf.lfPitchAndFamily = cast(BYTE)
                                                   ((0xF0 & pdp.lf.lfPitchAndFamily) | VARIABLE_PITCH);
                    return TRUE;

                // These six radio buttons set the upper nibble
                //   of the lpPitchAndFamily field

                case IDC_FF_DONTCARE:
                    pdp.lf.lfPitchAndFamily = cast(BYTE)
                                                   ((0x0F & pdp.lf.lfPitchAndFamily) | FF_DONTCARE);
                    return TRUE;

                case IDC_FF_ROMAN:
                    pdp.lf.lfPitchAndFamily = cast(BYTE)
                                                   ((0x0F & pdp.lf.lfPitchAndFamily) | FF_ROMAN);
                    return TRUE;

                case IDC_FF_SWISS:
                    pdp.lf.lfPitchAndFamily = cast(BYTE)
                                                   ((0x0F & pdp.lf.lfPitchAndFamily) | FF_SWISS);
                    return TRUE;

                case IDC_FF_MODERN:
                    pdp.lf.lfPitchAndFamily = cast(BYTE)
                                                   ((0x0F & pdp.lf.lfPitchAndFamily) | FF_MODERN);
                    return TRUE;

                case IDC_FF_SCRIPT:
                    pdp.lf.lfPitchAndFamily = cast(BYTE)
                                                   ((0x0F & pdp.lf.lfPitchAndFamily) | FF_SCRIPT);
                    return TRUE;

                case IDC_FF_DECORATIVE:
                    pdp.lf.lfPitchAndFamily = cast(BYTE)
                                                   ((0x0F & pdp.lf.lfPitchAndFamily) | FF_DECORATIVE);
                    return TRUE;

                // Mapping mode:

                case IDC_MM_TEXT:
                case IDC_MM_LOMETRIC:
                case IDC_MM_HIMETRIC:
                case IDC_MM_LOENGLISH:
                case IDC_MM_HIENGLISH:
                case IDC_MM_TWIPS:
                case IDC_MM_LOGTWIPS:
                    pdp.iMapMode = LOWORD(wParam);
                    return TRUE;

                // OK button pressed
                // -----------------

                case IDOK:

                    // Get LOGFONT structure

                    SetLogFontFromFields(hdlg, pdp);

                    // Set Match-Aspect and Advanced Graphics flags

                    pdp.fMatchAspect = IsDlgButtonChecked(hdlg, IDC_MATCH_ASPECT);
                    pdp.fAdvGraphics = IsDlgButtonChecked(hdlg, IDC_ADV_GRAPHICS);

                    // Get Information Context

                    if (pdp.iDevice == IDM_DEVICE_SCREEN)
                    {
                        hdcDevice = CreateIC("DISPLAY", NULL, NULL, NULL);
                    }
                    else
                    {
                        pd.hwndOwner = hdlg;
                        pd.Flags     = PD_RETURNDEFAULT | PD_RETURNIC;
                        pd.hDevNames = NULL;
                        pd.hDevMode  = NULL;

                        PrintDlg(&pd);

                        hdcDevice = pd.hDC;
                    }

                    // Set the mapping mode and the mapper flag

                    MySetMapMode(hdcDevice, pdp.iMapMode);
                    SetMapperFlags(hdcDevice, pdp.fMatchAspect);

                    // Create font and select it into IC

                    hFont = CreateFontIndirect(&pdp.lf);
                    SelectObject(hdcDevice, hFont);

                    // Get the text metrics and face name

                    GetTextMetrics(hdcDevice, &pdp.tm);
                    GetTextFace(hdcDevice, LF_FULLFACESIZE, pdp.szFaceName.ptr);
                    DeleteDC(hdcDevice);
                    DeleteObject(hFont);

                    // Update dialog fields and invalidate main window

                    SetFieldsFromTextMetric(hdlg, pdp);
                    InvalidateRect(GetParent(hdlg), NULL, TRUE);
                    return TRUE;
                    
                default:
            }

            break;
            
        default:
    }

    return FALSE;
}

void SetLogFontFromFields(HWND hdlg, DLGPARAMS* pdp)
{
    pdp.lf.lfHeight      = GetDlgItemInt(hdlg, IDC_LF_HEIGHT,  NULL, TRUE);
    pdp.lf.lfWidth       = GetDlgItemInt(hdlg, IDC_LF_WIDTH,   NULL, TRUE);
    pdp.lf.lfEscapement  = GetDlgItemInt(hdlg, IDC_LF_ESCAPE,  NULL, TRUE);
    pdp.lf.lfOrientation = cast(ubyte)GetDlgItemInt(hdlg, IDC_LF_ORIENT,  NULL, TRUE);
    pdp.lf.lfWeight      = GetDlgItemInt(hdlg, IDC_LF_WEIGHT,  NULL, TRUE);
    pdp.lf.lfCharSet     = cast(ubyte)GetDlgItemInt(hdlg, IDC_LF_CHARSET, NULL, FALSE);

    pdp.lf.lfItalic =
        IsDlgButtonChecked(hdlg, IDC_LF_ITALIC) == BST_CHECKED;
    pdp.lf.lfUnderline =
        IsDlgButtonChecked(hdlg, IDC_LF_UNDER) == BST_CHECKED;
    pdp.lf.lfStrikeOut =
        IsDlgButtonChecked(hdlg, IDC_LF_STRIKE) == BST_CHECKED;

    GetDlgItemText(hdlg, IDC_LF_FACENAME, pdp.lf.lfFaceName.ptr, LF_FACESIZE);
}

void SetFieldsFromTextMetric(HWND hdlg, DLGPARAMS* pdp)
{
    string szBuffer;
    TCHAR* szYes = ("Yes\0"w.dup.ptr);
    TCHAR* szNo  = ("No\0"w.dup.ptr);
    string[] szFamily = ["Don't Know", "Roman", "Swiss", "Modern",
                         "Script", "Decorative", "Undefined"];

    SetDlgItemInt(hdlg, IDC_TM_HEIGHT,   pdp.tm.tmHeight,           TRUE);
    SetDlgItemInt(hdlg, IDC_TM_ASCENT,   pdp.tm.tmAscent,           TRUE);
    SetDlgItemInt(hdlg, IDC_TM_DESCENT,  pdp.tm.tmDescent,          TRUE);
    SetDlgItemInt(hdlg, IDC_TM_INTLEAD,  pdp.tm.tmInternalLeading,  TRUE);
    SetDlgItemInt(hdlg, IDC_TM_EXTLEAD,  pdp.tm.tmExternalLeading,  TRUE);
    SetDlgItemInt(hdlg, IDC_TM_AVECHAR,  pdp.tm.tmAveCharWidth,     TRUE);
    SetDlgItemInt(hdlg, IDC_TM_MAXCHAR,  pdp.tm.tmMaxCharWidth,     TRUE);
    SetDlgItemInt(hdlg, IDC_TM_WEIGHT,   pdp.tm.tmWeight,           TRUE);
    SetDlgItemInt(hdlg, IDC_TM_OVERHANG, pdp.tm.tmOverhang,         TRUE);
    SetDlgItemInt(hdlg, IDC_TM_DIGASPX,  pdp.tm.tmDigitizedAspectX, TRUE);
    SetDlgItemInt(hdlg, IDC_TM_DIGASPY,  pdp.tm.tmDigitizedAspectY, TRUE);

    szBuffer = format(BCHARFORM, pdp.tm.tmFirstChar);
    SetDlgItemText(hdlg, IDC_TM_FIRSTCHAR, szBuffer.toUTF16z);

    szBuffer = format(BCHARFORM, pdp.tm.tmLastChar);
    SetDlgItemText(hdlg, IDC_TM_LASTCHAR, szBuffer.toUTF16z);

    szBuffer = format(BCHARFORM, pdp.tm.tmDefaultChar);
    SetDlgItemText(hdlg, IDC_TM_DEFCHAR, szBuffer.toUTF16z);

    szBuffer = format(BCHARFORM, pdp.tm.tmBreakChar);
    SetDlgItemText(hdlg, IDC_TM_BREAKCHAR, szBuffer.toUTF16z);

    SetDlgItemText(hdlg, IDC_TM_ITALIC, pdp.tm.tmItalic     ? szYes : szNo);
    SetDlgItemText(hdlg, IDC_TM_UNDER,  pdp.tm.tmUnderlined ? szYes : szNo);
    SetDlgItemText(hdlg, IDC_TM_STRUCK, pdp.tm.tmStruckOut  ? szYes : szNo);

    SetDlgItemText(hdlg, IDC_TM_VARIABLE,
                   TMPF_FIXED_PITCH & pdp.tm.tmPitchAndFamily ? szYes : szNo);

    SetDlgItemText(hdlg, IDC_TM_VECTOR,
                   TMPF_VECTOR & pdp.tm.tmPitchAndFamily ? szYes : szNo);

    SetDlgItemText(hdlg, IDC_TM_TRUETYPE,
                   TMPF_TRUETYPE & pdp.tm.tmPitchAndFamily ? szYes : szNo);

    SetDlgItemText(hdlg, IDC_TM_DEVICE,
                   TMPF_DEVICE & pdp.tm.tmPitchAndFamily ? szYes : szNo);

    SetDlgItemText(hdlg, IDC_TM_FAMILY,
                   szFamily[min(6, pdp.tm.tmPitchAndFamily >> 4)].toUTF16z);

    SetDlgItemInt(hdlg, IDC_TM_CHARSET,   pdp.tm.tmCharSet, FALSE);
    SetDlgItemText(hdlg, IDC_TM_FACENAME, pdp.szFaceName.ptr);
}

void MySetMapMode(HDC hdc, int iMapMode)
{
    switch (iMapMode)
    {
        case IDC_MM_TEXT:
            SetMapMode(hdc, MM_TEXT);       
            break;

        case IDC_MM_LOMETRIC:
            SetMapMode(hdc, MM_LOMETRIC);   
            break;

        case IDC_MM_HIMETRIC:
            SetMapMode(hdc, MM_HIMETRIC);   
            break;

        case IDC_MM_LOENGLISH:
            SetMapMode(hdc, MM_LOENGLISH);  
            break;

        case IDC_MM_HIENGLISH:
            SetMapMode(hdc, MM_HIENGLISH);  
            break;

        case IDC_MM_TWIPS:
            SetMapMode(hdc, MM_TWIPS);      
            break;

        case IDC_MM_LOGTWIPS:
            SetMapMode(hdc, MM_ANISOTROPIC);
            SetWindowExtEx(hdc, 1440, 1440, NULL);
            SetViewportExtEx(hdc, GetDeviceCaps(hdc, LOGPIXELSX),
                             GetDeviceCaps(hdc, LOGPIXELSY), NULL);
            break;
        
        default:
    }
}
