/***********************************************************************\
*                                ntdll.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*             Translated from MinGW API for MS-Windows 3.10             *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.ntdll;

private import win32.w32api;

// http://www.matcode.com/undocwin.h.txt
static assert (_WIN32_WINNT_ONLY,
	"win32.ntdll is available only if version WindowsNTonly, WindowsXP, "
	"Windows2003 or WindowsVista is set");


enum SHUTDOWN_ACTION {
	ShutdownNoReboot,
	ShutdownReboot,
	ShutdownPowerOff
}

extern (Windows) uint NtShutdownSystem(SHUTDOWN_ACTION Action);
