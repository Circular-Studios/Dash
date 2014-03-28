/***********************************************************************\
*                               rassapi.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.rassapi;

private import win32.lmcons, win32.windef;

// FIXME: check types of constants

const size_t
	RASSAPI_MAX_PHONENUMBER_SIZE = 128,
	RASSAPI_MAX_MEDIA_NAME	     =  16,
	RASSAPI_MAX_PORT_NAME	     =  16,
	RASSAPI_MAX_DEVICE_NAME      = 128,
	RASSAPI_MAX_DEVICETYPE_NAME  =  16,
	RASSAPI_MAX_PARAM_KEY_SIZE   =  32;

const RASPRIV_NoCallback        = 0x01;
const RASPRIV_AdminSetCallback  = 0x02;
const RASPRIV_CallerSetCallback = 0x04;
const RASPRIV_DialinPrivilege   = 0x08;
const RASPRIV_CallbackType      = 0x07;

enum {
	RAS_MODEM_OPERATIONAL = 1,
	RAS_MODEM_NOT_RESPONDING,
	RAS_MODEM_HARDWARE_FAILURE,
	RAS_MODEM_INCORRECT_RESPONSE,
	RAS_MODEM_UNKNOWN  // = 5
}

enum {
	RAS_PORT_NON_OPERATIONAL = 1,
	RAS_PORT_DISCONNECTED,
	RAS_PORT_CALLING_BACK,
	RAS_PORT_LISTENING,
	RAS_PORT_AUTHENTICATING,
	RAS_PORT_AUTHENTICATED,
	RAS_PORT_INITIALIZING // = 7
}

enum {
	MEDIA_UNKNOWN,
	MEDIA_SERIAL,
	MEDIA_RAS10_SERIAL,
	MEDIA_X25,
	MEDIA_ISDN
}

const USER_AUTHENTICATED = 0x0001;
const MESSENGER_PRESENT  = 0x0002;
const PPP_CLIENT         = 0x0004;
const GATEWAY_ACTIVE     = 0x0008;
const REMOTE_LISTEN      = 0x0010;
const PORT_MULTILINKED   = 0x0020;

const size_t
	RAS_IPADDRESSLEN  = 15,
	RAS_IPXADDRESSLEN = 22,
	RAS_ATADDRESSLEN  = 32;

// FIXME: should these be grouped together?
enum {
	RASDOWNLEVEL     = 10,
	RASADMIN_35      = 35,
	RASADMIN_CURRENT = 40
}

alias ULONG IPADDR;

enum RAS_PARAMS_FORMAT {
    ParamNumber = 0,
    ParamString
}

union RAS_PARAMS_VALUE {
	DWORD Number;
	struct _String {
		DWORD Length;
		PCHAR Data;
	}
	_String String;
}

struct RAS_PARAMETERS {
	CHAR[RASSAPI_MAX_PARAM_KEY_SIZE] P_Key;
	RAS_PARAMS_FORMAT                P_Type;
	BYTE                             P_Attributes;
	RAS_PARAMS_VALUE                 P_Value;
}

struct RAS_USER_0 {
	BYTE                                    bfPrivilege;
	WCHAR[RASSAPI_MAX_PHONENUMBER_SIZE + 1] szPhoneNumber;
}
alias RAS_USER_0* PRAS_USER_0;

struct RAS_PORT_0 {
	WCHAR[RASSAPI_MAX_PORT_NAME]       wszPortName;
	WCHAR[RASSAPI_MAX_DEVICETYPE_NAME] wszDeviceType;
	WCHAR[RASSAPI_MAX_DEVICE_NAME]     wszDeviceName;
	WCHAR[RASSAPI_MAX_MEDIA_NAME]      wszMediaName;
	DWORD                              reserved;
	DWORD                              Flags;
	WCHAR[UNLEN + 1]                   wszUserName;
	WCHAR[NETBIOS_NAME_LEN]            wszComputer;
	DWORD                              dwStartSessionTime; // seconds from 1/1/1970
	WCHAR[DNLEN + 1]                   wszLogonDomain;
	BOOL                               fAdvancedServer;
}
alias RAS_PORT_0* PRAS_PORT_0;

struct RAS_PPP_NBFCP_RESULT {
	DWORD dwError;
	DWORD dwNetBiosError;
	CHAR[NETBIOS_NAME_LEN + 1]  szName;
	WCHAR[NETBIOS_NAME_LEN + 1] wszWksta;
}

struct RAS_PPP_IPCP_RESULT {
	DWORD dwError;
	WCHAR[RAS_IPADDRESSLEN + 1] wszAddress;
}

struct RAS_PPP_IPXCP_RESULT {
	DWORD dwError;
	WCHAR[RAS_IPXADDRESSLEN + 1] wszAddress;
}

struct RAS_PPP_ATCP_RESULT {
	DWORD dwError;
	WCHAR[RAS_ATADDRESSLEN + 1] wszAddress;
}

struct RAS_PPP_PROJECTION_RESULT {
	RAS_PPP_NBFCP_RESULT nbf;
	RAS_PPP_IPCP_RESULT  ip;
	RAS_PPP_IPXCP_RESULT ipx;
	RAS_PPP_ATCP_RESULT  at;
}

struct RAS_PORT_1 {
	RAS_PORT_0 rasport0;
	DWORD      LineCondition;
	DWORD      HardwareCondition;
	DWORD      LineSpeed;
	WORD       NumStatistics;
	WORD       NumMediaParms;
	DWORD      SizeMediaParms;
	RAS_PPP_PROJECTION_RESULT ProjResult;
}
alias RAS_PORT_1* PRAS_PORT_1;

struct RAS_PORT_STATISTICS {
	DWORD dwBytesXmited;
	DWORD dwBytesRcved;
	DWORD dwFramesXmited;
	DWORD dwFramesRcved;
	DWORD dwCrcErr;
	DWORD dwTimeoutErr;
	DWORD dwAlignmentErr;
	DWORD dwHardwareOverrunErr;
	DWORD dwFramingErr;
	DWORD dwBufferOverrunErr;
	DWORD dwBytesXmitedUncompressed;
	DWORD dwBytesRcvedUncompressed;
	DWORD dwBytesXmitedCompressed;
	DWORD dwBytesRcvedCompressed;
	DWORD dwPortBytesXmited;
	DWORD dwPortBytesRcved;
	DWORD dwPortFramesXmited;
	DWORD dwPortFramesRcved;
	DWORD dwPortCrcErr;
	DWORD dwPortTimeoutErr;
	DWORD dwPortAlignmentErr;
	DWORD dwPortHardwareOverrunErr;
	DWORD dwPortFramingErr;
	DWORD dwPortBufferOverrunErr;
	DWORD dwPortBytesXmitedUncompressed;
	DWORD dwPortBytesRcvedUncompressed;
	DWORD dwPortBytesXmitedCompressed;
	DWORD dwPortBytesRcvedCompressed;
}
alias RAS_PORT_STATISTICS* PRAS_PORT_STATISTICS;

struct RAS_SERVER_0 {
	WORD TotalPorts;
	WORD PortsInUse;
	DWORD RasVersion;
}
alias RAS_SERVER_0* PRAS_SERVER_0;

extern (Windows) {
	DWORD RasAdminServerGetInfo(CPtr!(WCHAR), PRAS_SERVER_0);
	DWORD RasAdminGetUserAccountServer(CPtr!(WCHAR), CPtr!(WCHAR), LPWSTR);
	DWORD RasAdminUserGetInfo(CPtr!(WCHAR), CPtr!(WCHAR), PRAS_USER_0);
	DWORD RasAdminUserSetInfo(CPtr!(WCHAR), CPtr!(WCHAR), PRAS_USER_0);
	DWORD RasAdminPortEnum(WCHAR*, PRAS_PORT_0*, WORD*);
	DWORD RasAdminPortGetInfo(CPtr!(WCHAR), CPtr!(WCHAR), RAS_PORT_1*,
	 RAS_PORT_STATISTICS*, RAS_PARAMETERS**);
	DWORD RasAdminPortClearStatistics(CPtr!(WCHAR), CPtr!(WCHAR));
	DWORD RasAdminPortDisconnect(CPtr!(WCHAR), CPtr!(WCHAR));
	DWORD RasAdminFreeBuffer(PVOID);
	DWORD RasAdminGetErrorString(UINT, WCHAR*, DWORD);
	BOOL RasAdminAcceptNewConnection(RAS_PORT_1*, RAS_PORT_STATISTICS*,
	 RAS_PARAMETERS*);
	VOID RasAdminConnectionHangupNotification(RAS_PORT_1*,
	  RAS_PORT_STATISTICS*, RAS_PARAMETERS*);
	DWORD RasAdminGetIpAddressForUser (WCHAR*, WCHAR*, IPADDR*, BOOL*);
	VOID RasAdminReleaseIpAddress (WCHAR*, WCHAR*,IPADDR*);
	DWORD RasAdminGetUserParms(WCHAR*, PRAS_USER_0);
	DWORD RasAdminSetUserParms(WCHAR*, DWORD, PRAS_USER_0);
}
