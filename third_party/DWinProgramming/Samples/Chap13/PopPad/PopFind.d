/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module PopFind;

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
pragma(lib, "winmm.lib");
pragma(lib, "advapi32.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.commdlg;
import win32.mmsystem;

enum MAX_STRING_LEN = 256;

wchar[MAX_STRING_LEN] szFindText = 0;
wchar[MAX_STRING_LEN] szReplText = 0;

wstring fromWStringz(const wchar* s)
{
    if (s is null)
        return null;

    wchar* ptr;

    for (ptr = cast(wchar*)s; *ptr; ++ptr)
    {
    }

    return to!wstring(s[0..ptr - s]);
}

HWND PopFindFindDlg(HWND hwnd)
{
    static FINDREPLACE fr;         // must be static for modeless dialog

    fr.hwndOwner        = hwnd;
    fr.hInstance        = NULL;
    fr.Flags            = FR_HIDEUPDOWN | FR_HIDEMATCHCASE | FR_HIDEWHOLEWORD;
    fr.lpstrFindWhat    = szFindText.ptr;
    fr.lpstrReplaceWith = NULL;
    fr.wFindWhatLen     = MAX_STRING_LEN;
    fr.wReplaceWithLen  = 0;
    fr.lCustData        = 0;
    fr.lpfnHook         = NULL;
    fr.lpTemplateName   = NULL;

    return FindText(&fr);
}

HWND PopFindReplaceDlg(HWND hwnd)
{
    static FINDREPLACE fr;         // must be static for modeless dialog

    fr.hwndOwner        = hwnd;
    fr.hInstance        = NULL;
    fr.Flags            = FR_HIDEUPDOWN | FR_HIDEMATCHCASE | FR_HIDEWHOLEWORD;
    fr.lpstrFindWhat    = szFindText.ptr;
    fr.lpstrReplaceWith = szReplText.ptr;
    fr.wFindWhatLen     = MAX_STRING_LEN;
    fr.wReplaceWithLen  = MAX_STRING_LEN;
    fr.lCustData        = 0;
    fr.lpfnHook         = NULL;
    fr.lpTemplateName   = NULL;

    return ReplaceText(&fr);
}

BOOL PopFindFindText(HWND hwndEdit, int* piSearchOffset, LPFINDREPLACE pfr)
{
    int iLength, iPos;
    PTSTR pstrDoc, pstrPos;

    // Read in the edit document
    iLength = GetWindowTextLength(hwndEdit);
    pstrDoc = cast(PTSTR)GC.malloc((iLength + 1) * TCHAR.sizeof);
    if (pstrDoc is null)
        return FALSE;

    GetWindowText(hwndEdit, pstrDoc, iLength + 1);

    // Search the document for the find string
    auto needle = fromWStringz(pfr.lpstrFindWhat);
    auto str = pstrDoc[0..iLength];
    auto pos = str[*piSearchOffset..$].indexOf(needle);
        
    // Return an error code if the string cannot be found
    if (pos == -1) return FALSE;

    // Find the position in the document and the new start offset
    auto oldPos = *piSearchOffset + pos;
    *piSearchOffset += pos + needle.count;

    // Select the found text
    SendMessage(hwndEdit, EM_SETSEL, oldPos, *piSearchOffset);
    SendMessage(hwndEdit, EM_SCROLLCARET, 0, 0);

    return TRUE;
}

BOOL PopFindNextText(HWND hwndEdit, int* piSearchOffset)
{
    FINDREPLACE fr;

    fr.lpstrFindWhat = szFindText.ptr;

    return PopFindFindText(hwndEdit, piSearchOffset, &fr);
}

BOOL PopFindReplaceText(HWND hwndEdit, int* piSearchOffset, LPFINDREPLACE pfr)
{
    // Find the text
    if (!PopFindFindText(hwndEdit, piSearchOffset, pfr))
        return FALSE;

    // Replace it
    SendMessage(hwndEdit, EM_REPLACESEL, 0, cast(LPARAM)pfr.lpstrReplaceWith);

    return TRUE;
}

BOOL PopFindValidFind()
{
    return *(szFindText.ptr);
}
