module drop_source.enum_format;

import core.atomic;
import core.memory;

import std.algorithm;
import std.array;
import std.range;

import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;
import win32.winuser;
import win32.wtypes;

import utils.com;

class ClassEnumFormatEtc : ComObject, IEnumFORMATETC
{
    this(Range)(Range formatEtcArr)
        if (isInputRange!Range && is(ElementType!Range == FORMATETC))
    {
        _formatEtcArr = map!(a => deepDupFormatEtc(a))(formatEtcArr).array;
    }

    /** Used for copying. */
    this(FORMATETC[] formatEtcArr, size_t index)
    {
        this(formatEtcArr);
        _index = index;
    }

    extern (Windows)
    override HRESULT QueryInterface(GUID* riid, void** ppv)
    {
        if (*riid == IID_IEnumFORMATETC)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }

        return super.QueryInterface(riid, ppv);
    }

    extern (Windows)
    override ULONG Release()
    {
        LONG lRef = atomicOp!"-="(_refCount, 1);
        if (lRef == 0)
        {
            this.releaseMemory();
            GC.removeRoot(cast(void*)this);
        }

        return cast(ULONG)lRef;
    }

    /**
        MSDN: If the returned FORMATETC structure contains a non-null
        ptd member, then the caller must free this using CoTaskMemFree.
    */
    extern (Windows)
    HRESULT Next(ULONG itemCount, FORMATETC* pFormatEtc, ULONG* itemsCopied)
    {
        if (itemCount == 0 || pFormatEtc is null)
            return E_INVALIDARG;

        /** Copy FORMATETC structures into the caller's array buffer. */
        ULONG copyCount;
        while (_index < _formatEtcArr.length && copyCount < itemCount)
        {
            pFormatEtc[copyCount] = deepDupFormatEtc(_formatEtcArr[_index]);
            copyCount++;
            _index++;
        }

        // can be null if itemCount equals 1
        if (itemsCopied !is null)
            *itemsCopied = copyCount;

        // did we copy all that was requested?
        return copyCount == itemCount ? S_OK : S_FALSE;
    }

    extern (Windows)
    HRESULT Skip(ULONG itemCount)
    {
        _index += itemCount;
        return _index <= _formatEtcArr.length ? S_OK : S_FALSE;
    }

    extern (Windows)
    HRESULT Reset()
    {
        _index = 0;
        return S_OK;
    }

    /** Clone this enumerator. */
    extern (Windows)
    HRESULT Clone(IEnumFORMATETC* ppEnumFormatEtc)
    {
        if (_formatEtcArr.length == 0 || ppEnumFormatEtc is null)
            return E_INVALIDARG;

        auto obj = newCom!ClassEnumFormatEtc(_formatEtcArr, _index);
        obj.AddRef();
        *ppEnumFormatEtc = obj;
        return S_OK;
    }

private:
    private void releaseMemory()
    {
        foreach (formatEtc; _formatEtcArr)
        {
            if (formatEtc.ptd)
                CoTaskMemFree(formatEtc.ptd);
        }
    }

private:
    size_t _index;
    FORMATETC[] _formatEtcArr;
}
