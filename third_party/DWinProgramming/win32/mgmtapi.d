/***********************************************************************\
*                                mgmtapi.d                              *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.mgmtapi;

import win32.snmp;
private import win32.windef;

enum {
	SNMP_MGMTAPI_TIMEOUT = 40,
	SNMP_MGMTAPI_SELECT_FDERRORS,
	SNMP_MGMTAPI_TRAP_ERRORS,
	SNMP_MGMTAPI_TRAP_DUPINIT,
	SNMP_MGMTAPI_NOTRAPS,
	SNMP_MGMTAPI_AGAIN,
	SNMP_MGMTAPI_INVALID_CTL,
	SNMP_MGMTAPI_INVALID_SESSION,
	SNMP_MGMTAPI_INVALID_BUFFER // = 48
}

const MGMCTL_SETAGENTPORT = 1;

alias PVOID LPSNMP_MGR_SESSION;

extern (Windows) {
	BOOL SnmpMgrClose(LPSNMP_MGR_SESSION);
	BOOL SnmpMgrCtl(LPSNMP_MGR_SESSION, DWORD, LPVOID, DWORD, LPVOID, DWORD,
	  LPDWORD);
	BOOL SnmpMgrGetTrap(AsnObjectIdentifier*, AsnNetworkAddress*,
	  AsnInteger*, AsnInteger*, AsnTimeticks*, SnmpVarBindList*);
	BOOL SnmpMgrGetTrapEx(AsnObjectIdentifier*, AsnNetworkAddress*,
	  AsnNetworkAddress*, AsnInteger*, AsnInteger*, AsnOctetString*,
	  AsnTimeticks*, SnmpVarBindList*);
	BOOL SnmpMgrOidToStr(AsnObjectIdentifier*, LPSTR*);
	LPSNMP_MGR_SESSION SnmpMgrOpen(LPSTR, LPSTR, INT, INT);
	INT SnmpMgrRequest(LPSNMP_MGR_SESSION, BYTE, SnmpVarBindList*,
	  AsnInteger*, AsnInteger*);
	BOOL SnmpMgrStrToOid(LPSTR, AsnObjectIdentifier*);
	BOOL SnmpMgrTrapListen(HANDLE*);
}
