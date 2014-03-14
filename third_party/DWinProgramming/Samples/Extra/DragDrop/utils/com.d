module utils.com;

import core.atomic;
import core.memory;
import core.stdc.string;

import win32.objidl;
import win32.ole2;
import win32.winbase;
import win32.windef;

/**
    Create a global memory buffer and store text contents to it.
    Return the handle to the memory buffer.
*/
HGLOBAL toGlobalMem(string text)
{
    // allocate and lock a global memory buffer. Make it fixed
    // data so we don't have to use GlobalLock
    char* ptr = cast(char*)GlobalAlloc(GMEM_FIXED, text.memSizeOf);

    // copy the string into the buffer
    ptr[0 .. text.length] = text[];

    return cast(HGLOBAL)ptr;
}

/** Return the memory size needed to store the elements of the array. */
size_t memSizeOf(E)(E[] arr)
{
    return E.sizeof * arr.length;
}

///
unittest
{
    int[] arrInt = [1, 2, 3, 4];
    assert(arrInt.memSizeOf == 4 * int.sizeof);

    long[] arrLong = [1, 2, 3, 4];
    assert(arrLong.memSizeOf == 4 * long.sizeof);
}

/**
    Duplicate the memory helt at the global memory handle,
    and return the handle to the duplicated memory.
*/
HGLOBAL dupGlobalMem(HGLOBAL hMem)
{
    // lock the source memory object
    PVOID source = GlobalLock(hMem);
    scope(exit) GlobalUnlock(hMem);

    // create a fixed global block - just
    // a regular lump of our process heap
    DWORD len = GlobalSize(hMem);
    PVOID dest = GlobalAlloc(GMEM_FIXED, len);
    memcpy(dest, source, len);

    return dest;
}

/** Perform a deep copy of a FORMATETC structure. */
FORMATETC deepDupFormatEtc(FORMATETC source)
{
    FORMATETC res;
    res = source;

    // duplicate memory for the DVTARGETDEVICE if necessary
    if (source.ptd)
    {
        res.ptd = cast(DVTARGETDEVICE*)CoTaskMemAlloc(DVTARGETDEVICE.sizeof);
        *(res.ptd) = *(source.ptd);
    }

    return res;
}

/** Instantiate a COM class using the GC. */
C newCom(C, T...)(T arguments)
{
	// avoid special casing in _d_newclass, where COM objects are not garbage collected
	size_t size = C.classinfo.init.length;
    void* p = GC.malloc(size, GC.BlkAttr.FINALIZE);

	memcpy(p, C.classinfo.init.ptr, size);
	C c = cast(C)p;

	static if (arguments.length || __traits(compiles,c.__ctor(arguments)))
		c.__ctor(arguments);

	return c;
}

abstract class ComObject : IUnknown
{
    /**
        Note: See Issue 4092, COM objects are allocated in the
        C heap instead of the GC:
        http://d.puremagic.com/issues/show_bug.cgi?id=4092
    */
	@disable new(size_t size)
	{
        // should not be called because we don't have enough type info
		assert(0);
        // GC.malloc(size, GC.BlkAttr.FINALIZE);
	}

    HRESULT QueryInterface(IID* riid, void** ppv)
	{
		if (*riid == IID_IUnknown)
		{
			*ppv = cast(void*)cast(IUnknown)this;
			AddRef();
			return S_OK;
		}

        *ppv = null;
        return E_NOINTERFACE;
	}

    ULONG AddRef()
    {
        LONG lRef = atomicOp!"+="(_refCount, 1);
        if (lRef == 1)
            GC.addRoot(cast(void*)this);

        return lRef;
    }

    ULONG Release()
    {
        LONG lRef = atomicOp!"-="(_refCount, 1);
        if (lRef == 0)
            GC.removeRoot(cast(void*)this);

        return cast(ULONG)lRef;
    }

	shared(LONG) _refCount;
}
