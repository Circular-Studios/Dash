/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module PopFile;

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
pragma(lib, "winmm.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.commdlg;
import win32.mmsystem;
import win32.winnls;

LOGFONT logfont;
HFONT hFont;
OPENFILENAME ofn;

void PopFileInitialize(HWND hwnd)
{
    static string szFilter = "Text Files (*.TXT)\0*.txt\0"
                             "ASCII Files (*.ASC)\0*.asc\0"
                             "All Files (*.*)\0*.*\0\0";

    ofn.hwndOwner         = hwnd;
    ofn.hInstance         = NULL;
    ofn.lpstrFilter       = szFilter.toUTF16z;
    ofn.lpstrCustomFilter = NULL;
    ofn.nMaxCustFilter    = 0;
    ofn.nFilterIndex      = 0;
    ofn.lpstrFile         = NULL;            // Set in Open and Close functions
    ofn.nMaxFile          = MAX_PATH;
    ofn.lpstrFileTitle    = NULL;            // Set in Open and Close functions
    ofn.nMaxFileTitle     = MAX_PATH;
    ofn.lpstrInitialDir   = NULL;
    ofn.lpstrTitle        = NULL;
    ofn.Flags             = 0;               // Set in Open and Close functions
    ofn.nFileOffset       = 0;
    ofn.nFileExtension    = 0;
    ofn.lpstrDefExt       = "txt";
    ofn.lCustData         = 0L;
    ofn.lpfnHook          = NULL;
    ofn.lpTemplateName    = NULL;
}

BOOL PopFileOpenDlg(HWND hwnd, PTSTR pstrFileName, PTSTR pstrTitleName)
{
    ofn.hwndOwner      = hwnd;
    ofn.lpstrFile      = pstrFileName;
    ofn.lpstrFileTitle = pstrTitleName;
    ofn.Flags          = OFN_HIDEREADONLY | OFN_CREATEPROMPT;

    return GetOpenFileName(&ofn);
}

BOOL PopFileSaveDlg(HWND hwnd, PTSTR pstrFileName, PTSTR pstrTitleName)
{
    ofn.hwndOwner      = hwnd;
    ofn.lpstrFile      = pstrFileName;
    ofn.lpstrFileTitle = pstrTitleName;
    ofn.Flags          = OFN_OVERWRITEPROMPT;

    return GetSaveFileName(&ofn);
}

BOOL PopFileRead(HWND hwndEdit, PTSTR pstrFileName)
{
    BYTE   bySwap;
    DWORD  dwBytesRead;
    HANDLE hFile;
    int i, iFileLength, iUniTest;
    PBYTE pBuffer, pText, pConv;

    // Open the file.
    if (INVALID_HANDLE_VALUE ==
        (hFile = CreateFile(pstrFileName, GENERIC_READ, FILE_SHARE_READ,
                            NULL, OPEN_EXISTING, 0, NULL)))
        return FALSE;

    // Get file size in bytes and allocate memory for read.
    // Add an extra two bytes for zero termination.
    iFileLength = GetFileSize(hFile, NULL);
    pBuffer     = cast(typeof(pBuffer))GC.malloc(iFileLength + 2);

    // Read file and put terminating zeros at end.
    ReadFile(hFile, pBuffer, iFileLength, &dwBytesRead, NULL);
    CloseHandle(hFile);
    pBuffer[iFileLength]     = 0;
    pBuffer[iFileLength + 1] = 0;

    // Test to see if the text is Unicode
    iUniTest = IS_TEXT_UNICODE_SIGNATURE | IS_TEXT_UNICODE_REVERSE_SIGNATURE;

    if (IsTextUnicode(pBuffer, iFileLength, &iUniTest))
    {
        pText        = pBuffer + 2;
        iFileLength -= 2;

        if (iUniTest & IS_TEXT_UNICODE_REVERSE_SIGNATURE)
        {
            for (i = 0; i < iFileLength / 2; i++)
            {
                bySwap = (cast(BYTE*)pText) [2 * i];
                (cast(BYTE*)pText) [2 * i]     = (cast(BYTE*)pText) [2 * i + 1];
                (cast(BYTE*)pText) [2 * i + 1] = bySwap;
            }
        }

        // Allocate memory for possibly converted string
        pConv = cast(typeof(pConv))GC.malloc(iFileLength + 2);

        // If the edit control is not Unicode, convert Unicode text to
        // non-Unicode (ie, in general, wide character).

        lstrcpy(cast(PTSTR)pConv, cast(PTSTR)pText);

    }
    else  // the file is not Unicode
    {
        pText = pBuffer;

        // Allocate memory for possibly converted string.
        pConv = cast(typeof(pConv))GC.malloc(2 * iFileLength + 2);

        // If the edit control is Unicode, convert ASCII text.
        MultiByteToWideChar(CP_ACP, 0, cast(char*)pText, -1, cast(PTSTR)pConv, iFileLength + 1);

        // If not, just copy buffer

    }

    SetWindowText(hwndEdit, cast(PTSTR)pConv);
    GC.free(pBuffer);
    GC.free(pConv);

    return TRUE;
}

BOOL PopFileWrite(HWND hwndEdit, PTSTR pstrFileName)
{
    DWORD  dwBytesWritten;
    HANDLE hFile;
    int iLength;
    PTSTR pstrBuffer;
    WORD  wByteOrderMark = 0xFEFF;

    // Open the file, creating it if necessary
    if (INVALID_HANDLE_VALUE ==
        (hFile = CreateFile(pstrFileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL)))
        return FALSE;

    // Get the number of characters in the edit control and allocate
    // memory for them.
    iLength    = GetWindowTextLength(hwndEdit);
    pstrBuffer = cast(PTSTR)GC.malloc((iLength + 1) * TCHAR.sizeof);

    if (!pstrBuffer)
    {
        CloseHandle(hFile);
        return FALSE;
    }

    // If the edit control will return Unicode text, write the
    // byte order mark to the file.
    WriteFile(hFile, &wByteOrderMark, 2, &dwBytesWritten, NULL);

    // Get the edit buffer and write that out to the file.
    GetWindowText(hwndEdit, pstrBuffer, iLength + 1);
    WriteFile(hFile, pstrBuffer, iLength * TCHAR.sizeof,
              &dwBytesWritten, NULL);

    if ((iLength * TCHAR.sizeof) != cast(int)dwBytesWritten)
    {
        CloseHandle(hFile);
        GC.free(pstrBuffer);
        return FALSE;
    }

    CloseHandle(hFile);
    GC.free(pstrBuffer);

    return TRUE;
}
