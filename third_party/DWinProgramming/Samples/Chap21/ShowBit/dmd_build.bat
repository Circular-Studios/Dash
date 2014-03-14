@echo off
dmd -ofBitLib.dll -I..\..\..\WindowsAPI ..\..\..\dmd_win32.lib -I. -version=Unicode -version=WindowsXP BitLib.d BitLib.res %*
dmd -ofShowBit.exe -I..\..\..\WindowsAPI ..\..\..\dmd_win32.lib -I. -version=Unicode -version=WindowsXP ShowBit.d %*
