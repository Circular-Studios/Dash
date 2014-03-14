/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module EZFont;

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

enum EZ_ATTR_BOLD         = 1;
enum EZ_ATTR_ITALIC       = 2;
enum EZ_ATTR_UNDERLINE    = 4;
enum EZ_ATTR_STRIKEOUT    = 8;

HFONT EzCreateFont(HDC hdc, string szFaceName, int iDeciPtHeight,
                   int iDeciPtWidth, int iAttributes, BOOL fLogRes)
{
    FLOAT cxDpi, cyDpi;
    HFONT hFont;
    LOGFONT lf;
    POINT pt;
    TEXTMETRIC tm;

    SaveDC(hdc);

    SetGraphicsMode(hdc, GM_ADVANCED);
    ModifyWorldTransform(hdc, NULL, MWT_IDENTITY);
    SetViewportOrgEx(hdc, 0, 0, NULL);
    SetWindowOrgEx(hdc, 0, 0, NULL);

    if (fLogRes)
    {
        cxDpi = cast(FLOAT)GetDeviceCaps(hdc, LOGPIXELSX);
        cyDpi = cast(FLOAT)GetDeviceCaps(hdc, LOGPIXELSY);
    }
    else
    {
        cxDpi = cast(FLOAT)(25.4 * GetDeviceCaps(hdc, HORZRES) /
                        GetDeviceCaps(hdc, HORZSIZE));

        cyDpi = cast(FLOAT)(25.4 * GetDeviceCaps(hdc, VERTRES) /
                        GetDeviceCaps(hdc, VERTSIZE));
    }

    pt.x = cast(int)(iDeciPtWidth * cxDpi / 72);
    pt.y = cast(int)(iDeciPtHeight * cyDpi / 72);

    DPtoLP(hdc, &pt, 1);

    lf.lfHeight         = -cast(int)(fabs(pt.y) / 10.0 + 0.5);
    lf.lfWidth          = 0;
    lf.lfEscapement     = 0;
    lf.lfOrientation    = 0;
    lf.lfWeight         = iAttributes & EZ_ATTR_BOLD      ? 700 : 0;
    lf.lfItalic         = iAttributes & EZ_ATTR_ITALIC    ?   1 : 0;
    lf.lfUnderline      = iAttributes & EZ_ATTR_UNDERLINE ?   1 : 0;
    lf.lfStrikeOut      = iAttributes & EZ_ATTR_STRIKEOUT ?   1 : 0;
    lf.lfCharSet        = DEFAULT_CHARSET;
    lf.lfOutPrecision   = 0;
    lf.lfClipPrecision  = 0;
    lf.lfQuality        = 0;
    lf.lfPitchAndFamily = 0;

    
    lf.lfFaceName[] = ' ';
    
    // unsure about this, investigate
    lf.lfFaceName[0..szFaceName.length] = szFaceName.toUTF16;

    hFont = CreateFontIndirect(&lf);

    if (iDeciPtWidth != 0)
    {
        hFont = cast(HFONT)SelectObject(hdc, hFont);

        GetTextMetrics(hdc, &tm);

        DeleteObject(SelectObject(hdc, hFont));

        lf.lfWidth = cast(int)(tm.tmAveCharWidth *
                           fabs(pt.x) / fabs(pt.y) + 0.5);

        hFont = CreateFontIndirect(&lf);
    }

    RestoreDC(hdc, -1);
    return hFont;
}
