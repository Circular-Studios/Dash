/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module DrumFile;

import core.memory;
import core.runtime;
import core.thread;
import std.algorithm : min, max;

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
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.commdlg;
import win32.mmsystem;

import DrumTime;

OPENFILENAME ofn;

// The API expects these to be arrays of pointers.
const TCHAR*[3] szFilter =
[
    "Drum Files (*.DRM)\0"w.ptr,
    "*.drm\0"w.ptr,
    "\0"w.ptr
];

wchar* szDrumID;
wchar* szListID;
wchar* szInfoID;
wchar* szSoftID;
wchar* szDateID;
wchar* szFmtID;
wchar* szDataID;
char* szSoftware;
wchar* szErrorNoCreate;
wchar* szErrorCannotWrite;
wchar* szErrorNotFound;
wchar* szErrorNotDrum;
wchar* szErrorUnsupported;
wchar* szErrorCannotRead;

static this()
{
    szDrumID   = cast(wchar*)"DRUM".toUTF16z;
    szListID   = cast(wchar*)"LIST".toUTF16z;
    szInfoID   = cast(wchar*)"INFO".toUTF16z;
    szSoftID   = cast(wchar*)"ISFT".toUTF16z;
    szDateID   = cast(wchar*)"ISCD".toUTF16z;
    szFmtID    = cast(wchar*)"fmt ".toUTF16z;
    szDataID   = cast(wchar*)"data".toUTF16z;
    szSoftware = cast(char*)"DRUM by Charles Petzold, Programming Windows".toStringz;    
    
    szErrorNoCreate    = cast(wchar*)"File %s could not be opened for writing.".toUTF16z;
    szErrorCannotWrite = cast(wchar*)"File %s could not be written to.".toUTF16z;
    szErrorNotFound    = cast(wchar*)"File %s not found or cannot be opened.".toUTF16z;
    szErrorNotDrum     = cast(wchar*)"File %s is not a standard DRUM file.".toUTF16z;
    szErrorUnsupported = cast(wchar*)"File %s is not a supported DRUM file.".toUTF16z;
    szErrorCannotRead  = cast(wchar*)"File %s cannot be read.".toUTF16z;    
}

BOOL DrumFileOpenDlg(HWND hwnd, wchar* szFileName, wchar* szTitleName)
{
    ofn.hwndOwner      = hwnd;
    ofn.lpstrFilter    = szFilter[0];
    ofn.lpstrFile      = szFileName;
    ofn.nMaxFile       = MAX_PATH;
    ofn.lpstrFileTitle = szTitleName;
    ofn.nMaxFileTitle  = MAX_PATH;
    ofn.Flags          = OFN_CREATEPROMPT;
    ofn.lpstrDefExt    = "drm".toUTF16z;

    return GetOpenFileName(&ofn);
}

BOOL DrumFileSaveDlg(HWND hwnd, TCHAR* szFileName, TCHAR* szTitleName)
{
    ofn.hwndOwner      = hwnd;
    ofn.lpstrFilter    = szFilter[0];
    ofn.lpstrFile      = szFileName;
    ofn.nMaxFile       = MAX_PATH;
    ofn.lpstrFileTitle = szTitleName;
    ofn.nMaxFileTitle  = MAX_PATH;
    ofn.Flags          = OFN_OVERWRITEPROMPT;
    ofn.lpstrDefExt    = "drm".toUTF16z;

    return GetSaveFileName(&ofn);
}

wstring fromWStringz(const wchar* s)
{
    if (s is null) return null;

    wchar* ptr;
    for (ptr = cast(wchar*)s; *ptr; ++ptr) {}

    return to!wstring(s[0..ptr-s]);
}

TCHAR* DrumFileWrite(DRUM* pdrum, TCHAR* szFileName)
{
    // replace wError |= with enforce, and do scope(failure).
    string szDateBuf;
    HMMIO  hmmio;
    int iFormat = 2;
    MMCKINFO[3] mmckinfo;
    SYSTEMTIME st;
    WORD wError = 0;

    // Recreate the file for writing
    hmmio = mmioOpen(szFileName, NULL, MMIO_CREATE | MMIO_WRITE | MMIO_ALLOCBUF);
    if (hmmio == NULL)
        return szErrorNoCreate;

    // Create a "RIFF" chunk with a "CPDR" type
    mmckinfo[0].fccType = mmioStringToFOURCC(szDrumID, 0);

    wError |= mmioCreateChunk(hmmio, &mmckinfo[0], MMIO_CREATERIFF);
    // Create "LIST" sub-chunk with an "INFO" type

    mmckinfo[1].fccType = mmioStringToFOURCC(szInfoID, 0);

    wError |= mmioCreateChunk(hmmio, &mmckinfo[1], MMIO_CREATELIST);
    // Create "ISFT" sub-sub-chunk

    mmckinfo[2].ckid = mmioStringToFOURCC(szSoftID, 0);

    wError |= mmioCreateChunk(hmmio, &mmckinfo[2], 0);
    wError |= (mmioWrite(hmmio, szSoftware, szSoftware.sizeof) != szSoftware.sizeof);
    wError |= mmioAscend(hmmio, &mmckinfo[2], 0);

    GetLocalTime(&st);
    szDateBuf = format("%04d-%02d-%02d", st.wYear, st.wMonth, st.wDay);

    // Create "ISCD" sub-sub-chunk
    mmckinfo[2].ckid = mmioStringToFOURCC(szDateID, 0);

    wError |= mmioCreateChunk(hmmio, &mmckinfo[2], 0);
    wError |= (mmioWrite(hmmio, szDateBuf.toStringz, szDateBuf.count) != cast(int)(szDateBuf.count));
    wError |= mmioAscend(hmmio, &mmckinfo[2], 0);
    wError |= mmioAscend(hmmio, &mmckinfo[1], 0);

    // Create "fmt " sub-chunk
    mmckinfo[1].ckid = mmioStringToFOURCC(szFmtID, 0);

    wError |= mmioCreateChunk(hmmio, &mmckinfo[1], 0);
    wError |= (mmioWrite(hmmio, cast(PSTR)&iFormat, int.sizeof) != int.sizeof);
    wError |= mmioAscend(hmmio, &mmckinfo[1], 0);

    // Create the "data" sub-chunk
    mmckinfo[1].ckid = mmioStringToFOURCC(szDataID, 0);

    wError |= mmioCreateChunk(hmmio, &mmckinfo[1], 0);
    wError |= (mmioWrite(hmmio, cast(PSTR)pdrum, DRUM.sizeof) != DRUM.sizeof);
    wError |= mmioAscend(hmmio, &mmckinfo[1], 0);
    wError |= mmioAscend(hmmio, &mmckinfo[0], 0);

    // Clean up and return
    wError |= mmioClose(hmmio, 0);

    if (wError)
    {
        mmioOpen(szFileName, NULL, MMIO_DELETE);
        return szErrorCannotWrite;
    }

    return NULL;
}

TCHAR* DrumFileRead(DRUM* pdrum, TCHAR* szFileName)
{
    DRUM  drum;
    HMMIO hmmio;
    int i, iFormat;
    MMCKINFO[3] mmckinfo;

    // Open the file
    hmmio = mmioOpen(szFileName, NULL, MMIO_READ);
    if (hmmio == NULL)
        return szErrorNotFound;

    // Locate a "RIFF" chunk with a "DRUM" form-type
    mmckinfo[0].ckid = mmioStringToFOURCC(szDrumID, 0);

    if (mmioDescend(hmmio, &mmckinfo[0], NULL, MMIO_FINDRIFF))
    {
        mmioClose(hmmio, 0);
        return szErrorNotDrum;
    }

    // Locate, read, and verify the "fmt " sub-chunk
    mmckinfo[1].ckid = mmioStringToFOURCC(szFmtID, 0);
        
    if (mmioDescend(hmmio, &mmckinfo[1], &mmckinfo[0], MMIO_FINDCHUNK))
    {
        mmioClose(hmmio, 0);
        return szErrorNotDrum;
    }

    if (mmckinfo[1].cksize != int.sizeof)
    {
        mmioClose(hmmio, 0);
        return szErrorUnsupported;
    }

    if (mmioRead(hmmio, cast(PSTR)&iFormat, int.sizeof) != int.sizeof)
    {
        mmioClose(hmmio, 0);
        return szErrorCannotRead;
    }

    if (iFormat != 1 && iFormat != 2)
    {
        mmioClose(hmmio, 0);
        return szErrorUnsupported;
    }

    // Go to end of "fmt " sub-chunk
    mmioAscend(hmmio, &mmckinfo[1], 0);

    // Locate, read, and verify the "data" sub-chunk
    mmckinfo[1].ckid = mmioStringToFOURCC(szDataID, 0);
    //~ writeln((cast(char*)&mmckinfo[1].ckid)[0..4]);

    if (mmioDescend(hmmio, &mmckinfo[1], &mmckinfo[0], MMIO_FINDCHUNK))
    {
        mmioClose(hmmio, 0);
        return szErrorNotDrum;
    }

    if (mmckinfo[1].cksize != DRUM.sizeof)
    {
        mmioClose(hmmio, 0);
        return szErrorUnsupported;
    }

    if (mmioRead(hmmio, cast(LPSTR)&drum, DRUM.sizeof) != DRUM.sizeof)
    {
        mmioClose(hmmio, 0);
        return szErrorCannotRead;
    }
        
    // Close the file
    mmioClose(hmmio, 0);
    
    // Convert format 1 to format 2 and copy the DRUM structure data
    if (iFormat == 1)
    {
        for (i = 0; i < NUM_PERC; i++)
        {
            drum.dwSeqPerc [i] = drum.dwSeqPian [i];
            drum.dwSeqPian [i] = 0;
        }
    }

    *pdrum = drum;
    return NULL;
}
