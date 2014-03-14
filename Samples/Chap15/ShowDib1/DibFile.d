/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module DibFile;

import core.memory;
import std.utf;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.commdlg;

static OPENFILENAME ofn;

void DibFileInitialize(HWND hwnd)
{
    enum szFilter = "Bitmap Files (*.BMP)\0*.bmp\0All Files (*.*)\0*.*\0\0";

    ofn.lStructSize       = (OPENFILENAME.sizeof);
    ofn.hwndOwner         = hwnd;
    ofn.hInstance         = NULL;
    ofn.lpstrFilter       = szFilter;
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
    ofn.lpstrDefExt       = "bmp";
    ofn.lCustData         = 0;
    ofn.lpfnHook          = NULL;
    ofn.lpTemplateName    = NULL;
}

BOOL DibFileOpenDlg(HWND hwnd, PTSTR pstrFileName, PTSTR pstrTitleName)
{
    ofn.hwndOwner      = hwnd;
    ofn.lpstrFile      = pstrFileName;
    ofn.lpstrFileTitle = pstrTitleName;
    ofn.Flags          = 0;

    return GetOpenFileName(&ofn);
}

BOOL DibFileSaveDlg(HWND hwnd, PTSTR pstrFileName, PTSTR pstrTitleName)
{
    ofn.hwndOwner      = hwnd;
    ofn.lpstrFile      = pstrFileName;
    ofn.lpstrFileTitle = pstrTitleName;
    ofn.Flags          = OFN_OVERWRITEPROMPT;

    return GetSaveFileName(&ofn);
}

BITMAPFILEHEADER* DibLoadImage(string pstrFileName)
{
    BOOL   bSuccess;
    DWORD  dwFileSize, dwHighSize, dwBytesRead;
    HANDLE hFile;
    BITMAPFILEHEADER* pbmfh;

    hFile = CreateFile(pstrFileName.toUTF16z, GENERIC_READ, FILE_SHARE_READ, NULL,
                       OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL);

    if (hFile == INVALID_HANDLE_VALUE)
        return NULL;

    dwFileSize = GetFileSize(hFile, &dwHighSize);

    if (dwHighSize)
    {
        CloseHandle(hFile);
        return NULL;
    }

    pbmfh = cast(typeof(pbmfh))GC.malloc(dwFileSize);

    if (!pbmfh)
    {
        CloseHandle(hFile);
        return NULL;
    }

    bSuccess = ReadFile(hFile, pbmfh, dwFileSize, &dwBytesRead, NULL);
    CloseHandle(hFile);

    if (!bSuccess || (dwBytesRead != dwFileSize)
        || (pbmfh.bfType != *cast(WORD*)"BM")
        || (pbmfh.bfSize != dwFileSize))
    {
        GC.free(pbmfh);
        return NULL;
    }

    return pbmfh;
}

BOOL DibSaveImage(PTSTR pstrFileName, BITMAPFILEHEADER* pbmfh)
{
    BOOL   bSuccess;
    DWORD  dwBytesWritten;
    HANDLE hFile;

    hFile = CreateFile(pstrFileName, GENERIC_WRITE, 0, NULL,
                       CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);

    if (hFile == INVALID_HANDLE_VALUE)
        return FALSE;

    bSuccess = WriteFile(hFile, pbmfh, pbmfh.bfSize, &dwBytesWritten, NULL);
    CloseHandle(hFile);

    if (!bSuccess || (dwBytesWritten != pbmfh.bfSize))
    {
        DeleteFile(pstrFileName);
        return FALSE;
    }

    return TRUE;
}
