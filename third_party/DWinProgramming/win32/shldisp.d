/***********************************************************************\
*                               shldisp.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.shldisp;

private import win32.unknwn, win32.windef, win32.wtypes;

// options for IAutoComplete2
const DWORD ACO_AUTOSUGGEST = 0x01;

interface IAutoComplete : IUnknown {
	HRESULT Init(HWND, IUnknown*, LPCOLESTR, LPCOLESTR);
	HRESULT Enable(BOOL);
}
alias IAutoComplete* LPAUTOCOMPLETE;

interface IAutoComplete2 : IAutoComplete {
	HRESULT SetOptions(DWORD);
	HRESULT GetOptions(DWORD*);
}
alias IAutoComplete2* LPAUTOCOMPLETE2;
