/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module TestMci;

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

string appName     = "TestMci";
string description = "MCI Command String Tester";
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
    if (DialogBox(hInstance, appName.toUTF16z, NULL, &DlgProc) == -1)
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
    }

    return 0;
}

enum ID_TIMER = 1;

extern (Windows)
BOOL DlgProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HWND hwndEdit;
    int iCharBeg, iCharEnd, iLineBeg, iLineEnd, iChar, iLine, iLength;
    MCIERROR error;
    RECT  rect;
    TCHAR[1024] szCommand;
    TCHAR[1024] szReturn;
    TCHAR[1024] szError;
    string szBuffer;

    switch (message)
    {
        case WM_INITDIALOG:
            // Center the window on screen
            GetWindowRect(hwnd, &rect);
            SetWindowPos(hwnd, NULL,
                         (GetSystemMetrics(SM_CXSCREEN) - rect.right + rect.left) / 2,
                         (GetSystemMetrics(SM_CYSCREEN) - rect.bottom + rect.top) / 2,
                         0, 0, SWP_NOZORDER | SWP_NOSIZE);

            hwndEdit = GetDlgItem(hwnd, IDC_MAIN_EDIT);
            SetFocus(hwndEdit);
            return FALSE;

        case WM_COMMAND:
            
            switch (LOWORD(wParam))
            {
                case IDOK:
                    // Find the line numbers corresponding to the selection

                    SendMessage(hwndEdit, EM_GETSEL, cast(WPARAM)&iCharBeg,
                                cast(LPARAM)&iCharEnd);

                    iLineBeg = SendMessage(hwndEdit, EM_LINEFROMCHAR, iCharBeg, 0);
                    iLineEnd = SendMessage(hwndEdit, EM_LINEFROMCHAR, iCharEnd, 0);

                    // Loop through all the lines
                    for (iLine = iLineBeg; iLine <= iLineEnd; iLine++)
                    {
                        // Get the line and terminate it; ignore if blank
                        *cast(WORD*)szCommand = szCommand.sizeof / TCHAR.sizeof;

                        iLength = SendMessage(hwndEdit, EM_GETLINE, iLine, cast(LPARAM)szCommand.ptr);
                        szCommand[iLength] = 0;

                        if (iLength == 0)
                            continue;

                        // Send the MCI command
                        error = mciSendString(szCommand.ptr, szReturn.ptr, szReturn.sizeof / TCHAR.sizeof, hwnd);

                        // Set the Return String field
                        SetDlgItemText(hwnd, IDC_RETURN_STRING, szReturn.ptr);

                        // Set the Error String field (even if no error)
                        mciGetErrorString(error, szError.ptr, szError.sizeof / TCHAR.sizeof);

                        SetDlgItemText(hwnd, IDC_ERROR_STRING, szError.ptr);
                    }

                    // Send the caret to the end of the last selected line
                    iChar  = SendMessage(hwndEdit, EM_LINEINDEX, iLineEnd, 0);
                    iChar += SendMessage(hwndEdit, EM_LINELENGTH, iCharEnd, 0);
                    SendMessage(hwndEdit, EM_SETSEL, iChar, iChar);

                    // Insert a carriage return/line feed combination
                    SendMessage(hwndEdit, EM_REPLACESEL, FALSE,
                                cast(LPARAM)"\r\n\0".dup.ptr);
                    SetFocus(hwndEdit);
                    return TRUE;

                case IDCANCEL:
                    EndDialog(hwnd, 0);
                    return TRUE;

                case IDC_MAIN_EDIT:

                    if (HIWORD(wParam) == EN_ERRSPACE)
                    {
                        MessageBox(hwnd, "Error control out of space.",
                                   appName.toUTF16z, MB_OK | MB_ICONINFORMATION);
                        return TRUE;
                    }

                    break;
                    
                default:
            }

            break;

        case MM_MCINOTIFY:
            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_MESSAGE), TRUE);

            szBuffer = format("Device ID = %s", lParam);
            SetDlgItemText(hwnd, IDC_NOTIFY_ID, szBuffer.toUTF16z);
            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_ID), TRUE);

            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_SUCCESSFUL),
                         wParam & MCI_NOTIFY_SUCCESSFUL);

            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_SUPERSEDED),
                         wParam & MCI_NOTIFY_SUPERSEDED);

            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_ABORTED),
                         wParam & MCI_NOTIFY_ABORTED);

            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_FAILURE),
                         wParam & MCI_NOTIFY_FAILURE);

            SetTimer(hwnd, ID_TIMER, 5000, NULL);
            return TRUE;

        case WM_TIMER:
            KillTimer(hwnd, ID_TIMER);

            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_MESSAGE), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_ID), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_SUCCESSFUL), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_SUPERSEDED), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_ABORTED), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_NOTIFY_FAILURE), FALSE);
            return TRUE;

        case WM_SYSCOMMAND:

            switch (LOWORD(wParam))
            {
                case SC_CLOSE:
                    EndDialog(hwnd, 0);
                    return TRUE;
                
                default:
            }

            break;
            
        default:
    }

    return FALSE;
}
