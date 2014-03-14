/***********************************************************************\
*                                rpcnsi.d                               *
*                                                                       *
*                       Windows API header module                       *
*                     RPC Name Service (RpcNs APIs)                     *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.rpcnsi;
pragma(lib, "rpcns4.lib");

private import win32.basetyps, win32.rpcdcep, win32.rpcnsi, win32.rpcdce,
  win32.w32api;
private import win32.windef;  // for HANDLE

alias HANDLE RPC_NS_HANDLE;

const RPC_C_NS_SYNTAX_DEFAULT=0;
const RPC_C_NS_SYNTAX_DCE=3;
const RPC_C_PROFILE_DEFAULT_ELT=0;
const RPC_C_PROFILE_ALL_ELT=1;
const RPC_C_PROFILE_MATCH_BY_IF=2;
const RPC_C_PROFILE_MATCH_BY_MBR=3;
const RPC_C_PROFILE_MATCH_BY_BOTH=4;
const RPC_C_NS_DEFAULT_EXP_AGE=-1;

extern (Windows) {
	RPC_STATUS RpcNsBindingExportA(uint, ubyte*, RPC_IF_HANDLE,
	  RPC_BINDING_VECTOR*, UUID_VECTOR*);
	RPC_STATUS RpcNsBindingUnexportA(uint, ubyte*, RPC_IF_HANDLE,
	  UUID_VECTOR*);
	RPC_STATUS RpcNsBindingLookupBeginA(uint, ubyte*, RPC_IF_HANDLE, UUID*,
	  uint, RPC_NS_HANDLE*);
	RPC_STATUS RpcNsBindingLookupNext(RPC_NS_HANDLE, RPC_BINDING_VECTOR**);
	RPC_STATUS RpcNsBindingLookupDone(RPC_NS_HANDLE*);
	RPC_STATUS RpcNsGroupDeleteA(uint, ubyte*);
	RPC_STATUS RpcNsGroupMbrAddA(uint, ubyte*, uint, ubyte*);
	RPC_STATUS RpcNsGroupMbrRemoveA(uint, ubyte*, uint, ubyte*);
	RPC_STATUS RpcNsGroupMbrInqBeginA(uint, ubyte*, uint, RPC_NS_HANDLE*);
	RPC_STATUS RpcNsGroupMbrInqNextA(RPC_NS_HANDLE, ubyte**);
	RPC_STATUS RpcNsGroupMbrInqDone(RPC_NS_HANDLE*);
	RPC_STATUS RpcNsProfileDeleteA(uint, ubyte*);
	RPC_STATUS RpcNsProfileEltAddA(uint, ubyte*, RPC_IF_ID*, uint, ubyte*,
	  uint, ubyte*);
	RPC_STATUS RpcNsProfileEltRemoveA(uint, ubyte*, RPC_IF_ID*, uint, ubyte*);
	RPC_STATUS RpcNsProfileEltInqBeginA(uint, ubyte*, uint, RPC_IF_ID*, uint,
	  uint, ubyte*, RPC_NS_HANDLE*);
	RPC_STATUS RpcNsProfileEltInqNextA(RPC_NS_HANDLE, RPC_IF_ID*, ubyte**,
	  uint*, ubyte**);
	RPC_STATUS RpcNsProfileEltInqDone(RPC_NS_HANDLE*);
	RPC_STATUS RpcNsEntryObjectInqNext(in RPC_NS_HANDLE, out UUID*);
	RPC_STATUS RpcNsEntryObjectInqDone(ref RPC_NS_HANDLE*);
	RPC_STATUS RpcNsEntryExpandNameA(uint, ubyte*, ubyte**);
	RPC_STATUS RpcNsMgmtBindingUnexportA(uint, ubyte*, RPC_IF_ID*, uint,
	  UUID_VECTOR*);
	RPC_STATUS RpcNsMgmtEntryCreateA(uint, ubyte*);
	RPC_STATUS RpcNsMgmtEntryDeleteA(uint, ubyte*);
	RPC_STATUS RpcNsMgmtEntryInqIfIdsA(uint, ubyte*, RPC_IF_ID_VECTOR**);
	RPC_STATUS RpcNsMgmtHandleSetExpAge(RPC_NS_HANDLE, uint);
	RPC_STATUS RpcNsMgmtInqExpAge(uint*);
	RPC_STATUS RpcNsMgmtSetExpAge(uint);
	RPC_STATUS RpcNsBindingImportNext(RPC_NS_HANDLE, RPC_BINDING_HANDLE*);
	RPC_STATUS RpcNsBindingImportDone(RPC_NS_HANDLE*);
	RPC_STATUS RpcNsBindingSelect(RPC_BINDING_VECTOR*, RPC_BINDING_HANDLE*);
}

// For the cases where Win95, 98, ME have no _W versions, and we must alias to
// _A even for version(Unicode).

version (Unicode) {
	static if (_WIN32_WINNT_ONLY) {
		const bool _WIN32_USE_UNICODE = true;
	} else {
		const bool _WIN32_USE_UNICODE = false;
	}
} else {
	const bool _WIN32_USE_UNICODE = false;
}

static if (!_WIN32_USE_UNICODE) {
	RPC_STATUS RpcNsEntryObjectInqBeginA(uint, ubyte*, RPC_NS_HANDLE*);
	RPC_STATUS RpcNsBindingImportBeginA(uint, ubyte*, RPC_IF_HANDLE, UUID*,
	  RPC_NS_HANDLE*);
}

static if (_WIN32_WINNT_ONLY) {
	RPC_STATUS RpcNsBindingExportW(uint, ushort*, RPC_IF_HANDLE,
	  RPC_BINDING_VECTOR*, UUID_VECTOR*);
	RPC_STATUS RpcNsBindingUnexportW(uint, ushort*, RPC_IF_HANDLE,
	  UUID_VECTOR*);
	RPC_STATUS RpcNsBindingLookupBeginW(uint, ushort*, RPC_IF_HANDLE, UUID*,
	  uint, RPC_NS_HANDLE*);
	RPC_STATUS RpcNsGroupDeleteW(uint, ushort*);
	RPC_STATUS RpcNsGroupMbrAddW(uint, ushort*, uint, ushort*);
	RPC_STATUS RpcNsGroupMbrRemoveW(uint, ushort*, uint, ushort*);
	RPC_STATUS RpcNsGroupMbrInqBeginW(uint, ushort*, uint, RPC_NS_HANDLE*);
	RPC_STATUS RpcNsGroupMbrInqNextW(RPC_NS_HANDLE, ushort**);
	RPC_STATUS RpcNsProfileDeleteW(uint, ushort*);
	RPC_STATUS RpcNsProfileEltAddW(uint, ushort*, RPC_IF_ID*, uint, ushort*,
	  uint, ushort*);
	RPC_STATUS RpcNsProfileEltRemoveW(uint, ushort*, RPC_IF_ID*, uint,
	  ushort*);
	RPC_STATUS RpcNsProfileEltInqBeginW(uint, ushort*, uint, RPC_IF_ID*,
	  uint, uint, ushort*, RPC_NS_HANDLE*);
	RPC_STATUS RpcNsProfileEltInqNextW(RPC_NS_HANDLE, RPC_IF_ID*, ushort**,
	  uint*, ushort**);
	RPC_STATUS RpcNsEntryObjectInqBeginW(uint, ushort*, RPC_NS_HANDLE*);
	RPC_STATUS RpcNsEntryExpandNameW(uint, ushort*, ushort**);
	RPC_STATUS RpcNsMgmtBindingUnexportW(uint, ushort*, RPC_IF_ID*, uint,
	  UUID_VECTOR*);
	RPC_STATUS RpcNsMgmtEntryCreateW(uint, ushort*);
	RPC_STATUS RpcNsMgmtEntryDeleteW(uint, ushort*);
	RPC_STATUS RpcNsMgmtEntryInqIfIdsW(uint, ushort , RPC_IF_ID_VECTOR**);
	RPC_STATUS RpcNsBindingImportBeginW(uint, ushort*, RPC_IF_HANDLE, UUID*,
	  RPC_NS_HANDLE*);
} // _WIN32_WINNT_ONLY

static if (_WIN32_USE_UNICODE) {
	alias RpcNsBindingLookupBeginW RpcNsBindingLookupBegin;
	alias RpcNsBindingImportBeginW RpcNsBindingImportBegin;
	alias RpcNsBindingExportW RpcNsBindingExport;
	alias RpcNsBindingUnexportW RpcNsBindingUnexport;
	alias RpcNsGroupDeleteW RpcNsGroupDelete;
	alias RpcNsGroupMbrAddW RpcNsGroupMbrAdd;
	alias RpcNsGroupMbrRemoveW RpcNsGroupMbrRemove;
	alias RpcNsGroupMbrInqBeginW RpcNsGroupMbrInqBegin;
	alias RpcNsGroupMbrInqNextW RpcNsGroupMbrInqNext;
	alias RpcNsEntryExpandNameW RpcNsEntryExpandName;
	alias RpcNsEntryObjectInqBeginW RpcNsEntryObjectInqBegin;
	alias RpcNsMgmtBindingUnexportW RpcNsMgmtBindingUnexport;
	alias RpcNsMgmtEntryCreateW RpcNsMgmtEntryCreate;
	alias RpcNsMgmtEntryDeleteW RpcNsMgmtEntryDelete;
	alias RpcNsMgmtEntryInqIfIdsW RpcNsMgmtEntryInqIfIds;
	alias RpcNsProfileDeleteW RpcNsProfileDelete;
	alias RpcNsProfileEltAddW RpcNsProfileEltAdd;
	alias RpcNsProfileEltRemoveW RpcNsProfileEltRemove;
	alias RpcNsProfileEltInqBeginW RpcNsProfileEltInqBegin;
	alias RpcNsProfileEltInqNextW RpcNsProfileEltInqNext;
} else {
	alias RpcNsBindingLookupBeginA RpcNsBindingLookupBegin;
	alias RpcNsBindingImportBeginA RpcNsBindingImportBegin;
	alias RpcNsBindingExportA RpcNsBindingExport;
	alias RpcNsBindingUnexportA RpcNsBindingUnexport;
	alias RpcNsGroupDeleteA RpcNsGroupDelete;
	alias RpcNsGroupMbrAddA RpcNsGroupMbrAdd;
	alias RpcNsGroupMbrRemoveA RpcNsGroupMbrRemove;
	alias RpcNsGroupMbrInqBeginA RpcNsGroupMbrInqBegin;
	alias RpcNsGroupMbrInqNextA RpcNsGroupMbrInqNext;
	alias RpcNsEntryExpandNameA RpcNsEntryExpandName;
	alias RpcNsEntryObjectInqBeginA RpcNsEntryObjectInqBegin;
	alias RpcNsMgmtBindingUnexportA RpcNsMgmtBindingUnexport;
	alias RpcNsMgmtEntryCreateA RpcNsMgmtEntryCreate;
	alias RpcNsMgmtEntryDeleteA RpcNsMgmtEntryDelete;
	alias RpcNsMgmtEntryInqIfIdsA RpcNsMgmtEntryInqIfIds;
	alias RpcNsProfileDeleteA RpcNsProfileDelete;
	alias RpcNsProfileEltAddA RpcNsProfileEltAdd;
	alias RpcNsProfileEltRemoveA RpcNsProfileEltRemove;
	alias RpcNsProfileEltInqBeginA RpcNsProfileEltInqBegin;
	alias RpcNsProfileEltInqNextA RpcNsProfileEltInqNext;
}
