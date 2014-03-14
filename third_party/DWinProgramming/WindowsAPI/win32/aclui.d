/***********************************************************************\
*                                aclui.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*             Translated from MinGW API for MS-Windows 3.10             *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.aclui;
pragma(lib, "aclui.lib");

private import win32.w32api;

static assert (_WIN32_WINNT_ONLY && _WIN32_WINNT >= 0x500,
	"win32.aclui is available only if version WindowsXP, Windows2003 "
	"or WindowsVista is set, or both Windows2000 and WindowsNTonly are set");

import win32.accctrl, win32.commctrl, win32.objbase;
private import win32.basetyps, win32.prsht, win32.unknwn, win32.windef,
  win32.winuser;


struct SI_OBJECT_INFO {
	DWORD     dwFlags;
	HINSTANCE hInstance;
	LPWSTR    pszServerName;
	LPWSTR    pszObjectName;
	LPWSTR    pszPageTitle;
	GUID      guidObjectType;
}
alias SI_OBJECT_INFO* PSI_OBJECT_INFO;

// values for SI_OBJECT_INFO.dwFlags
const DWORD
	SI_EDIT_PERMS               = 0x00000000,
	SI_EDIT_OWNER               = 0x00000001,
	SI_EDIT_AUDITS              = 0x00000002,
	SI_CONTAINER                = 0x00000004,
	SI_READONLY                 = 0x00000008,
	SI_ADVANCED                 = 0x00000010,
	SI_RESET                    = 0x00000020,
	SI_OWNER_READONLY           = 0x00000040,
	SI_EDIT_PROPERTIES          = 0x00000080,
	SI_OWNER_RECURSE            = 0x00000100,
	SI_NO_ACL_PROTECT           = 0x00000200,
	SI_NO_TREE_APPLY            = 0x00000400,
	SI_PAGE_TITLE               = 0x00000800,
	SI_SERVER_IS_DC             = 0x00001000,
	SI_RESET_DACL_TREE          = 0x00004000,
	SI_RESET_SACL_TREE          = 0x00008000,
	SI_OBJECT_GUID              = 0x00010000,
	SI_EDIT_EFFECTIVE           = 0x00020000,
	SI_RESET_DACL               = 0x00040000,
	SI_RESET_SACL               = 0x00080000,
	SI_RESET_OWNER              = 0x00100000,
	SI_NO_ADDITIONAL_PERMISSION = 0x00200000,
	SI_MAY_WRITE                = 0x10000000,
	SI_EDIT_ALL                 = SI_EDIT_PERMS | SI_EDIT_OWNER
	                              | SI_EDIT_AUDITS;

struct SI_ACCESS {
	CPtr!(GUID) pguid;
	ACCESS_MASK mask;
	LPCWSTR     pszName;
	DWORD       dwFlags;
}
alias SI_ACCESS* PSI_ACCESS;

// values for SI_ACCESS.dwFlags
const DWORD
	SI_ACCESS_SPECIFIC  = 0x00010000,
	SI_ACCESS_GENERAL   = 0x00020000,
	SI_ACCESS_CONTAINER = 0x00040000,
	SI_ACCESS_PROPERTY  = 0x00080000;


struct SI_INHERIT_TYPE {
	CPtr!(GUID) pguid;
	ULONG       dwFlags;
	LPCWSTR     pszName;
}
alias SI_INHERIT_TYPE* PSI_INHERIT_TYPE;

/* values for SI_INHERIT_TYPE.dwFlags
   INHERIT_ONLY_ACE, CONTAINER_INHERIT_ACE, OBJECT_INHERIT_ACE
   defined elsewhere */

enum SI_PAGE_TYPE {
	SI_PAGE_PERM,
	SI_PAGE_ADVPERM,
	SI_PAGE_AUDIT,
	SI_PAGE_OWNER
}

const uint PSPCB_SI_INITDIALOG = WM_USER + 1;

interface ISecurityInformation : IUnknown {
	HRESULT GetObjectInformation(PSI_OBJECT_INFO);
	HRESULT GetSecurity(SECURITY_INFORMATION, PSECURITY_DESCRIPTOR*, BOOL);
	HRESULT SetSecurity(SECURITY_INFORMATION, PSECURITY_DESCRIPTOR);
	HRESULT GetAccessRights(CPtr!(GUID), DWORD, PSI_ACCESS*, ULONG*, ULONG*);
	HRESULT MapGeneric(CPtr!(GUID), UCHAR*, ACCESS_MASK*);
	HRESULT GetInheritTypes(PSI_INHERIT_TYPE*, ULONG*);
	HRESULT PropertySheetPageCallback(HWND, UINT, SI_PAGE_TYPE);
}
alias ISecurityInformation* LPSECURITYINFO;

/* Comment from MinGW
 * TODO: ISecurityInformation2, IEffectivePermission, ISecurityObjectTypeInfo
 */

// FIXME: linkage attribute?
extern (C) /+DECLSPEC_IMPORT+/ extern const IID IID_ISecurityInformation;

extern (Windows) {
	HPROPSHEETPAGE CreateSecurityPage(LPSECURITYINFO psi);
	BOOL EditSecurity(HWND hwndOwner, LPSECURITYINFO psi);
}
