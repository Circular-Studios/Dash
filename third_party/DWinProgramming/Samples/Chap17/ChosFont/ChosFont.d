/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module ChosFont;

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

string appName     = "ChosFont";
string description = "ChooseFont";
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

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static CHOOSEFONT cf;
    static int cyChar;
    static LOGFONT lf;
    dstring szText = "ABCDE abcde ÀÁÂÃÄÅ àáâãäå";

    HDC hdc;
    int y;
    PAINTSTRUCT ps;
    string szBuffer;
    TEXTMETRIC tm;

    switch (message)
    {
        case WM_CREATE:

            // Get height
            cyChar = HIWORD(GetDialogBaseUnits());

            // Initialize the LOGFONT structure
            GetObject(GetStockObject(SYSTEM_FONT), lf.sizeof, &lf);

            // Initialize the CHOOSEFONT structure
            cf.hwndOwner      = hwnd;
            cf.hDC            = NULL;
            cf.lpLogFont      = &lf;
            cf.iPointSize     = 0;
            cf.Flags          = CF_INITTOLOGFONTSTRUCT | CF_SCREENFONTS | CF_EFFECTS;
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

            switch (LOWORD(wParam))
            {
                case IDM_FONT:

                    if (ChooseFont(&cf))
                        InvalidateRect(hwnd, NULL, TRUE);

                    return 0;

                default:
            }

            return 0;

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);

            // Display sample using selected font
            SelectObject(hdc, CreateFontIndirect(&lf));
            GetTextMetrics(hdc, &tm);
            SetTextColor(hdc, cf.rgbColors);
            TextOut(hdc, 0, y = tm.tmExternalLeading, to!string(szText).toUTF16z, szText.count);

            // Display LOGFONT structure fields using system font
            DeleteObject(SelectObject(hdc, GetStockObject(SYSTEM_FONT)));
            SetTextColor(hdc, 0);

            szBuffer = format("lfHeight = %s", lf.lfHeight);
            TextOut(hdc, 0, y += tm.tmHeight, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfWidth = %s", lf.lfWidth);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfEscapement = %s", lf.lfEscapement);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfOrientation = %s", lf.lfOrientation);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfWeight = %s", lf.lfWeight);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfItalic = %s", lf.lfItalic);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfUnderline = %s", lf.lfUnderline);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfStrikeOut = %s", lf.lfStrikeOut);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfCharSet = %s", lf.lfCharSet);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfOutPrecision = %s", lf.lfOutPrecision);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfClipPrecision = %s", lf.lfClipPrecision);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfQuality = %s", lf.lfQuality);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfPitchAndFamily = 0x%02X", lf.lfPitchAndFamily);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            szBuffer = format("lfFaceName = %s", lf.lfFaceName);
            TextOut(hdc, 0, y += cyChar, szBuffer.toUTF16z, szBuffer.count);

            EndPaint(hwnd, &ps);
            return 0;
        }

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
