/***********************************************************************\
*                               basetsd.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*             Translated from MinGW API for MS-Windows 3.12             *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.basetsd;

/*	This template is used in these modules to declare constant pointer types,
 *	in order to support both D 1.x and 2.x.
 */
template CPtr(T) {
	version (D_Version2) {
		// must use mixin so that it doesn't cause a syntax error under D1
		mixin("alias const(T)* CPtr;");
	} else {
		alias T* CPtr;
	}
}

// [SnakE 2009-02-23] Moved HANDLE definition here from winnt.d to avoid
// 'forwatd template reference' to CPtr from winnt.d caused by a circular
// import.

alias void* HANDLE;

alias HANDLE* PHANDLE, LPHANDLE;

version (Win64) {
	alias long __int3264;
	const ulong ADDRESS_TAG_BIT = 0x40000000000;

	alias long INT_PTR, LONG_PTR;
	alias long* PINT_PTR, PLONG_PTR;
	alias ulong UINT_PTR, ULONG_PTR, HANDLE_PTR;
	alias ulong* PUINT_PTR, PULONG_PTR;
	alias int HALF_PTR;
	alias int* PHALF_PTR;
	alias uint UHALF_PTR;
	alias uint* PUHALF_PTR;

	/*	*To* functions are conditioned out in MinGW.
	 *	Presumably they're not working/tested yet.  Comment:
			TODO when WIN64 is here
	 */
} else {
	alias int __int3264;
	const uint ADDRESS_TAG_BIT = 0x80000000;

	alias int INT_PTR, LONG_PTR;
	alias int* PINT_PTR, PLONG_PTR;
	alias uint UINT_PTR, ULONG_PTR, HANDLE_PTR;
	alias uint* PUINT_PTR, PULONG_PTR;
	alias short HALF_PTR;
	alias short* PHALF_PTR;
	alias ushort UHALF_PTR;
	alias ushort* PUHALF_PTR;

	uint HandleToUlong(HANDLE h)      { return cast(uint) h; }
	int HandleToLong(HANDLE h)        { return cast(int) h; }
	HANDLE LongToHandle(LONG_PTR h)   { return cast(HANDLE) h; }
	uint PtrToUlong(CPtr!(void) p)    { return cast(uint) p; }
	uint PtrToUint(CPtr!(void) p)     { return cast(uint) p; }
	int PtrToInt(CPtr!(void) p)       { return cast(int) p; }
	ushort PtrToUshort(CPtr!(void) p) { return cast(ushort) p; }
	short PtrToShort(CPtr!(void) p)   { return cast(short) p; }
	void* IntToPtr(int i)             { return cast(void*) i; }
	void* UIntToPtr(uint ui)          { return cast(void*) ui; }
	alias IntToPtr LongToPtr;
	alias UIntToPtr ULongToPtr;
}

alias UIntToPtr UintToPtr, UlongToPtr;

enum : UINT_PTR {
	MAXUINT_PTR = UINT_PTR.max
}

enum : INT_PTR {
	MAXINT_PTR = INT_PTR.max,
	MININT_PTR = INT_PTR.min
}

enum : ULONG_PTR {
	MAXULONG_PTR = ULONG_PTR.max
}

enum : LONG_PTR {
	MAXLONG_PTR = LONG_PTR.max,
	MINLONG_PTR = LONG_PTR.min
}

enum : UHALF_PTR {
	MAXUHALF_PTR = UHALF_PTR.max
}

enum : HALF_PTR {
	MAXHALF_PTR = HALF_PTR.max,
	MINHALF_PTR = HALF_PTR.min
}

alias byte INT8;
alias byte* PINT8;
alias ubyte UINT8;
alias ubyte* PUINT8;

alias short INT16;
alias short* PINT16;
alias ushort UINT16;
alias ushort* PUINT16;

alias int LONG32, INT32;
alias int* PLONG32, PINT32;
alias uint ULONG32, DWORD32, UINT32;
alias uint* PULONG32, PDWORD32, PUINT32;

alias ULONG_PTR SIZE_T, DWORD_PTR;
alias ULONG_PTR* PSIZE_T, PDWORD_PTR;
alias LONG_PTR SSIZE_T;
alias LONG_PTR* PSSIZE_T;

alias long LONG64, INT64;
alias long* PLONG64, PINT64;
alias ulong ULONG64, DWORD64, UINT64;
alias ulong* PULONG64, PDWORD64, PUINT64;
