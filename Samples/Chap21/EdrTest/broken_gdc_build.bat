@echo off
gdc -v2 -mwindows -I..\..\..\ -fversion=Unicode -fversion=WindowsXP -shared -o mydll.dll mydll.d EdrLib.d -Wl,--out-implib,implibmydll.a
gdc -v2 -fintfc -fsyntax-only -H mydll.d

:: ~ Note: broken:
:: ~ gdc -v2 -mwindows -I..\..\..\ -L-L"%CD%" -Wl,%CD%\gdc_win32.a -fversion=Unicode -fversion=WindowsXP -o EdrTest.exe EdrTest.d implibmydll.a
