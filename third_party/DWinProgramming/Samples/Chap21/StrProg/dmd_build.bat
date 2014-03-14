@echo off
dmd -H -ofStrLib.dll -L/IMPLIB -I..\..\..\WindowsAPI ..\..\..\dmd_win32.lib -I. -version=Unicode -version=WindowsXP StrLib.d dllmodule.d %*

dmd -ofStrProg.exe -I..\..\..\WindowsAPI ..\..\..\dmd_win32.lib -I. -version=Unicode -version=WindowsXP StrProg.d StrLib.lib StrProg.res %*
