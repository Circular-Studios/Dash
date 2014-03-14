module list_clipboard.main;

/**
    The project queries the OS clipboard using COM functions,
    and then prints out all the content types in the clipboard.
 */

import core.runtime;

import std.c.process;

import std.algorithm;
import std.conv;
import std.exception;
import std.range;
import std.stdio;
import std.string;
import std.utf;

pragma(lib, "comctl32.lib");
pragma(lib, "ole32.lib");

import win32.commctrl;
import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;
import win32.winuser;
import win32.wtypes;

import list_clipboard.resource;

import utils.com;

alias toCharz = toUTFz!(char*);

struct STRLOOKUP
{
    UINT cfFormat;
    string name;
}

// note: missing in WinAPI
enum CF_DIBV5 = 17;
enum CF_MAX   = 18;

STRLOOKUP[] cliplook =
[
    STRLOOKUP(CF_BITMAP, "CF_BITMAP"),
    STRLOOKUP(CF_DIB, "CF_DIB"),
    STRLOOKUP(CF_DIBV5, "CF_DIBV5"),
    STRLOOKUP(CF_DIF, "CF_DIF"),
    STRLOOKUP(CF_DSPBITMAP, "CF_DSPBITMAP"),
    STRLOOKUP(CF_DSPENHMETAFILE, "CF_DSPENHMETAFILE"),
    STRLOOKUP(CF_DSPMETAFILEPICT, "CF_DSPMETAFILEPICT"),
    STRLOOKUP(CF_DSPTEXT, "CF_DSPTEXT"),
    STRLOOKUP(CF_ENHMETAFILE, "CF_ENHMETAFILE"),
    STRLOOKUP(CF_GDIOBJFIRST, "CF_GDIOBJFIRST"),
    STRLOOKUP(CF_HDROP, "CF_HDROP"),
    STRLOOKUP(CF_LOCALE, "CF_LOCALE"),
    STRLOOKUP(CF_METAFILEPICT, "CF_METAFILEPICT"),
    STRLOOKUP(CF_OEMTEXT, "CF_OEMTEXT"),
    STRLOOKUP(CF_OWNERDISPLAY, "CF_OWNERDISPLAY"),
    STRLOOKUP(CF_PALETTE, "CF_PALETTE"),
    STRLOOKUP(CF_PENDATA, "CF_PENDATA"),
    STRLOOKUP(CF_PRIVATEFIRST, "CF_PRIVATEFIRST"),
    STRLOOKUP(CF_RIFF, "CF_RIFF"),
    STRLOOKUP(CF_SYLK, "CF_SYLK"),
    STRLOOKUP(CF_TEXT, "CF_TEXT"),
    STRLOOKUP(CF_WAVE, "CF_WAVE"),
    STRLOOKUP(CF_TIFF, "CF_TIFF"),
    STRLOOKUP(CF_UNICODETEXT, "CF_UNICODETEXT"),
    STRLOOKUP(0, null),
];

STRLOOKUP[] aspectlook =
[
    STRLOOKUP(DVASPECT.DVASPECT_CONTENT, "Content  "),
    STRLOOKUP(DVASPECT.DVASPECT_THUMBNAIL, "Thumbnail"),
    STRLOOKUP(DVASPECT.DVASPECT_ICON, "Icon     "),
    STRLOOKUP(DVASPECT.DVASPECT_DOCPRINT, "DocPrint "),
    STRLOOKUP(0, null),
];

STRLOOKUP[] tymedlook =
[
    STRLOOKUP(TYMED.TYMED_HGLOBAL, "hGlobal"),
    STRLOOKUP(TYMED.TYMED_FILE, "File"),
    STRLOOKUP(TYMED.TYMED_ISTREAM, "IStream"),
    STRLOOKUP(TYMED.TYMED_ISTORAGE, "IStorage"),
    STRLOOKUP(TYMED.TYMED_GDI, "GDI"),
    STRLOOKUP(TYMED.TYMED_MFPICT, "MFPict"),
    STRLOOKUP(TYMED.TYMED_ENHMF, "ENHMF"),
    STRLOOKUP(TYMED.TYMED_NULL, "Null"),
    STRLOOKUP(0, null),
];

enum APPNAME = "IDataObject Viewer";

HWND hwndMain;
HWND hwndList;
HINSTANCE hInstance;

/** Display the enumerated format of the clipboard. */
void AddFormatListView(HWND hwndList, FORMATETC* pfmtetc)
{
    // Get textual name of format
    string name;
    char[64] namebuf = 0;
    if (GetClipboardFormatName(pfmtetc.cfFormat, namebuf.ptr, 64) == 0)
    {
        auto fmt = cliplook.find!(a => a.cfFormat == pfmtetc.cfFormat);
        if (fmt.empty)
            name = "Unknown Format";
        else
            name = fmt.front.name;
    }
    else
    {
        name = to!string(namebuf.ptr);
    }

    DWORD nIndex = ListView_GetItemCount(hwndList);

    LVITEM lvitem;
    lvitem.mask     = LVIF_TEXT;
    lvitem.iSubItem = 0;
    lvitem.iItem    = nIndex;
    lvitem.pszText  = name.toCharz;

    // add new row, and set format name (cfFormat)
    ListView_InsertItem(hwndList, &lvitem);

    // Add TARGETDEVICE pointer
    string ptd;
    if (pfmtetc.ptd !is null)
        ptd = format("%08x", pfmtetc.ptd);

    // set the subitem
    ListView_SetItemText(hwndList, nIndex, 1, ptd.toCharz);

    // Add DVASPECT_xxx constant
    string aspect;
    auto aspectRng = aspectlook.find!(a => a.cfFormat == pfmtetc.dwAspect);
    if (aspectRng.empty)
        aspect = "Unknown  ";
    else
        aspect = aspectRng.front.name;

    ListView_SetItemText(hwndList, nIndex, 2, aspect.toCharz);

    // Add lindex value
    ListView_SetItemText(hwndList, nIndex, 3, pfmtetc.lindex.to!string.toCharz);

    // Add TYMED value(s)
    string[] tymedArr;

    // now add all supported data mediums
    for (int i = 1; i <= 64; i <<= 2)
    {
        if (pfmtetc.tymed & i)
        {
            string tymed;
            auto tymedRng = tymedlook.find!(a => a.cfFormat == i);
            if (tymedRng.empty)
                tymed = "Unknown";
            else
                tymed = tymedRng.front.name;

            tymedArr ~= tymed;
        }
    }

    ListView_SetItemText(hwndList, nIndex, 4, tymedArr.join(", ").toCharz);
}

/** Create the list view and the columns. */
HWND CreateListView(HWND hwndParent)
{
    LVCOLUMN lvcol;
    int width = 512;

	hwndList = CreateWindowEx(WS_EX_CLIENTEDGE, "SysListView32", "",
			WS_CHILD|WS_VISIBLE|LVS_REPORT, 0, 0, 0, 0, hwndParent, null,
			hInstance, null);

    width -= GetSystemMetrics(SM_CXVSCROLL);

    lvcol.pszText  = "cfFormat".toCharz;
    lvcol.mask     = LVCF_WIDTH | LVCF_TEXT | LVCF_SUBITEM;
    lvcol.cx       = 164;
    lvcol.iSubItem = 0;
    ListView_InsertColumn(hwndList, 0, &lvcol);
    width -= lvcol.cx;

    lvcol.pszText = "ptd".toCharz;
    lvcol.cx      = 54;
    ListView_InsertColumn(hwndList, 1, &lvcol);
    width -= lvcol.cx;

    lvcol.pszText = "dwAspect".toCharz;
    lvcol.cx      = 90;
    ListView_InsertColumn(hwndList, 2, &lvcol);
    width -= lvcol.cx;

    lvcol.pszText = "lindex".toCharz;
    lvcol.cx      = 68;
    ListView_InsertColumn(hwndList, 3, &lvcol);
    width -= lvcol.cx;

    lvcol.pszText = "tymed".toCharz;
    lvcol.cx      = max(120, width + 1);
    ListView_InsertColumn(hwndList, 4, &lvcol);
    width -= lvcol.cx;

    return hwndList;
}

extern (Windows) LRESULT WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    HICON hIcon;

    switch (msg)
    {
        case WM_CREATE:
            hwndList = CreateListView(hwnd);

            // set small icon for window
            hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_ICON1));
            SendMessage(hwnd, WM_SETICON, ICON_BIG, cast(LPARAM)hIcon);

            RegisterDropWindow(hwnd);

            return TRUE;

        case WM_ERASEBKGND:

            // stop background flicker!
            return 1;

        case WM_COMMAND:
            switch (LOWORD(wParam))
            {
                case IDM_FILE_EXIT:
                    CloseWindow(hwnd);
                    return 0;

                case IDM_FILE_ABOUT:
                    MessageBox(hwnd, "IDataObject Viewer\r\n\r\n"
                               "Copyright(c) 2003 by Catch22 Productions\t\r\n"
                               "Written by J Brown.\r\n\r\n"
                               "Homepage at www.catch22.net", APPNAME, MB_ICONINFORMATION);
                    return 0;

                case IDM_FILE_CLIP:
                    enumClipboardData(hwnd);
                    return 0;

                default:
            }

            break;

        case WM_CLOSE:
            // shut program down
            UnregisterDropWindow(hwnd);
            DestroyWindow(hwnd);
            PostQuitMessage(0);
            return 0;

        case WM_SIZE:
            // resize listbox to fit in main window
            MoveWindow(hwndList, 0, 0, LOWORD(lParam), HIWORD(lParam), TRUE);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, msg, wParam, lParam);
}

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
        MessageBox(null, o.toString().toStringz, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

int myWinMain(HINSTANCE hInst, HINSTANCE hPrev, LPSTR lpCmdLine, int nShowCmd)
{
    enforce(OleInitialize(null) == S_OK);
    scope (exit) OleUninitialize();

    MSG msg;
    hInstance = hInst;

    InitCommonControls();
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

class CDropTarget : ComObject, IDropTarget
{
    this(HWND hwnd)
    {
        _hwnd = hwnd;
    }

    extern(Windows)
    override HRESULT QueryInterface (IID* riid, void ** ppv)
    {
        if (*riid == IID_IDropTarget)
        {
            AddRef();
            *ppv = cast(void*)cast(IUnknown)this;
            return S_OK;
        }

        return super.QueryInterface(riid, ppv);
    }

    extern(Windows)
    DWORD DropEffect(DWORD dwAllowed)
    {
        DWORD dwEffect = dwAllowed & DROPEFFECT.DROPEFFECT_COPY;

        if (dwEffect == 0)
            dwEffect = dwAllowed;

        return dwEffect;
    }

    extern(Windows)
    HRESULT DragEnter(IDataObject dataObject, DWORD grfKeyState, POINTL pt, DWORD * pdwEffect)
    {
        *pdwEffect = DropEffect(*pdwEffect);
        return S_OK;
    }

    extern(Windows)
    HRESULT DragOver(DWORD grfKeyState, POINTL pt, DWORD * pdwEffect)
    {
        *pdwEffect = DropEffect(*pdwEffect);
        return S_OK;
    }

    extern(Windows)
    HRESULT DragLeave()
    {
        return S_OK;
    }

    extern(Windows)
    HRESULT Drop(IDataObject dataObject, DWORD grfKeyState, POINTL pt, DWORD * pdwEffect)
    {
        enumData(_hwnd, dataObject);
        *pdwEffect = DROPEFFECT.DROPEFFECT_NONE;
        return S_OK;
    }

private:
	HWND _hwnd;
}

void RegisterDropWindow(HWND hwnd)
{
	CDropTarget pDropTarget = newCom!CDropTarget(hwnd);

    auto res = RegisterDragDrop(hwnd, pDropTarget);
    enforce(res == S_OK || res == DRAGDROP_E_ALREADYREGISTERED,
        format("Could not register handle '%s'. Error code: %s", hwnd, res));
}

void UnregisterDropWindow(HWND hwnd)
{
	RevokeDragDrop(hwnd);
}

/** Enumerate all data in the data object and fill it in the list view. */
void enumData(HWND hwnd, IDataObject dataObject)
{
    FORMATETC fmtetc;
    HWND  hwndList;
    ULONG num;

    hwndList = GetWindow(hwnd, GW_CHILD);
    ListView_DeleteAllItems(hwndList);

    // Get the COM interface for format enumeration
    IEnumFORMATETC enumFormats;
    enforce(dataObject.EnumFormatEtc(DATADIR.DATADIR_GET, &enumFormats) == S_OK);

    // Enumerate each type of data supported by this IDataObject, one-by-one
    while (enumFormats.Next(1, &fmtetc, &num) == S_OK)
    {
        AddFormatListView(hwndList, &fmtetc);
    }

    enumFormats.Release();
}

/** Get the data object of the clipboard and enumerate its data. */
void enumClipboardData(HWND hwnd)
{
    IDataObject dataObject = getClipboardDataObject();
    enumData(hwnd, dataObject);
    dataObject.Release();
}

IDataObject getClipboardDataObject()
{
    IDataObject dataObject;
    enforce(OleGetClipboard(&dataObject) == S_OK);
    return dataObject;
}
