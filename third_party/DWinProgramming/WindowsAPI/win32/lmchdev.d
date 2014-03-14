/***********************************************************************\
*                               lmchdev.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.lmchdev;

// COMMENT: This file might be deprecated.

private import win32.lmcons, win32.windef;

const CHARDEVQ_NO_REQUESTS  = -1;
const CHARDEV_CLOSE         = 0;
const CHARDEVQ_MAX_PRIORITY = 1;
const CHARDEVQ_DEV_PARMNUM  = 1;

const HANDLE_INFO_LEVEL_1 = 1;
const HANDLE_CHARTIME_PARMNUM = 1;
const HANDLE_CHARCOUNT_PARMNUM = 2;

const CHARDEV_STAT_OPENED = 2;
const CHARDEVQ_PRIORITY_PARMNUM = 2;
const CHARDEVQ_DEVS_PARMNUM = 3;
const CHARDEV_STAT_ERROR = 4;
const CHARDEVQ_NUMUSERS_PARMNUM = 4;
const CHARDEVQ_NUMAHEAD_PARMNUM = 5;
const CHARDEVQ_DEF_PRIORITY = 5;
const CHARDEVQ_PRIORITY_INFOLEVEL = PARMNUM_BASE_INFOLEVEL+CHARDEVQ_PRIORITY_PARMNUM;
const CHARDEVQ_DEVS_INFOLEVEL = PARMNUM_BASE_INFOLEVEL+CHARDEVQ_DEVS_PARMNUM;
const CHARDEVQ_MIN_PRIORITY = 9;

struct CHARDEV_INFO_0 {
 LPWSTR ch0_dev;
}
alias CHARDEV_INFO_0* PCHARDEV_INFO_0, LPCHARDEV_INFO_0;

struct CHARDEV_INFO_1{
	LPWSTR ch1_dev;
	DWORD ch1_status;
	LPWSTR ch1_username;
	DWORD ch1_time;
}
alias CHARDEV_INFO_1* PCHARDEV_INFO_1, LPCHARDEV_INFO_1;

struct CHARDEVQ_INFO_0 {
 LPWSTR cq0_dev;
}
alias CHARDEVQ_INFO_0* PCHARDEVQ_INFO_0, LPCHARDEVQ_INFO_0;

struct CHARDEVQ_INFO_1{
	LPWSTR cq1_dev;
	DWORD cq1_priority;
	LPWSTR cq1_devs;
	DWORD cq1_numusers;
	DWORD cq1_numahead;
}
alias CHARDEVQ_INFO_1* PCHARDEVQ_INFO_1, LPCHARDEVQ_INFO_1;

struct CHARDEVQ_INFO_1002 {
	DWORD cq1002_priority;
}
alias CHARDEVQ_INFO_1002* PCHARDEVQ_INFO_1002, LPCHARDEVQ_INFO_1002;

struct CHARDEVQ_INFO_1003 {
	LPWSTR cq1003_devs;
}
alias CHARDEVQ_INFO_1003* PCHARDEVQ_INFO_1003, LPCHARDEVQ_INFO_1003;

struct HANDLE_INFO_1{
	DWORD hdli1_chartime;
	DWORD hdli1_charcount;
}
alias HANDLE_INFO_1* PHANDLE_INFO_1, LPHANDLE_INFO_1;

extern (Windows) {
	NET_API_STATUS NetCharDevEnum(LPCWSTR, DWORD, PBYTE*, DWORD, PDWORD, PDWORD, PDWORD);
	NET_API_STATUS NetCharDevGetInfo(LPCWSTR, LPCWSTR, DWORD, PBYTE*);
	NET_API_STATUS NetCharDevControl(LPCWSTR, LPCWSTR, DWORD);
	NET_API_STATUS NetCharDevQEnum(LPCWSTR, LPCWSTR, DWORD, PBYTE*, DWORD, PDWORD, PDWORD, PDWORD);
	NET_API_STATUS NetCharDevQGetInfo(LPCWSTR, LPCWSTR, LPCWSTR, DWORD, PBYTE*);
	NET_API_STATUS NetCharDevQSetInfo(LPCWSTR, LPCWSTR, DWORD, PBYTE, PDWORD);
	NET_API_STATUS NetCharDevQPurge(LPCWSTR, LPCWSTR);
	NET_API_STATUS NetCharDevQPurgeSelf(LPCWSTR, LPCWSTR, LPCWSTR);
	NET_API_STATUS NetHandleGetInfo(HANDLE, DWORD, PBYTE*);
	NET_API_STATUS NetHandleSetInfo(HANDLE, DWORD, PBYTE, DWORD, PDWORD);
}
