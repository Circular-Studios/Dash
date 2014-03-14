module save_clipboard.data_object;

import std.algorithm;
import std.range;
import std.string;

import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;
import win32.winuser;
import win32.wtypes;

const ULONG MAX_FORMATS = 100;

import save_clipboard.enum_format;
import utils.com;

struct FormatStore
{
    FORMATETC formatetc;
    STGMEDIUM stgmedium;
}

class DataObject : ComObject, IDataObject
{
    this(FormatStore[] formatStores...)
    {
        foreach (fs; formatStores)
            _formatStores ~= fs;
    }

    extern (Windows)
    override HRESULT QueryInterface(GUID* riid, void** ppv)
    {
        if (*riid == IID_IDataObject)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }

        return super.QueryInterface(riid, ppv);
    }

    /**
        Find the data of the format pFormatEtc and if found store
        it into the storage medium pMedium.
    */
    extern (Windows)
    HRESULT GetData(FORMATETC* pFormatEtc, STGMEDIUM* pMedium)
    {
        // try to match the requested FORMATETC with one of our supported formats
        auto fsRange = findFormatStore(*pFormatEtc);
        if (fsRange.empty)
            return DV_E_FORMATETC;  // pFormatEtc is invalid

        // found a match - transfer the data into the supplied pMedium
        auto formatStore = fsRange.front;

        // store the type of the format, and the release callback (null).
        pMedium.tymed = formatStore.formatetc.tymed;
        pMedium.pUnkForRelease = null;

        // duplicate the memory
        switch (formatStore.formatetc.tymed)
        {
            case TYMED.TYMED_HGLOBAL:
                pMedium.hGlobal = dupGlobalMem(formatStore.stgmedium.hGlobal);
                return S_OK;

            default:
                // todo: we should really assert here since we need to handle
                // all the data types in our formatStores if we accept them
                // in the constructor.
                return DV_E_FORMATETC;
        }
    }

    extern (Windows)
    HRESULT GetDataHere(FORMATETC* pFormatEtc, STGMEDIUM* pMedium)
    {
        // GetDataHere is only required for IStream and IStorage mediums
        // It is an error to call GetDataHere for things like HGLOBAL and other clipboard formats
        // OleFlushClipboard
        return DATA_E_FORMATETC;
    }

    //	Called to see if the IDataObject supports the specified format of data
    extern (Windows)
    HRESULT QueryGetData(FORMATETC* pFormatEtc)
    {
        return findFormatStore(*pFormatEtc).empty ? DV_E_FORMATETC : S_OK;
    }

    /**
        MSDN: Provides a potentially different but logically equivalent
        FORMATETC structure. You use this method to determine whether two
        different FORMATETC structures would return the same data,
        removing the need for duplicate rendering.
    */
    extern (Windows)
    HRESULT GetCanonicalFormatEtc(FORMATETC* pFormatEtc, FORMATETC* pFormatEtcOut)
    {
        /*
            MSDN: For data objects that never provide device-specific renderings,
            the simplest implementation of this method is to copy the input
            FORMATETC to the output FORMATETC, store a NULL in the ptd member of
            the output FORMATETC, and return DATA_S_SAMEFORMATETC.
        */
        *pFormatEtcOut = deepDupFormatEtc(*pFormatEtc);
        pFormatEtcOut.ptd = null;
        return DATA_S_SAMEFORMATETC;
    }

    extern (Windows)
    HRESULT SetData(FORMATETC* pFormatEtc, STGMEDIUM* pMedium, BOOL fRelease)
    {
        return E_NOTIMPL;
    }

    /**
        Create and store an object into ppEnumFormatEtc which enumerates the
        formats supported by this DataObject instance.
    */
    extern (Windows)
    HRESULT EnumFormatEtc(DWORD dwDirection, IEnumFORMATETC* ppEnumFormatEtc)
    {
        switch (dwDirection) with (DATADIR)
        {
            case DATADIR_GET:
            {
                if (_formatStores.length == 0 || ppEnumFormatEtc is null)
                    return E_INVALIDARG;

                auto obj = newCom!ClassEnumFormatEtc(_formatStores.map!(a => a.formatetc));
                obj.AddRef();
                *ppEnumFormatEtc = obj;
                return S_OK;
            }

            // not supported for now.
            case DATADIR_SET:
                return E_NOTIMPL;

            default:
                assert(0, format("Unhandled direction case: %s", dwDirection));
        }
    }

    extern (Windows)
    HRESULT DAdvise(FORMATETC* pFormatEtc, DWORD advf, IAdviseSink pAdvSink, DWORD* pdwConnection)
    {
        return OLE_E_ADVISENOTSUPPORTED;
    }

    extern (Windows)
    HRESULT DUnadvise(DWORD dwConnection)
    {
        return OLE_E_ADVISENOTSUPPORTED;
    }

    extern (Windows)
    HRESULT EnumDAdvise(IEnumSTATDATA* ppEnumAdvise)
    {
        return OLE_E_ADVISENOTSUPPORTED;
    }

private:
    /**
        Find the format store in our list of supported formats,
        or return an empty range if not found.
    */
    private auto findFormatStore(FORMATETC formatEtc)
    {
        return _formatStores
            .find!(a =>
                a.formatetc.tymed == formatEtc.tymed &&
                a.formatetc.cfFormat == formatEtc.cfFormat &&
                a.formatetc.dwAspect == formatEtc.dwAspect);
    }

private:
    FormatStore[] _formatStores;
}
