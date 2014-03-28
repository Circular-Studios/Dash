/***********************************************************************\
*                                winver.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.winver;

private import win32.windef;

// FIXME: type weirdness
enum {
	VS_FILE_INFO    =  16,
	VS_VERSION_INFO =   1,
	VS_USER_DEFINED = 100
}

enum {
	VS_FFI_SIGNATURE     = 0xFEEF04BD,
	VS_FFI_STRUCVERSION  =    0x10000,
	VS_FFI_FILEFLAGSMASK =       0x3F
}

enum {
	VS_FF_DEBUG        =  1,
	VS_FF_PRERELEASE   =  2,
	VS_FF_PATCHED      =  4,
	VS_FF_PRIVATEBUILD =  8,
	VS_FF_INFOINFERRED = 16,
	VS_FF_SPECIALBUILD = 32
}

enum {
	VOS_UNKNOWN       =       0,
	VOS_DOS           = 0x10000,
	VOS_OS216         = 0x20000,
	VOS_OS232         = 0x30000,
	VOS_NT            = 0x40000,
	VOS__BASE         =       0,
	VOS__WINDOWS16    =       1,
	VOS__PM16         =       2,
	VOS__PM32         =       3,
	VOS__WINDOWS32    =       4,
	VOS_DOS_WINDOWS16 = 0x10001,
	VOS_DOS_WINDOWS32 = 0x10004,
	VOS_OS216_PM16    = 0x20002,
	VOS_OS232_PM32    = 0x30003,
	VOS_NT_WINDOWS32  = 0x40004
}

enum {
	VFT_UNKNOWN    = 0,
	VFT_APP        = 1,
	VFT_DLL        = 2,
	VFT_DRV        = 3,
	VFT_FONT       = 4,
	VFT_VXD        = 5,
	VFT_STATIC_LIB = 7
}

enum {
	VFT2_UNKNOWN         =  0,
	VFT2_DRV_PRINTER     =  1,
	VFT2_DRV_KEYBOARD    =  2,
	VFT2_DRV_LANGUAGE    =  3,
	VFT2_DRV_DISPLAY     =  4,
	VFT2_DRV_MOUSE       =  5,
	VFT2_DRV_NETWORK     =  6,
	VFT2_DRV_SYSTEM      =  7,
	VFT2_DRV_INSTALLABLE =  8,
	VFT2_DRV_SOUND       =  9,
	VFT2_DRV_COMM        = 10,
	VFT2_DRV_INPUTMETHOD = 11,
	VFT2_FONT_RASTER     =  1,
	VFT2_FONT_VECTOR     =  2,
	VFT2_FONT_TRUETYPE   =  3
}

enum : DWORD {
	VFFF_ISSHAREDFILE = 1
}

enum : DWORD {
	VFF_CURNEDEST    = 1,
	VFF_FILEINUSE    = 2,
	VFF_BUFFTOOSMALL = 4
}

enum : DWORD {
	VIFF_FORCEINSTALL  = 1,
	VIFF_DONTDELETEOLD
}

enum {
	VIF_TEMPFILE         = 0x00001,
	VIF_MISMATCH         = 0x00002,
	VIF_SRCOLD           = 0x00004,
	VIF_DIFFLANG         = 0x00008,
	VIF_DIFFCODEPG       = 0x00010,
	VIF_DIFFTYPE         = 0x00020,
	VIF_WRITEPROT        = 0x00040,
	VIF_FILEINUSE        = 0x00080,
	VIF_OUTOFSPACE       = 0x00100,
	VIF_ACCESSVIOLATION  = 0x00200,
	VIF_SHARINGVIOLATION = 0x00400,
	VIF_CANNOTCREATE     = 0x00800,
	VIF_CANNOTDELETE     = 0x01000,
	VIF_CANNOTRENAME     = 0x02000,
	VIF_CANNOTDELETECUR  = 0x04000,
	VIF_OUTOFMEMORY      = 0x08000,
	VIF_CANNOTREADSRC    = 0x10000,
	VIF_CANNOTREADDST    = 0x20000,
	VIF_BUFFTOOSMALL     = 0x40000
}

struct VS_FIXEDFILEINFO {
	DWORD dwSignature;
	DWORD dwStrucVersion;
	DWORD dwFileVersionMS;
	DWORD dwFileVersionLS;
	DWORD dwProductVersionMS;
	DWORD dwProductVersionLS;
	DWORD dwFileFlagsMask;
	DWORD dwFileFlags;
	DWORD dwFileOS;
	DWORD dwFileType;
	DWORD dwFileSubtype;
	DWORD dwFileDateMS;
	DWORD dwFileDateLS;
}

extern (Windows) {
	DWORD VerFindFileA(DWORD, LPCSTR, LPCSTR, LPCSTR, LPSTR, PUINT, LPSTR,
	  PUINT);
	DWORD VerFindFileW(DWORD, LPCWSTR, LPCWSTR, LPCWSTR, LPWSTR, PUINT, LPWSTR,
	  PUINT);
	DWORD VerInstallFileA(DWORD, LPCSTR, LPCSTR, LPCSTR, LPCSTR, LPCSTR, LPSTR,
	  PUINT);
	DWORD VerInstallFileW(DWORD, LPCWSTR, LPCWSTR, LPCWSTR, LPCWSTR, LPCWSTR,
	  LPWSTR, PUINT);
	DWORD GetFileVersionInfoSizeA(LPCSTR, PDWORD);
	DWORD GetFileVersionInfoSizeW(LPCWSTR, PDWORD);
	BOOL GetFileVersionInfoA(LPCSTR, DWORD, DWORD, PVOID);
	BOOL GetFileVersionInfoW(LPCWSTR, DWORD, DWORD, PVOID);
	DWORD VerLanguageNameA(DWORD, LPSTR, DWORD);
	DWORD VerLanguageNameW(DWORD, LPWSTR, DWORD);
	BOOL VerQueryValueA(LPCVOID, LPCSTR, LPVOID*, PUINT);
	BOOL VerQueryValueW(LPCVOID, LPCWSTR, LPVOID*, PUINT);
}

version (Unicode) {
	alias VerFindFileW VerFindFile;
	alias VerQueryValueW VerQueryValue;
	alias VerInstallFileW VerInstallFile;
	alias GetFileVersionInfoSizeW GetFileVersionInfoSize;
	alias GetFileVersionInfoW GetFileVersionInfo;
	alias VerLanguageNameW VerLanguageName;
	alias VerQueryValueW VerQueryValue;
} else {
	alias VerQueryValueA VerQueryValue;
	alias VerFindFileA VerFindFile;
	alias VerInstallFileA VerInstallFile;
	alias GetFileVersionInfoSizeA GetFileVersionInfoSize;
	alias GetFileVersionInfoA GetFileVersionInfo;
	alias VerLanguageNameA VerLanguageName;
	alias VerQueryValueA VerQueryValue;
}
