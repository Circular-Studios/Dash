module drop_source.main;

/**
    The project implements IDropSource and initiates a Drag & Drop operation.
    It uses an Edit control and allows dragging text from one application to another.
*/

import core.runtime;
import core.stdc.stdlib;
import core.stdc.string;

import std.conv;
import std.exception;
import std.stdio;
import std.string;

pragma(lib, "comctl32.lib");
pragma(lib, "ole32.lib");
pragma(lib, "gdi32.lib");

import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;
import win32.wingdi;
import win32.winuser;
import win32.wtypes;

import utils.com;

import drop_source.source;
import drop_source.resource;
import drop_source.data_object;
import drop_source.enum_format;

extern (Windows)
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    int result;

    void exceptionHandler(Throwable e)
    {
        throw e;
    }

    try
    {
        Runtime.initialize(&exceptionHandler);
        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, iCmdShow);
        Runtime.terminate(&exceptionHandler);
    }
    catch (Throwable o)
    {
        MessageBox(null, o.toString().toStringz, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

enum APPNAME = "IDropSource";

HWND hwndMain;
HWND hwndEdit;
HINSTANCE hInstance;
WNDPROC OldEditWndProc;

int myWinMain(HINSTANCE hInst, HINSTANCE hPrev, LPSTR lpCmdLine, int nShowCmd)
{
    enforce(OleInitialize(null) == S_OK);
    scope(exit)
        OleUninitialize();

    MSG msg;
    hInstance = hInst;

    InitMainWnd();
    CreateMainWnd();

    while (GetMessage(&msg, null, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}

void InitMainWnd()
{
    WNDCLASSEX wc;

    wc.lpfnWndProc   = &WndProc;
    wc.lpszClassName = APPNAME;
    wc.lpszMenuName  = MAKEINTRESOURCE(IDR_MENU1);
    wc.hInstance     = hInstance;

    RegisterClassEx(&wc);
}

void CreateMainWnd()
{
    hwndMain = CreateWindowEx(0, APPNAME, APPNAME,
                              WS_VISIBLE | WS_OVERLAPPEDWINDOW,
                              CW_USEDEFAULT, CW_USEDEFAULT, 512, 200, null, null,
                              hInstance, null);
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg)
    {
        case WM_CREATE:
            // create a child-window EDIT control
            hwndEdit = CreateWindowEx(WS_EX_CLIENTEDGE, "EDIT", "",
                                      WS_CHILD | WS_VISIBLE | ES_MULTILINE | ES_WANTRETURN | WS_VSCROLL,
                                      0, 0, 0, 0, hwnd, null, hInstance, null);

            // fixed-width font
            SendMessage(hwndEdit, WM_SETFONT, cast(WPARAM)GetStockObject(ANSI_FIXED_FONT), 0);

            // subclass the edit control so we can add drag+drop support to it
            OldEditWndProc = cast(WNDPROC) SetWindowLong(hwndEdit, GWL_WNDPROC, cast(LONG)&EditWndProc);

            SetFocus(hwndEdit);

            return TRUE;

        case WM_COMMAND:
            // react to menu messages
            switch (LOWORD(wParam))
            {
                case IDM_FILE_EXIT:
                    CloseWindow(hwnd);
                    return 0;

                case IDM_FILE_ABOUT:
                    MessageBox(hwnd, "IDropSource Test Application\r\n\r\n"
                               "Copyright(c) 2004 by Catch22 Productions\t\r\n"
                               "Written by J Brown.\r\n\r\n"
                               "Homepage at www.catch22.net", APPNAME, MB_ICONINFORMATION);
                    return 0;

                default:
            }

            break;

        case WM_CLOSE:
            DestroyWindow(hwnd);
            PostQuitMessage(0);
            return 0;

        case WM_SIZE:
            // resize editbox to fit in main window
            MoveWindow(hwndEdit, 0, 0, LOWORD(lParam), HIWORD(lParam), TRUE);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, msg, wParam, lParam);
}

//Subclass window-procedure for EDIT control
extern (Windows)
LRESULT EditWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    static BOOL fMouseDown   = FALSE;
    static BOOL fDidDragDrop = FALSE;

    switch (msg)
    {
        case WM_KEYDOWN:
            // when ESCAPE is pressed clear the current selection
            if (wParam == VK_ESCAPE)
                ClearSelection(hwnd);

            break;

        case WM_LBUTTONDOWN:
        case WM_LBUTTONDBLCLK:
            // if the mouse is pressed when it is over a selection,
            // then start a drag-drop as soon as the mouse moves next
            if (MouseInSelection(hwndEdit, lParam))
            {
                fMouseDown   = TRUE;
                fDidDragDrop = FALSE;
                SetCapture(hwnd);
                return 0;
            }

            break;

        case WM_SETCURSOR:
            // set the mouse cursor to an ARROW when it intersects the
            // current selection, or the default IBEAM otherwise
            if (cast(HWND)wParam == hwnd)
            {
                POINT pt;
                GetCursorPos(&pt);
                ScreenToClient(hwndEdit, &pt);

                if (MouseInSelection(hwndEdit, MAKELPARAM(pt.x, pt.y)))
                {
                    SetCursor(LoadCursor(null, MAKEINTRESOURCE(IDC_ARROW)));
                }
                else
                {
                    SetCursor(LoadCursor(null, MAKEINTRESOURCE(IDC_IBEAM)));
                }
            }

            return TRUE;

        case WM_MOUSEMOVE:
            // if the mouse is held down then start a drag-drop
            if (fMouseDown)
            {
                IDataObject pDataObject;
                IDropSource pDropSource;
                DWORD dwEffect;
                DWORD dwResult;

                FORMATETC fmtetc = { CF_TEXT, null, DVASPECT.DVASPECT_CONTENT, -1, TYMED.TYMED_HGLOBAL };
                STGMEDIUM stgmed = { TYMED.TYMED_HGLOBAL };

                // transfer the current selection into the IDataObject
                stgmed.hGlobal = CopySelection(hwndEdit);

                // Create IDataObject and IDropSource COM objects
                pDropSource = newCom!CDropSource();
                scope(exit) pDropSource.Release();

                pDataObject = newCom!DataObject(FormatStore(fmtetc, stgmed));
                scope(exit) pDataObject.Release();

                // Star the drag & drop operation
                dwResult = DoDragDrop(pDataObject, pDropSource, DROPEFFECT.DROPEFFECT_COPY | DROPEFFECT.DROPEFFECT_MOVE, &dwEffect);

                // success!
                if (dwResult == DRAGDROP_S_DROP)
                {
                    if (dwEffect & DROPEFFECT.DROPEFFECT_MOVE)
                    {
                        MessageBox(null, "Moving", "Info", MB_OK);
                        // todo: remove selection from edit control
                    }
                }
                else if (dwResult == DRAGDROP_S_CANCEL)  // cancelled
                {
                }

                ReleaseCapture();
                fMouseDown   = FALSE;
                fDidDragDrop = TRUE;
            }

            break;

        case WM_LBUTTONUP:

            // stop drag-drop from happening when the mouse is released.
            if (fMouseDown)
            {
                ReleaseCapture();
                fMouseDown = FALSE;

                if (fDidDragDrop == FALSE)
                    ClearSelection(hwnd);
            }

            break;

        default:
    }

    return CallWindowProc(OldEditWndProc, hwnd, msg, wParam, lParam);
}

// Is the mouse cursor within the edit control's selected text?
//
// Return TRUE/FALSE
//
BOOL MouseInSelection(HWND hwndEdit, LPARAM MouseMsgParam)
{
    DWORD nSelStart;
    DWORD nSelEnd;

    // get the selection inside the edit control
    SendMessage(hwndEdit, EM_GETSEL, cast(WPARAM)&nSelStart, cast(LPARAM)&nSelEnd);

    if (nSelStart != nSelEnd)
    {
        DWORD nCurPos;

        // Get the cursor position the mouse has clicked on
        nCurPos = SendMessage(hwndEdit, EM_CHARFROMPOS, 0, MouseMsgParam);
        nCurPos = LOWORD(nCurPos);

        // Did the mouse click inside the active selection?
        return (nCurPos >= nSelStart && nCurPos < nSelEnd) ? TRUE : FALSE;
    }

    return FALSE;
}

// Remove any selection from the edit control
void ClearSelection(HWND hwndEdit)
{
    SendMessage(hwndEdit, EM_SETSEL, -1, -1);
}

// Copy selected text to an HGLOBAL and return it
HGLOBAL CopySelection(HWND hwndEdit)
{
    DWORD nSelStart, nSelEnd;
    DWORD nSelLength, nEditLength;
    HGLOBAL hMem;
    char* ptr;
    char* tmp;

    SendMessage(hwndEdit, EM_GETSEL, cast(WPARAM)&nSelStart, cast(LPARAM)&nSelEnd);

    nSelLength = nSelEnd - nSelStart;

    // get the entire contents of the control
    nEditLength = SendMessage(hwndEdit, EM_GETLIMITTEXT, 0, 0);
    tmp         = cast(char*)malloc(nEditLength);

    SendMessage(hwndEdit, WM_GETTEXT, nEditLength, cast(LPARAM)tmp);

    hMem = GlobalAlloc(GHND, nSelLength + 1);
    ptr  = cast(char*)GlobalLock(hMem);

    // copy the selected text and null-terminate
    memcpy(ptr, tmp + nSelStart, nSelLength);
    ptr[nSelLength] = '\0';

    GlobalUnlock(hMem);

    free(tmp);

    return hMem;
}
