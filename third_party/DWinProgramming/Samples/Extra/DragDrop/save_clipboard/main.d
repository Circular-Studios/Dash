module save_clipboard.main;

/**
    The project stores text data to the the OS clipboard using
    COM classes and functions.
*/

import std.conv;
import std.exception;
import std.stdio;

pragma(lib, "comctl32.lib");
pragma(lib, "ole32.lib");

import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;
import win32.winuser;
import win32.wtypes;

import utils.com;
import save_clipboard.data_object;

void main()
{
    enforce(OleInitialize(null) == S_OK);
    scope(exit) OleUninitialize();
    saveClipboard();
}

/** Save contents to the clipboard. */
void saveClipboard()
{
    auto fs = getTextFormatStore();
    fs.stgmedium.hGlobal = toGlobalMem("Hello, World!");
    scope(exit) ReleaseStgMedium(&fs.stgmedium);

    IDataObject pDataObject = newCom!DataObject(fs);
    scope(exit) pDataObject.Release();

    OleSetClipboard(pDataObject);
    OleFlushClipboard();
}

/** Get the format and storage medium for a text type. */
FormatStore getTextFormatStore()
{
    FormatStore store;
    store.formatetc = FORMATETC(CF_TEXT, null, DVASPECT.DVASPECT_CONTENT, -1, TYMED.TYMED_HGLOBAL);
    store.stgmedium = STGMEDIUM(TYMED.TYMED_HGLOBAL);
    return store;
}
