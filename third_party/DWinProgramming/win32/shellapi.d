/***********************************************************************\
*                               shellapi.d                              *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.shellapi;
pragma(lib, "shell32.lib");

private import win32.w32api, win32.windef, win32.basetyps;

enum : UINT {
	ABE_LEFT,
	ABE_TOP,
	ABE_RIGHT,
	ABE_BOTTOM // = 3
}

enum : UINT {
	ABS_AUTOHIDE    = 1,
	ABS_ALWAYSONTOP
}

const ULONG
	SEE_MASK_CLASSNAME      =        1,
	SEE_MASK_CLASSKEY       =        3,
	SEE_MASK_IDLIST         =        4,
	SEE_MASK_INVOKEIDLIST   =       12,
	SEE_MASK_ICON           = 0x000010,
	SEE_MASK_HOTKEY         = 0x000020,
	SEE_MASK_NOCLOSEPROCESS = 0x000040,
	SEE_MASK_CONNECTNETDRV  = 0x000080,
	SEE_MASK_FLAG_DDEWAIT   = 0x000100,
	SEE_MASK_DOENVSUBST     = 0x000200,
	SEE_MASK_FLAG_NO_UI     = 0x000400,
	SEE_MASK_NO_CONSOLE     = 0x008000,
	SEE_MASK_UNICODE        = 0x010000,
	SEE_MASK_ASYNCOK        = 0x100000,
	SEE_MASK_HMONITOR       = 0x200000;

enum : DWORD {
	ABM_NEW,
	ABM_REMOVE,
	ABM_QUERYPOS,
	ABM_SETPOS,
	ABM_GETSTATE,
	ABM_GETTASKBARPOS,
	ABM_ACTIVATE,
	ABM_GETAUTOHIDEBAR,
	ABM_SETAUTOHIDEBAR,
	ABM_WINDOWPOSCHANGED // = 9
}

static if (WINVER >= 0x501) {
	const DWORD ABM_SETSTATE = 10;
}

enum : UINT {
	ABN_STATECHANGE,
	ABN_POSCHANGED,
	ABN_FULLSCREENAPP,
	ABN_WINDOWARRANGE
}

enum : DWORD {
	NIM_ADD,
	NIM_MODIFY,
	NIM_DELETE
}

static if (_WIN32_IE >= 0x500) {
	const NOTIFYICON_VERSION = 3;

	enum : DWORD {
		NIM_SETFOCUS = 3,
		NIM_SETVERSION
	}
}

const UINT
	NIF_MESSAGE = 1,
	NIF_ICON    = 2,
	NIF_TIP     = 4,
	NIF_STATE   = 8;

static if (_WIN32_IE >= 0x500) {
	const UINT NIF_INFO = 0x00000010;
}

static if (_WIN32_IE >= 0x600) {
	const UINT NIF_GUID = 0x00000020;
}

static if (_WIN32_IE >= 0x500) {
	enum : DWORD {
		NIIF_NONE,
		NIIF_INFO,
		NIIF_WARNING,
		NIIF_ERROR
	}
}

static if (_WIN32_IE >= 0x600) {
	enum : DWORD {
		NIIF_ICON_MASK = 15,
		NIIF_NOSOUND
	}
}

const DWORD
	NIS_HIDDEN     = 1,
	NIS_SHAREDICON = 2;

const HINSTANCE
	SE_ERR_FNF             = cast(HANDLE)  2,
	SE_ERR_PNF             = cast(HANDLE)  3,
	SE_ERR_ACCESSDENIED    = cast(HANDLE)  5,
	SE_ERR_OOM             = cast(HANDLE)  8,
	SE_ERR_DLLNOTFOUND     = cast(HANDLE) 32,
	SE_ERR_SHARE           = cast(HANDLE) 26,
	SE_ERR_ASSOCINCOMPLETE = cast(HANDLE) 27,
	SE_ERR_DDETIMEOUT      = cast(HANDLE) 28,
	SE_ERR_DDEFAIL         = cast(HANDLE) 29,
	SE_ERR_DDEBUSY         = cast(HANDLE) 30,
	SE_ERR_NOASSOC         = cast(HANDLE) 31;

enum : UINT {
	FO_MOVE = 1,
	FO_COPY,
	FO_DELETE,
	FO_RENAME
}

const FILEOP_FLAGS
	FOF_MULTIDESTFILES        = 0x0001,
	FOF_CONFIRMMOUSE          = 0x0002,
	FOF_SILENT                = 0x0004,
	FOF_RENAMEONCOLLISION     = 0x0008,
	FOF_NOCONFIRMATION        = 0x0010,
	FOF_WANTMAPPINGHANDLE     = 0x0020,
	FOF_ALLOWUNDO             = 0x0040,
	FOF_FILESONLY             = 0x0080,
	FOF_SIMPLEPROGRESS        = 0x0100,
	FOF_NOCONFIRMMKDIR        = 0x0200,
	FOF_NOERRORUI             = 0x0400,
	FOF_NOCOPYSECURITYATTRIBS = 0x0800;

// these are not documented on the MSDN site
enum {
	PO_DELETE     = 19,
	PO_RENAME     = 20,
	PO_PORTCHANGE = 32,
	PO_REN_PORT   = 52
}

const UINT
	SHGFI_LARGEICON         = 0x000000,
	SHGFI_SMALLICON         = 0x000001,
	SHGFI_OPENICON          = 0x000002,
	SHGFI_SHELLICONSIZE     = 0x000004,
	SHGFI_PIDL              = 0x000008,
	SHGFI_USEFILEATTRIBUTES = 0x000010,
	SHGFI_ICON              = 0x000100,
	SHGFI_DISPLAYNAME       = 0x000200,
	SHGFI_TYPENAME          = 0x000400,
	SHGFI_ATTRIBUTES        = 0x000800,
	SHGFI_ICONLOCATION      = 0x001000,
	SHGFI_EXETYPE           = 0x002000,
	SHGFI_SYSICONINDEX      = 0x004000,
	SHGFI_LINKOVERLAY       = 0x008000,
	SHGFI_SELECTED          = 0x010000,
	SHGFI_ATTR_SPECIFIED    = 0x020000;

const SHERB_NOCONFIRMATION = 1;
const SHERB_NOPROGRESSUI   = 2;
const SHERB_NOSOUND        = 4;

alias WORD FILEOP_FLAGS, PRINTEROP_FLAGS;
alias HANDLE HDROP;

align(2):

struct APPBARDATA {
	DWORD  cbSize = APPBARDATA.sizeof;
	HWND   hWnd;
	UINT   uCallbackMessage;
	UINT   uEdge;
	RECT   rc;
	LPARAM lParam;
}
alias APPBARDATA* PAPPBARDATA;

struct NOTIFYICONDATAA {
	DWORD cbSize = NOTIFYICONDATAA.sizeof;
	HWND  hWnd;
	UINT  uID;
	UINT  uFlags;
	UINT  uCallbackMessage;
	HICON hIcon;
	static if (_WIN32_IE >= 0x500) {
		CHAR[128] szTip;
		DWORD     dwState;
		DWORD     dwStateMask;
		CHAR[256] szInfo;
		union {
			UINT  uTimeout;
			UINT  uVersion;
		}
		CHAR[64]  szInfoTitle;
		DWORD     dwInfoFlags;
	} else {
		CHAR[64]  szTip;
	}
	static if (_WIN32_IE >= 0x600) {
		GUID      guidItem;
	}
}
alias NOTIFYICONDATAA* PNOTIFYICONDATAA;

struct NOTIFYICONDATAW {
	DWORD cbSize = NOTIFYICONDATAW.sizeof;
	HWND  hWnd;
	UINT  uID;
	UINT  uFlags;
	UINT  uCallbackMessage;
	HICON hIcon;
	static if (_WIN32_IE >= 0x500) {
		WCHAR[128] szTip;
		DWORD      dwState;
		DWORD      dwStateMask;
		WCHAR[256] szInfo;
		union {
			UINT   uTimeout;
			UINT   uVersion;
		}
		WCHAR[64]  szInfoTitle;
		DWORD      dwInfoFlags;
	} else {
		WCHAR[64]  szTip;
	}
	static if (_WIN32_IE >= 0x600) {
		GUID guidItem;
	}
}
alias NOTIFYICONDATAW* PNOTIFYICONDATAW;

struct SHELLEXECUTEINFOA {
	DWORD     cbSize = SHELLEXECUTEINFOA.sizeof;
	ULONG     fMask;
	HWND      hwnd;
	LPCSTR    lpVerb;
	LPCSTR    lpFile;
	LPCSTR    lpParameters;
	LPCSTR    lpDirectory;
	int       nShow;
	HINSTANCE hInstApp;
	PVOID     lpIDList;
	LPCSTR    lpClass;
	HKEY      hkeyClass;
	DWORD     dwHotKey;
	HANDLE    hIcon;
	HANDLE    hProcess;
}
alias SHELLEXECUTEINFOA* LPSHELLEXECUTEINFOA;

struct SHELLEXECUTEINFOW {
	DWORD     cbSize = SHELLEXECUTEINFOW.sizeof;
	ULONG     fMask;
	HWND      hwnd;
	LPCWSTR   lpVerb;
	LPCWSTR   lpFile;
	LPCWSTR   lpParameters;
	LPCWSTR   lpDirectory;
	int       nShow;
	HINSTANCE hInstApp;
	PVOID     lpIDList;
	LPCWSTR   lpClass;
	HKEY      hkeyClass;
	DWORD     dwHotKey;
	HANDLE    hIcon;
	HANDLE    hProcess;
}
alias SHELLEXECUTEINFOW* LPSHELLEXECUTEINFOW;

struct SHFILEOPSTRUCTA {
	HWND         hwnd;
	UINT         wFunc;
	LPCSTR       pFrom;
	LPCSTR       pTo;
	FILEOP_FLAGS fFlags;
	BOOL         fAnyOperationsAborted;
	PVOID        hNameMappings;
	LPCSTR       lpszProgressTitle;
}
alias SHFILEOPSTRUCTA* LPSHFILEOPSTRUCTA;

struct SHFILEOPSTRUCTW {
	HWND         hwnd;
	UINT         wFunc;
	LPCWSTR      pFrom;
	LPCWSTR      pTo;
	FILEOP_FLAGS fFlags;
	BOOL         fAnyOperationsAborted;
	PVOID        hNameMappings;
	LPCWSTR      lpszProgressTitle;
}
alias SHFILEOPSTRUCTW* LPSHFILEOPSTRUCTW;

struct SHFILEINFOA {
	HICON          hIcon;
	int            iIcon;
	DWORD          dwAttributes;
	CHAR[MAX_PATH] szDisplayName;
	CHAR[80]       szTypeName;
}

struct SHFILEINFOW {
	HICON           hIcon;
	int             iIcon;
	DWORD           dwAttributes;
	WCHAR[MAX_PATH] szDisplayName;
	WCHAR[80]       szTypeName;
}

struct SHQUERYRBINFO {
	DWORD cbSize = SHQUERYRBINFO.sizeof;
	long  i64Size;
	long  i64NumItems;
}
alias SHQUERYRBINFO* LPSHQUERYRBINFO;

extern (Windows) {
	LPWSTR* CommandLineToArgvW(LPCWSTR, int*);
	void DragAcceptFiles(HWND, BOOL);
	void DragFinish(HDROP);
	UINT DragQueryFileA(HDROP, UINT, LPSTR, UINT);
	UINT DragQueryFileW(HDROP, UINT, LPWSTR, UINT);
	BOOL DragQueryPoint(HDROP, LPPOINT);
	HICON DuplicateIcon(HINSTANCE, HICON);
	HICON ExtractAssociatedIconA(HINSTANCE, LPCSTR, PWORD);
	HICON ExtractAssociatedIconW(HINSTANCE, LPCWSTR, PWORD);
	HICON ExtractIconA(HINSTANCE, LPCSTR, UINT);
	HICON ExtractIconW(HINSTANCE, LPCWSTR, UINT);
	UINT ExtractIconExA(LPCSTR, int, HICON*, HICON*, UINT);
	UINT ExtractIconExW(LPCWSTR, int, HICON*, HICON*, UINT);
	HINSTANCE FindExecutableA(LPCSTR, LPCSTR, LPSTR);
	HINSTANCE FindExecutableW(LPCWSTR, LPCWSTR, LPWSTR);
	UINT SHAppBarMessage(DWORD, PAPPBARDATA);
	BOOL Shell_NotifyIconA(DWORD, PNOTIFYICONDATAA);
	BOOL Shell_NotifyIconW(DWORD, PNOTIFYICONDATAW);
	int ShellAboutA(HWND, LPCSTR, LPCSTR, HICON);
	int ShellAboutW(HWND, LPCWSTR, LPCWSTR, HICON);
	HINSTANCE ShellExecuteA(HWND, LPCSTR, LPCSTR, LPCSTR, LPCSTR, INT);
	HINSTANCE ShellExecuteW(HWND, LPCWSTR, LPCWSTR, LPCWSTR, LPCWSTR, INT);
	BOOL ShellExecuteExA(LPSHELLEXECUTEINFOA);
	BOOL ShellExecuteExW(LPSHELLEXECUTEINFOW);
	int SHFileOperationA(LPSHFILEOPSTRUCTA);
	int SHFileOperationW(LPSHFILEOPSTRUCTW);
	void SHFreeNameMappings(HANDLE);
	DWORD SHGetFileInfoA(LPCSTR, DWORD, SHFILEINFOA*, UINT, UINT);
	DWORD SHGetFileInfoW(LPCWSTR, DWORD, SHFILEINFOW*, UINT, UINT);
	HRESULT SHQueryRecycleBinA(LPCSTR,  LPSHQUERYRBINFO);
	HRESULT SHQueryRecycleBinW(LPCWSTR,  LPSHQUERYRBINFO);
	HRESULT SHEmptyRecycleBinA(HWND, LPCSTR, DWORD);
	HRESULT SHEmptyRecycleBinW(HWND, LPCWSTR, DWORD);
}

version (Unicode) {
	alias NOTIFYICONDATAW NOTIFYICONDATA;
	alias SHELLEXECUTEINFOW SHELLEXECUTEINFO;
	alias SHFILEOPSTRUCTW SHFILEOPSTRUCT;
	alias SHFILEINFOW SHFILEINFO;
	alias DragQueryFileW DragQueryFile;
	alias ExtractAssociatedIconW ExtractAssociatedIcon;
	alias ExtractIconW ExtractIcon;
	alias ExtractIconExW ExtractIconEx;
	alias FindExecutableW FindExecutable;
	alias Shell_NotifyIconW Shell_NotifyIcon;
	alias ShellAboutW ShellAbout;
	alias ShellExecuteW ShellExecute;
	alias ShellExecuteExW ShellExecuteEx;
	alias SHFileOperationW SHFileOperation;
	alias SHGetFileInfoW SHGetFileInfo;
	alias SHQueryRecycleBinW SHQueryRecycleBin;
	alias SHEmptyRecycleBinW SHEmptyRecycleBin;
} else {
	alias NOTIFYICONDATAA NOTIFYICONDATA;
	alias SHELLEXECUTEINFOA SHELLEXECUTEINFO;
	alias SHFILEOPSTRUCTA SHFILEOPSTRUCT;
	alias SHFILEINFOA SHFILEINFO;
	alias DragQueryFileA DragQueryFile;
	alias ExtractAssociatedIconA ExtractAssociatedIcon;
	alias ExtractIconA ExtractIcon;
	alias ExtractIconExA ExtractIconEx;
	alias FindExecutableA FindExecutable;
	alias Shell_NotifyIconA Shell_NotifyIcon;
	alias ShellAboutA ShellAbout;
	alias ShellExecuteA ShellExecute;
	alias ShellExecuteExA ShellExecuteEx;
	alias SHFileOperationA SHFileOperation;
	alias SHGetFileInfoA SHGetFileInfo;
	alias SHQueryRecycleBinA SHQueryRecycleBin;
	alias SHEmptyRecycleBinA SHEmptyRecycleBin;
}

alias NOTIFYICONDATA* PNOTIFYICONDATA;
alias SHELLEXECUTEINFO* LPSHELLEXECUTEINFO;
alias SHFILEOPSTRUCT* LPSHFILEOPSTRUCT;
