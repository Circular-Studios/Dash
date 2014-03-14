module drop_target.target;

import std.algorithm;
import std.range;
import std.string;

import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;
import win32.winuser;
import win32.wtypes;

import utils.com;

class CDropTarget : ComObject, IDropTarget
{
    extern (Windows)
    override HRESULT QueryInterface(GUID* riid, void** ppv)
    {
        if (*riid == IID_IDropTarget)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }

        return super.QueryInterface(riid, ppv);
    }

    this(HWND hwnd)
    {
        m_hWnd       = hwnd;
        m_fAllowDrop = false;
    }

    extern (Windows)
    HRESULT DragEnter(IDataObject pDataObject, DWORD grfKeyState, POINTL pt, DWORD* pdwEffect)
    {
        // does the dataobject contain data we want?
        m_fAllowDrop = QueryDataObject(pDataObject);

        if (m_fAllowDrop)
        {
            // get the dropeffect based on keyboard state
            *pdwEffect = DropEffect(grfKeyState, pt, *pdwEffect);
            SetFocus(m_hWnd);
            PositionCursor(m_hWnd, pt);
        }
        else
        {
            *pdwEffect = DROPEFFECT.DROPEFFECT_NONE;
        }

        return S_OK;
    }

    extern (Windows)
    HRESULT DragOver(DWORD grfKeyState, POINTL pt, DWORD* pdwEffect)
    {
        if (m_fAllowDrop)
        {
            *pdwEffect = DropEffect(grfKeyState, pt, *pdwEffect);
            PositionCursor(m_hWnd, pt);
        }
        else
        {
            *pdwEffect = DROPEFFECT.DROPEFFECT_NONE;
        }

        return S_OK;
    }

    extern (Windows)
    HRESULT DragLeave()
    {
        return S_OK;
    }

    extern (Windows)
    HRESULT Drop(IDataObject pDataObject, DWORD grfKeyState, POINTL pt, DWORD* pdwEffect)
    {
        PositionCursor(m_hWnd, pt);

        if (m_fAllowDrop)
        {
            // drop the data
            DropData(m_hWnd, pDataObject);
            *pdwEffect = DropEffect(grfKeyState, pt, *pdwEffect);
        }
        else
        {
            *pdwEffect = DROPEFFECT.DROPEFFECT_NONE;
        }

        return S_OK;
    }

private:
    private bool QueryDataObject(IDataObject pDataObject)
    {
        FORMATETC fmtetc = { CF_TEXT, null, DVASPECT.DVASPECT_CONTENT, -1, TYMED.TYMED_HGLOBAL };

        // does the data object support CF_TEXT using an HGLOBAL?
        return pDataObject.QueryGetData(&fmtetc) == S_OK ? true : false;
    }

    private DWORD DropEffect(DWORD grfKeyState, POINTL pt, DWORD dwAllowed)
    {
        DWORD dwEffect = 0;

        // 1. check "pt" . do we allow a drop at the specified coordinates?
        // todo: not checked here

        // 2. work out what the drop-effect should be based on grfKeyState
        if (grfKeyState & MK_CONTROL)
        {
            dwEffect = dwAllowed & DROPEFFECT.DROPEFFECT_COPY;
        }
        else
        if (grfKeyState & MK_SHIFT)
        {
            dwEffect = dwAllowed & DROPEFFECT.DROPEFFECT_MOVE;
        }

        // 3. no key-modifiers were specified (or drop effect not allowed), so
        // base the effect on those allowed by the dropsource
        if (dwEffect == 0)
        {
            if (dwAllowed & DROPEFFECT.DROPEFFECT_COPY)
                dwEffect = DROPEFFECT.DROPEFFECT_COPY;

            if (dwAllowed & DROPEFFECT.DROPEFFECT_MOVE)
                dwEffect = DROPEFFECT.DROPEFFECT_MOVE;
        }

        return dwEffect;
    }

private:
    HWND m_hWnd;
    bool m_fAllowDrop;
}

// Position the edit control's caret under the mouse
void PositionCursor(HWND hwndEdit, POINTL pt)
{
    DWORD curpos;

    // get the character position of mouse
    ScreenToClient(hwndEdit, cast(POINT*)&pt);
    curpos = SendMessage(hwndEdit, EM_CHARFROMPOS, 0, MAKELPARAM(pt.x, pt.y));

    // set cursor position
    SendMessage(hwndEdit, EM_SETSEL, LOWORD(curpos), LOWORD(curpos));
}

// Drop the data to the window
void DropData(HWND hwnd, IDataObject pDataObject)
{
    // construct a FORMATETC object
    FORMATETC fmtetc = { CF_TEXT, null, DVASPECT.DVASPECT_CONTENT, -1, TYMED.TYMED_HGLOBAL };
    STGMEDIUM stgmed;

    // See if the dataobject contains any TEXT stored as a HGLOBAL
    if (pDataObject.QueryGetData(&fmtetc) == S_OK)
    {
        // Yippie! the data is there, so go get it!
        if (pDataObject.GetData(&fmtetc, &stgmed) == S_OK)
        {
            // we asked for the data as a HGLOBAL, so access it appropriately
            PVOID data = GlobalLock(stgmed.hGlobal);
            SetWindowText(hwnd, cast(char*)data);
            GlobalUnlock(stgmed.hGlobal);

            // release the data
            ReleaseStgMedium(&stgmed);
        }
    }
}

void RegisterDropWindow(HWND hwnd, IDropTarget* ppDropTarget)
{
    CDropTarget pDropTarget = newCom!CDropTarget(hwnd);

    // acquire a strong lock
    CoLockObjectExternal(pDropTarget, TRUE, FALSE);

    // tell OLE that the window is a drop target
    RegisterDragDrop(hwnd, pDropTarget);

    *ppDropTarget = pDropTarget;
}

void UnregisterDropWindow(HWND hwnd, IDropTarget pDropTarget)
{
    // remove drag+drop
    RevokeDragDrop(hwnd);

    // remove the strong lock
    CoLockObjectExternal(pDropTarget, FALSE, TRUE);

    // release our own reference
    pDropTarget.Release();
}
