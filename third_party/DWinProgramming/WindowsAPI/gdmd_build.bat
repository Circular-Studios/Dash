@echo off
setlocal EnableDelayedExpansion
set "files="
for %%i in (win32\*.d) do set files=!files! %%i
gdmd -m32 -ignore -I. -version=Unicode -version=WindowsXP -lib -ofgdc_win32_x32.lib %files%
