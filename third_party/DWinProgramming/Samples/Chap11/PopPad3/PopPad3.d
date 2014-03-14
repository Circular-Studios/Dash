/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module PopPad3;

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

import PopFile;
import PopFind;
import PopFont;

import resource;

string appName     = "PopPad";
string description = "name";
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
    wndclass.hIcon         = LoadIcon(hInstance, appName.toUTF16z);
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

    hAccel = LoadAccelerators(hInstance, appName.toUTF16z);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        if (hDlgModeless == NULL || !IsDialogMessage(hDlgModeless, &msg))
        {
            if (!TranslateAccelerator(hwnd, hAccel, &msg))
            {
                TranslateMessage(&msg);
                DispatchMessage(&msg);
            }
        }
    }    
    return msg.wParam;
}

enum EDITID   = 1;
enum UNTITLED = "(untitled)";

HWND hDlgModeless;

void DoCaption(HWND hwnd, string szTitleName)
{
    string szCaption;

    szCaption = format("%s - %s", appName, szTitleName.length ? szTitleName : UNTITLED);
    SetWindowText(hwnd, szCaption.toUTF16z);
}

void OkMessage(HWND hwnd, string szMessage, string szTitleName)
{
    string szBuffer;

    szBuffer = format(szMessage, szTitleName.length ? szTitleName : UNTITLED);
    MessageBox(hwnd, szBuffer.toUTF16z, appName.toUTF16z, MB_OK | MB_ICONEXCLAMATION);
}

int AskAboutSave(HWND hwnd, string szTitleName)
{
    string szBuffer;
    int iReturn;

    szBuffer = format("Save current changes in %s?", szTitleName.length ? szTitleName : UNTITLED);
    iReturn = MessageBox(hwnd, szBuffer.toUTF16z, appName.toUTF16z, MB_YESNOCANCEL | MB_ICONQUESTION);

    if (iReturn == IDYES)
        if (!SendMessage(hwnd, WM_COMMAND, IDM_FILE_SAVE, 0))
            iReturn = IDCANCEL;

    return iReturn;
}

wchar[MAX_PATH] szFileName  = 0;
wchar[MAX_PATH] szTitleName = 0;

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BOOL bNeedSave = FALSE;
    static HINSTANCE hInst;
    static HWND  hwndEdit;
    static int   iOffset;
    static UINT  messageFindReplace;
    int iSelBeg, iSelEnd, iEnable;
    LPFINDREPLACE pfr;

    switch (message)
    {
        case WM_CREATE:
            hInst = (cast(LPCREATESTRUCT)lParam).hInstance;

            // Create the edit control child window
            hwndEdit = CreateWindow("edit", NULL,
                                    WS_CHILD | WS_VISIBLE | WS_HSCROLL | WS_VSCROLL |
                                    WS_BORDER | ES_LEFT | ES_MULTILINE |
                                    ES_NOHIDESEL | ES_AUTOHSCROLL | ES_AUTOVSCROLL,
                                    0, 0, 0, 0,
                                    hwnd, cast(HMENU)EDITID, hInst, NULL);

            SendMessage(hwndEdit, EM_LIMITTEXT, 32000, 0L);

            // Initialize common dialog box stuff
            PopFileInitialize(hwnd);
            PopFontInitialize(hwndEdit);

            messageFindReplace = RegisterWindowMessage(FINDMSGSTRING.ptr);

            DoCaption(hwnd, to!string(fromWStringz(szTitleName.ptr)));
            return 0;

        case WM_SETFOCUS:
            SetFocus(hwndEdit);
            return 0;

        case WM_SIZE:
            MoveWindow(hwndEdit, 0, 0, LOWORD(lParam), HIWORD(lParam), TRUE);
            return 0;

        case WM_INITMENUPOPUP:

            switch (lParam)
            {
                case 1:       // Edit menu

                    // Enable Undo if edit control can do it
                    EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_UNDO,
                                   SendMessage(hwndEdit, EM_CANUNDO, 0, 0L) ?
                                   MF_ENABLED : MF_GRAYED);

                    // Enable Paste if text is in the clipboard

                    EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_PASTE,
                                   IsClipboardFormatAvailable(CF_TEXT) ?
                                   MF_ENABLED : MF_GRAYED);

                    // Enable Cut, Copy, and Del if text is selected

                    SendMessage(hwndEdit, EM_GETSEL, cast(WPARAM)&iSelBeg, cast(LPARAM)&iSelEnd);

                    iEnable = (iSelBeg != iSelEnd) ? MF_ENABLED : MF_GRAYED;

                    EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_CUT, iEnable);
                    EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_COPY, iEnable);
                    EnableMenuItem(cast(HMENU)wParam, IDM_EDIT_CLEAR, iEnable);
                    break;

                case 2:       // Search menu

                    // Enable Find, Next, and Replace if modeless
                    //   dialogs are not already active
                    iEnable = hDlgModeless == NULL ?
                              MF_ENABLED : MF_GRAYED;

                    EnableMenuItem(cast(HMENU)wParam, IDM_SEARCH_FIND, iEnable);
                    EnableMenuItem(cast(HMENU)wParam, IDM_SEARCH_NEXT, iEnable);
                    EnableMenuItem(cast(HMENU)wParam, IDM_SEARCH_REPLACE, iEnable);
                    break;
                
                default:
            }

            return 0;

        case WM_COMMAND:
            // Messages from edit control

            if (lParam && LOWORD(wParam) == EDITID)
            {
                switch (HIWORD(wParam))
                {
                    case EN_UPDATE:
                        bNeedSave = TRUE;
                        return 0;

                    case EN_ERRSPACE:
                    case EN_MAXTEXT:
                        MessageBox(hwnd, "Edit control out of space.",
                                   appName.toUTF16z, MB_OK | MB_ICONSTOP);
                        return 0;
                    
                    default:
                }

                break;
            }

            switch (LOWORD(wParam))
            {
                // Messages from File menu

                case IDM_FILE_NEW:

                    if (bNeedSave && IDCANCEL == AskAboutSave(hwnd, to!string(fromWStringz(szTitleName.ptr))))
                        return 0;

                    SetWindowText(hwndEdit, "\0");
                    szFileName[0]  = 0;
                    szTitleName[0] = 0;
                    DoCaption(hwnd, to!string(fromWStringz(szTitleName.ptr)));
                    bNeedSave = FALSE;
                    return 0;

                case IDM_FILE_OPEN:

                    if (bNeedSave && IDCANCEL == AskAboutSave(hwnd, to!string(fromWStringz(szTitleName.ptr))))
                        return 0;

                    if (PopFileOpenDlg(hwnd, szFileName.ptr, szTitleName.ptr))
                    {
                        if (!PopFileRead(hwndEdit, szFileName.ptr))
                        {
                            OkMessage(hwnd, "Could not read file %s!", to!string(fromWStringz(szTitleName.ptr)));
                            szFileName[0]  = 0;
                            szTitleName[0] = 0;
                        }
                    }

                    DoCaption(hwnd, to!string(fromWStringz(szTitleName.ptr)));
                    bNeedSave = FALSE;
                    return 0;

                case IDM_FILE_SAVE:

                    if (szFileName[0] != 0)
                    {
                        if (PopFileWrite(hwndEdit, szFileName.ptr))
                        {
                            bNeedSave = FALSE;
                            return 1;
                        }
                        else
                        {
                            OkMessage(hwnd, "Could not write file %s", to!string(fromWStringz(szTitleName.ptr)));
                            return 0;
                        }
                    }
                    
                    goto case;

                case IDM_FILE_SAVE_AS:

                    if (PopFileSaveDlg(hwnd, szFileName.ptr, szTitleName.ptr))
                    {
                        DoCaption(hwnd, to!string(fromWStringz(szTitleName.ptr)));

                        if (PopFileWrite(hwndEdit, szFileName.ptr))
                        {
                            bNeedSave = FALSE;
                            return 1;
                        }
                        else
                        {
                            OkMessage(hwnd, "Could not write file %s", to!string(fromWStringz(szTitleName.ptr)));
                            return 0;
                        }
                    }

                    return 0;

                case IDM_FILE_PRINT:

                    if (!PopPrntPrintFile(hInst, hwnd, hwndEdit, szTitleName.ptr))
                        OkMessage(hwnd, "Could not print file %s", to!string(fromWStringz(szTitleName.ptr)));

                    return 0;

                case IDM_APP_EXIT:
                    SendMessage(hwnd, WM_CLOSE, 0, 0);
                    return 0;

                // Messages from Edit menu
                case IDM_EDIT_UNDO:
                    SendMessage(hwndEdit, WM_UNDO, 0, 0);
                    return 0;

                case IDM_EDIT_CUT:
                    SendMessage(hwndEdit, WM_CUT, 0, 0);
                    return 0;

                case IDM_EDIT_COPY:
                    SendMessage(hwndEdit, WM_COPY, 0, 0);
                    return 0;

                case IDM_EDIT_PASTE:
                    SendMessage(hwndEdit, WM_PASTE, 0, 0);
                    return 0;

                case IDM_EDIT_CLEAR:
                    SendMessage(hwndEdit, WM_CLEAR, 0, 0);
                    return 0;

                case IDM_EDIT_SELECT_ALL:
                    SendMessage(hwndEdit, EM_SETSEL, 0, -1);
                    return 0;

                // Messages from Search menu
                case IDM_SEARCH_FIND:
                    SendMessage(hwndEdit, EM_GETSEL, 0, cast(LPARAM)&iOffset);
                    hDlgModeless = PopFindFindDlg(hwnd);
                    return 0;

                case IDM_SEARCH_NEXT:
                    SendMessage(hwndEdit, EM_GETSEL, 0, cast(LPARAM)&iOffset);

                    if (PopFindValidFind())
                        PopFindNextText(hwndEdit, &iOffset);
                    else
                        hDlgModeless = PopFindFindDlg(hwnd);

                    return 0;

                case IDM_SEARCH_REPLACE:
                    SendMessage(hwndEdit, EM_GETSEL, 0, cast(LPARAM)&iOffset);
                    hDlgModeless = PopFindReplaceDlg(hwnd);
                    return 0;

                case IDM_FORMAT_FONT:

                    if (PopFontChooseFont(hwnd))
                        PopFontSetFont(hwndEdit);

                    return 0;

                // Messages from Help menu
                case IDM_HELP:
                    OkMessage(hwnd, "Help not yet implemented!",
                              "\0");
                    return 0;

                case IDM_APP_ABOUT:
                    DialogBox(hInst, "AboutBox", hwnd, &AboutDlgProc);
                    return 0;
                
                default:
            }

            break;

        case WM_CLOSE:
            if (!bNeedSave || IDCANCEL != AskAboutSave(hwnd, to!string(fromWStringz(szTitleName.ptr))))
                DestroyWindow(hwnd);

            return 0;

        case WM_QUERYENDSESSION:
            if (!bNeedSave || IDCANCEL != AskAboutSave(hwnd, to!string(fromWStringz(szTitleName.ptr))))
                return 1;

            return 0;

        case WM_DESTROY:
            PopFontDeinitialize();
            PostQuitMessage(0);
            return 0;

        default:
            // Process "Find-Replace" messages
            if (message == messageFindReplace)
            {
                pfr = cast(LPFINDREPLACE)lParam;

                if (pfr.Flags & FR_DIALOGTERM)
                    hDlgModeless = NULL;

                if (pfr.Flags & FR_FINDNEXT)
                    if (!PopFindFindText(hwndEdit, &iOffset, pfr))
                        OkMessage(hwnd, "Text not found!", "\0");

                if (pfr.Flags & FR_REPLACE || pfr.Flags & FR_REPLACEALL)
                    if (!PopFindReplaceText(hwndEdit, &iOffset, pfr))
                        OkMessage(hwnd, "Text not found!", "\0");

                if (pfr.Flags & FR_REPLACEALL)
                {
                    while (PopFindReplaceText(hwndEdit, &iOffset, pfr))
                    {
                    }
                }

                return 0;
            }

            break;
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern (Windows)
BOOL AboutDlgProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_INITDIALOG:
            return TRUE;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDOK:
                    EndDialog(hDlg, 0);
                    return TRUE;
                
                default:
            }

            break;
            
        default:
    }

    return FALSE;
}

BOOL PopPrntPrintFile(HINSTANCE hInst, HWND hwnd, HWND hwndEdit, PTSTR pstrTitleName)
{
     return FALSE;
}
