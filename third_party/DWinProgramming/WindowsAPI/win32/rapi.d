/***********************************************************************\
*                                 rapi.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.rapi;

/* Comment from MinGW
	NOTE: This strictly does not belong in the Win32 API since it's
	really part of Platform SDK.
 */

private import win32.winbase, win32.windef;

struct IRAPIStream {
	IRAPIStreamVtbl* lpVtbl;
}

enum RAPISTREAMFLAG {
	STREAM_TIMEOUT_READ
}

extern (Windows) {
	alias HRESULT function(IRAPIStream*, RAPISTREAMFLAG, DWORD)  _SetRapiStat;
	alias HRESULT function(IRAPIStream*, RAPISTREAMFLAG, DWORD*) _GetRapiStat;
}

struct IRAPIStreamVtbl {
	_SetRapiStat SetRapiStat;
	_GetRapiStat GetRapiStat;
}

// FIXME: what's this?
//typedef HRESULT(STDAPICALLTYPE RAPIEXT)(DWORD, BYTE, DWORD, BYTE, IRAPIStream*);

struct RAPIINIT {
	DWORD   cbSize = this.sizeof;
	HANDLE  heRapiInit;
	HRESULT hrRapiInit;
}

extern (Windows) {
	HRESULT CeRapiInit();
	HRESULT CeRapiInitEx(RAPIINIT*);
	BOOL CeCreateProcess(LPCWSTR, LPCWSTR, LPSECURITY_ATTRIBUTES,
	  LPSECURITY_ATTRIBUTES, BOOL, DWORD, LPVOID, LPWSTR, LPSTARTUPINFO,
	  LPPROCESS_INFORMATION);
	HRESULT CeRapiUninit();
	BOOL CeWriteFile(HANDLE, LPCVOID, DWORD, LPDWORD, LPOVERLAPPED);
	HANDLE CeCreateFile(LPCWSTR, DWORD, DWORD, LPSECURITY_ATTRIBUTES, DWORD,
	  DWORD, HANDLE);
	BOOL CeCreateDirectory(LPCWSTR, LPSECURITY_ATTRIBUTES);
	DWORD CeGetLastError();
	BOOL CeGetFileTime(HANDLE, LPFILETIME, LPFILETIME, LPFILETIME);
	BOOL CeCloseHandle(HANDLE);
}
