/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module PopPrnt;

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

import resource;

BOOL bUserAbort;
HWND hDlgPrint;

extern (Windows)
BOOL PrintDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg)
    {
        case WM_INITDIALOG:
            EnableMenuItem(GetSystemMenu(hDlg, FALSE), SC_CLOSE, MF_GRAYED);
            return TRUE;

        case WM_COMMAND:
            bUserAbort = TRUE;
            EnableWindow(GetParent(hDlg), TRUE);
            DestroyWindow(hDlg);
            hDlgPrint = NULL;
            return TRUE;
        
        default:
    }

    return FALSE;
}

extern (Windows)
BOOL AbortProc(HDC hPrinterDC, int iCode)
{
    MSG msg;

    while (!bUserAbort && PeekMessage(&msg, NULL, 0, 0, PM_REMOVE))
    {
        if (!hDlgPrint || !IsDialogMessage(hDlgPrint, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return !bUserAbort;
}

BOOL PopPrntPrintFile(HINSTANCE hInst, HWND hwnd, HWND hwndEdit, PTSTR szTitleName)
{
    static DOCINFO  di = DOCINFO(DOCINFO.sizeof);
    static PRINTDLG pd;
    BOOL bSuccess;
    int  yChar, iCharsPerLine, iLinesPerPage, iTotalLines, iTotalPages, iPage, iLine, iLineNum;
    PTSTR pstrBuffer;
    TCHAR[64 + MAX_PATH] szJobName;
    TEXTMETRIC tm;
    WORD iColCopy, iNoiColCopy;

    // Invoke Print common dialog box
    pd.hwndOwner   = hwnd;
    pd.hDevMode    = NULL;
    pd.hDevNames   = NULL;
    pd.hDC         = NULL;
    pd.Flags       = PD_ALLPAGES | PD_COLLATE |
                     PD_RETURNDC | PD_NOSELECTION;
    
    pd.nFromPage = 0;
    pd.nToPage = 0;
    pd.nMinPage = 0;
    pd.nMaxPage = 0;
    pd.nCopies = 1;
    pd.hInstance = NULL;
    pd.lCustData = 0L;
    pd.lpfnPrintHook       = NULL;
    pd.lpfnSetupHook       = NULL;
    pd.lpPrintTemplateName = NULL;
    pd.lpSetupTemplateName = NULL;
    pd.hPrintTemplate      = NULL;
    pd.hSetupTemplate      = NULL;

    if (!PrintDlg(&pd))
        return TRUE;

    iTotalLines = SendMessage(hwndEdit, EM_GETLINECOUNT, 0, 0);
    if (iTotalLines == 0)
        return TRUE;

    // Calculate necessary metrics for file
    GetTextMetrics(pd.hDC, &tm);
    yChar = tm.tmHeight + tm.tmExternalLeading;

    iCharsPerLine = GetDeviceCaps(pd.hDC, HORZRES) / tm.tmAveCharWidth;
    iLinesPerPage = GetDeviceCaps(pd.hDC, VERTRES) / yChar;
    iTotalPages   = (iTotalLines + iLinesPerPage - 1) / iLinesPerPage;

    // Allocate a buffer for each line of text
    pstrBuffer = cast(typeof(pstrBuffer))GC.malloc(TCHAR.sizeof * (iCharsPerLine + 1));

    // Display the printing dialog box
    EnableWindow(hwnd, FALSE);

    bSuccess   = TRUE;
    bUserAbort = FALSE;

    hDlgPrint = CreateDialog(hInst, "PrintDlgBox", hwnd, &PrintDlgProc);

    SetDlgItemText(hDlgPrint, IDC_FILENAME, szTitleName);
    
    // @BUG@ WindowsAPI callbacks are not defined properly:
    //     alias BOOL function(HDC, int) ABORTPROC;
    //
    // should be:
    //     alias extern(Windows) BOOL function(HDC, int) ABORTPROC;    
    SetAbortProc(pd.hDC, cast(BOOL function(HDC, int))&AbortProc);

    // Start the document
    GetWindowText(hwnd, szJobName.ptr, szJobName.sizeof);
    di.lpszDocName = szJobName.ptr;

    if (StartDoc(pd.hDC, &di) > 0)
    {
        // Collation requires this loop and iNoiColCopy
        for (iColCopy = 0;
             iColCopy < (cast(WORD)pd.Flags & PD_COLLATE ? pd.nCopies : 1);
             iColCopy++)
        {
            for (iPage = 0; iPage < iTotalPages; iPage++)
            {
                for (iNoiColCopy = 0;
                     iNoiColCopy < (pd.Flags & PD_COLLATE ? 1 : pd.nCopies);
                     iNoiColCopy++)
                {
                    // Start the page
                    if (StartPage(pd.hDC) < 0)
                    {
                        bSuccess = FALSE;
                        break;
                    }

                    // For each page, print the lines
                    for (iLine = 0; iLine < iLinesPerPage; iLine++)
                    {
                        iLineNum = iLinesPerPage * iPage + iLine;

                        if (iLineNum > iTotalLines)
                            break;

                        *cast(int*)pstrBuffer = iCharsPerLine;

                        TextOut(pd.hDC, 0, yChar * iLine, pstrBuffer,
                                cast(int)SendMessage(hwndEdit, EM_GETLINE,
                                                 cast(WPARAM)iLineNum, cast(LPARAM)pstrBuffer));
                    }

                    if (EndPage(pd.hDC) < 0)
                    {
                        bSuccess = FALSE;
                        break;
                    }

                    if (bUserAbort)
                        break;
                }

                if (!bSuccess || bUserAbort)
                    break;
            }

            if (!bSuccess || bUserAbort)
                break;
        }
    }
    else
        bSuccess = FALSE;

    if (bSuccess)
        EndDoc(pd.hDC);

    if (!bUserAbort)
    {
        EnableWindow(hwnd, TRUE);
        DestroyWindow(hDlgPrint);
    }

    GC.free(pstrBuffer);
    DeleteDC(pd.hDC);

    return bSuccess && !bUserAbort;
}
