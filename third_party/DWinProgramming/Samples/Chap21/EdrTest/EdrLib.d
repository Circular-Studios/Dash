module EdrLib;

pragma(lib, "gdi32.lib");
pragma(lib, "comdlg32.lib");
import win32.windef;
import win32.wingdi;
import std.utf : count, toUTFz;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

export extern(Windows) BOOL EdrCenterText(HDC hdc, PRECT prc, string pString)
{
    SIZE size;
    GetTextExtentPoint32(hdc, toUTF16z(pString), pString.count, &size);
    return TextOut(hdc, (prc.right - prc.left - size.cx) / 2,
                        (prc.bottom - prc.top - size.cy) / 2, toUTF16z(pString), pString.count);
}
