/***********************************************************************\
*                               httpext.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.httpext;

/* Comment from MinGW
       httpext.h - Header for ISAPI extensions.

       This file is part of a free library for the Win32 API.

       This library is distributed in the hope that it will be useful,
       but WITHOUT ANY WARRANTY; without even the implied warranty of
       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

private import win32.windows;

enum {
    HSE_VERSION_MAJOR               = 2,
    HSE_VERSION_MINOR               = 0,
    HSE_LOG_BUFFER_LEN              = 80,
    HSE_MAX_EXT_DLL_NAME_LEN        = 256,
    HSE_STATUS_SUCCESS              = 1,
    HSE_STATUS_SUCCESS_AND_KEEP_CONN,
    HSE_STATUS_PENDING,
    HSE_STATUS_ERROR,
    HSE_REQ_BASE                    = 0,
    HSE_REQ_SEND_URL_REDIRECT_RESP,
    HSE_REQ_SEND_URL,
    HSE_REQ_SEND_RESPONSE_HEADER,
    HSE_REQ_DONE_WITH_SESSION,
    HSE_REQ_SEND_RESPONSE_HEADER_EX = 1016,
    HSE_REQ_END_RESERVED            = 1000,
    HSE_TERM_ADVISORY_UNLOAD        = 0x00000001,
    HSE_TERM_MUST_UNLOAD,
    HSE_IO_SYNC                     = 0x00000001,
    HSE_IO_ASYNC,
    HSE_IO_DISCONNECT_AFTER_SEND    = 0x00000004,
    HSE_IO_SEND_HEADERS             = 0x00000008
}

alias HANDLE HCONN;

struct HSE_VERSION_INFO {
	DWORD dwExtensionVersion;
	CHAR[HSE_MAX_EXT_DLL_NAME_LEN] lpszExtensionDesc;
}
alias HSE_VERSION_INFO* LPHSE_VERSION_INFO;

struct EXTENSION_CONTROL_BLOCK {
	DWORD  cbSize = EXTENSION_CONTROL_BLOCK.sizeof;
	DWORD  dwVersion;
	HCONN  ConnID;
	DWORD  dwHttpStatusCode;
	CHAR[HSE_LOG_BUFFER_LEN] lpszLogData;
	LPSTR  lpszMethod;
	LPSTR  lpszQueryString;
	LPSTR  lpszPathInfo;
	LPSTR  lpszPathTranslated;
	DWORD  cbTotalBytes;
	DWORD  cbAvailable;
	LPBYTE lpbData;
	LPSTR  lpszContentType;
	extern(Pascal) BOOL function(HCONN, LPSTR, LPVOID, LPDWORD)
	  GetServerVariable;
	extern(Pascal) BOOL function(HCONN, LPVOID, LPDWORD, DWORD) WriteClient;
	extern(Pascal) BOOL function(HCONN, LPVOID, LPDWORD) ReadClient;
	extern(Pascal) BOOL function(HCONN, DWORD, LPVOID, LPDWORD, LPDWORD)
	  ServerSupportFunction;
}
alias EXTENSION_CONTROL_BLOCK* LPEXTENSION_CONTROL_BLOCK;

extern (Pascal) {
	alias BOOL function(HSE_VERSION_INFO*) PFN_GETEXTENSIONVERSION;
	alias DWORD function(EXTENSION_CONTROL_BLOCK*) PFN_HTTPEXTENSIONPROC;
	alias BOOL function(DWORD) PFN_TERMINATEEXTENSION;
	alias VOID function(EXTENSION_CONTROL_BLOCK*, PVOID, DWORD, DWORD) PFN_HSE_IO_COMPLETION;
}

struct HSE_TF_INFO {
	PFN_HSE_IO_COMPLETION pfnHseIO;
	PVOID  pContext;
	HANDLE hFile;
	LPCSTR pszStatusCode;
	DWORD  BytesToWrite;
	DWORD  Offset;
	PVOID  pHead;
	DWORD  HeadLength;
	PVOID  pTail;
	DWORD  TailLength;
	DWORD  dwFlags;
}
alias HSE_TF_INFO* LPHSE_TF_INFO;

struct HSE_SEND_HEADER_EX_INFO {
	LPCSTR pszStatus;
	LPCSTR pszHeader;
	DWORD  cchStatus;
	DWORD  cchHeader;
	BOOL   fKeepConn;
}
alias HSE_SEND_HEADER_EX_INFO* LPHSE_SEND_HEADER_EX_INF;

extern (Pascal) {
	BOOL GetExtensionVersion(HSE_VERSION_INFO*);
	DWORD HttpExtensionProc(EXTENSION_CONTROL_BLOCK*);
	BOOL TerminateExtension(DWORD);
}
