/***********************************************************************\
*                               custcntl.d                              *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.custcntl;

private import win32.windef;

// FIXME: check type
const CCF_NOTEXT = 1;

const size_t
	CCHCCCLASS =  32,
	CCHCCDESC  =  32,
	CCHCCTEXT  = 256;

struct CCSTYLEA {
	DWORD           flStyle;
	DWORD           flExtStyle;
	CHAR[CCHCCTEXT] szText;
	LANGID          lgid;
	WORD            wReserved1;
}
alias CCSTYLEA* LPCCSTYLEA;

struct CCSTYLEW {
	DWORD            flStyle;
	DWORD            flExtStyle;
	WCHAR[CCHCCTEXT] szText;
	LANGID           lgid;
	WORD             wReserved1;
}
alias CCSTYLEW* LPCCSTYLEW;

struct CCSTYLEFLAGA {
	DWORD flStyle;
	DWORD flStyleMask;
	LPSTR pszStyle;
}
alias CCSTYLEFLAGA* LPCCSTYLEFLAGA;

struct CCSTYLEFLAGW {
	DWORD  flStyle;
	DWORD  flStyleMask;
	LPWSTR pszStyle;
}
alias CCSTYLEFLAGW* LPCCSTYLEFLAGW;

struct CCINFOA {
	CHAR[CCHCCCLASS]  szClass;
	DWORD             flOptions;
	CHAR[CCHCCDESC]   szDesc;
	UINT              cxDefault;
	UINT              cyDefault;
	DWORD             flStyleDefault;
	DWORD             flExtStyleDefault;
	DWORD             flCtrlTypeMask;
	CHAR[CCHCCTEXT]   szTextDefault;
	INT               cStyleFlags;
	LPCCSTYLEFLAGA    aStyleFlags;
	LPFNCCSTYLEA      lpfnStyle;
	LPFNCCSIZETOTEXTA lpfnSizeToText;
	DWORD             dwReserved1;
	DWORD             dwReserved2;
}
alias CCINFOA* LPCCINFOA;

struct CCINFOW {
	WCHAR[CCHCCCLASS] szClass;
	DWORD             flOptions;
	WCHAR[CCHCCDESC]  szDesc;
	UINT              cxDefault;
	UINT              cyDefault;
	DWORD             flStyleDefault;
	DWORD             flExtStyleDefault;
	DWORD             flCtrlTypeMask;
	WCHAR[CCHCCTEXT]  szTextDefault;
	INT               cStyleFlags;
	LPCCSTYLEFLAGW    aStyleFlags;
	LPFNCCSTYLEW      lpfnStyle;
	LPFNCCSIZETOTEXTW lpfnSizeToText;
	DWORD             dwReserved1;
	DWORD             dwReserved2;
}
alias CCINFOW* LPCCINFOW;

extern (Windows) {
	alias BOOL function(HWND, LPCCSTYLEA) LPFNCCSTYLEA;
	alias BOOL function(HWND, LPCCSTYLEW) LPFNCCSTYLEW;
	alias INT function(DWORD, DWORD, HFONT, LPSTR) LPFNCCSIZETOTEXTA;
	alias INT function(DWORD, DWORD, HFONT, LPWSTR) LPFNCCSIZETOTEXTW;
	alias UINT function(LPCCINFOA) LPFNCCINFOA;
	alias UINT function(LPCCINFOW) LPFNCCINFOW;
	UINT CustomControlInfoA(LPCCINFOA acci);
	UINT CustomControlInfoW(LPCCINFOW acci);
}

version (Unicode) {
	alias CCSTYLEW CCSTYLE;
	alias CCSTYLEFLAGW CCSTYLEFLAG;
	alias CCINFOW CCINFO;
	alias LPFNCCSTYLEW LPFNCCSTYLE;
	alias LPFNCCSIZETOTEXTW LPFNCCSIZETOTEXT;
	alias LPFNCCINFOW LPFNCCINFO;
} else {
	alias CCSTYLEA CCSTYLE;
	alias CCSTYLEFLAGA CCSTYLEFLAG;
	alias CCINFOA CCINFO;
	alias LPFNCCSTYLEA LPFNCCSTYLE;
	alias LPFNCCSIZETOTEXTA LPFNCCSIZETOTEXT;
	alias LPFNCCINFOA LPFNCCINFO;
}

alias CCSTYLE* LPCCSTYLE;
alias CCSTYLEFLAG* LPCCSTYLEFLAG;
alias CCINFO* LPCCINFO;
