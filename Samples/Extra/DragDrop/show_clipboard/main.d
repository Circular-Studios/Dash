module show_clipboard;

/**
    The self-contained module queries the OS clipboard using COM
    functions, and then prints out the contents if the clipboard
    holds any text data.
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

void main()
{
    enforce(OleInitialize(null) == S_OK);
    scope(exit) OleUninitialize();
    showClipboard();
}

/** Print clipboard contents to stderr. */
void showClipboard()
{
    /**
        Clipboard and Drag & Drop both use an IDataObject,
        so the reading code can remain simple.
    */
    IDataObject pDataObject;
    enforce(OleGetClipboard(&pDataObject) == S_OK);
    scope(exit) pDataObject.Release;

    /** The format we're querying about. */
    FORMATETC fmtetc = { CF_TEXT, null, DVASPECT.DVASPECT_CONTENT, -1, TYMED.TYMED_HGLOBAL };
    STGMEDIUM stgmed;

    /** Query if the data object has CF_TEXT data, stored as an HGLOBAL. */
    if (pDataObject.GetData(&fmtetc, &stgmed) == S_OK)
    {
        scope(exit) ReleaseStgMedium(&stgmed);

        // We need to lock the HGLOBAL handle because we can't
        // be sure if this is GMEM_FIXED (i.e. normal heap) data or not
        char* data = cast(char*)GlobalLock(stgmed.hGlobal);
        scope(exit) GlobalUnlock(stgmed.hGlobal);

        stderr.writefln("Clipboard contents:\n%s", data.to!string);
    }
}
