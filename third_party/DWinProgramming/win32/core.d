/***********************************************************************\
*                                core.d                                 *
*                                                                       *
*                    Helper module for the Windows API                  *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.core;

/**
 The core Windows API functions.

 Importing this file is equivalent to the C code:
 ---
 #define WIN32_LEAN_AND_MEAN
 #include "windows.h"
 ---

*/

public import win32.windef;
public import win32.winnt;
public import win32.wincon;
public import win32.winbase;
public import win32.wingdi;
public import win32.winuser;
public import win32.winnls;
public import win32.winver;
public import win32.winnetwk;

// We can't use static if for imports, build gets confused.
// static if (_WIN32_WINNT_ONLY) import win32.winsvc;
version (WindowsVista) {
	version = WIN32_WINNT_ONLY;
} else version (Windows2003) {
	version = WIN32_WINNT_ONLY;
} else version (WindowsXP) {
	version = WIN32_WINNT_ONLY;
} else version (WindowsNTonly) {
	version = WIN32_WINNT_ONLY;
}

version (WIN32_WINNT_ONLY) {
	public import win32.winsvc;
}
