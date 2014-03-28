/***********************************************************************\
*                               lmalert.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.lmalert;
pragma(lib, "netapi32.lib");

private import win32.lmcons, win32.windef;

const TCHAR[]
	ALERTER_MAILSLOT     = `\\.\MAILSLOT\Alerter`,
	ALERT_PRINT_EVENT    = "PRINTING",
	ALERT_MESSAGE_EVENT  = "MESSAGE",
	ALERT_ERRORLOG_EVENT = "ERRORLOG",
	ALERT_ADMIN_EVENT    = "ADMIN",
	ALERT_USER_EVENT     = "USER";
//MACRO #define ALERT_OTHER_INFO(x) ((PBYTE)(x)+sizeof(STD_ALERT))

//MACRO #define ALERT_VAR_DATA(p) ((PBYTE)(p)+sizeof(*p))

const PRJOB_QSTATUS     = 3;
const PRJOB_DEVSTATUS   = 508;
const PRJOB_COMPLETE    = 4;
const PRJOB_INTERV      = 8;
const PRJOB_            = 16;
const PRJOB_DESTOFFLINE = 32;
const PRJOB_DESTPAUSED  = 64;
const PRJOB_NOTIFY      = 128;
const PRJOB_DESTNOPAPER = 256;
const PRJOB_DELETED     = 32768;
const PRJOB_QS_QUEUED   = 0;
const PRJOB_QS_PAUSED   = 1;
const PRJOB_QS_SPOOLING = 2;
const PRJOB_QS_PRINTING = 3;

struct ADMIN_OTHER_INFO{
	DWORD alrtad_errcode;
	DWORD alrtad_numstrings;
}
alias ADMIN_OTHER_INFO* PADMIN_OTHER_INFO, LPADMIN_OTHER_INFO;

struct STD_ALERT{
	DWORD alrt_timestamp;
	TCHAR alrt_eventname[EVLEN+1];
	TCHAR alrt_servicename[SNLEN+1];
}
alias STD_ALERT* PSTD_ALERT, LPSTD_ALERT;

struct ERRLOG_OTHER_INFO{
	DWORD alrter_errcode;
	DWORD alrter_offset;
}
alias ERRLOG_OTHER_INFO* PERRLOG_OTHER_INFO, LPERRLOG_OTHER_INFO;

struct PRINT_OTHER_INFO{
	DWORD alrtpr_jobid;
	DWORD alrtpr_status;
	DWORD alrtpr_submitted;
	DWORD alrtpr_size;
}
alias PRINT_OTHER_INFO* PPRINT_OTHER_INFO, LPPRINT_OTHER_INFO;

struct USER_OTHER_INFO{
	DWORD alrtus_errcode;
	DWORD alrtus_numstrings;
}
alias USER_OTHER_INFO* PUSER_OTHER_INFO, LPUSER_OTHER_INFO;

extern (Windows) {
NET_API_STATUS NetAlertRaise(LPCWSTR,PVOID,DWORD);
NET_API_STATUS NetAlertRaiseEx(LPCWSTR,PVOID,DWORD,LPCWSTR);
}
