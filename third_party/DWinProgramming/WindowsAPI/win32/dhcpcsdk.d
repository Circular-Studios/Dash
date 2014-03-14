/***********************************************************************\
*                               dhcpcsdk.d                              *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.dhcpcsdk;

private import win32.w32api, win32.windef;

static assert (_WIN32_WINNT_ONLY && _WIN32_WINNT >= 0x500,
"win32.dhcpcsdk is available only if version WindowsXP, Windows2003
or WindowsVista is set, or both Windows2000 and WindowsNTonly are set");

//#if (_WIN32_WINNT >= 0x0500)

// FIXME: check type
const DHCPCAPI_REGISTER_HANDLE_EVENT = 1;
const DHCPCAPI_REQUEST_PERSISTENT    = 1;
const DHCPCAPI_REQUEST_SYNCHRONOUS   = 2;

struct DHCPCAPI_CLASSID {
	ULONG  Flags;
	LPBYTE Data;
	ULONG  nBytesData;
}
alias DHCPCAPI_CLASSID* PDHCPCAPI_CLASSID, LPDHCPCAPI_CLASSID;

struct DHCPAPI_PARAMS {
	ULONG  Flags;
	ULONG  OptionId;
	BOOL   IsVendor;
	LPBYTE Data;
	DWORD  nBytesData;
}
alias DHCPAPI_PARAMS* PDHCPAPI_PARAMS, LPDHCPAPI_PARAMS;

struct DHCPCAPI_PARAMS_ARRAY {
	ULONG            nParams;
	LPDHCPAPI_PARAMS Params;
}
alias DHCPCAPI_PARAMS_ARRAY* PDHCPCAPI_PARAMS_ARRAY, LPDHCPCAPI_PARAMS_ARRAY;

extern (Windows) {
	void DhcpCApiCleanup();
	DWORD DhcpCApiInitialize(LPDWORD);
	DWORD DhcpDeRegisterParamChange(DWORD, LPVOID, LPVOID);
	DWORD DhcpRegisterParamChange(DWORD, LPVOID, PWSTR, LPDHCPCAPI_CLASSID,
	  DHCPCAPI_PARAMS_ARRAY, LPVOID);
	DWORD DhcpRemoveDNSRegistrations();
	DWORD DhcpUndoRequestParams(DWORD, LPVOID, LPWSTR, LPWSTR);
}

//#endif // (_WIN32_WINNT >= 0x0500)
