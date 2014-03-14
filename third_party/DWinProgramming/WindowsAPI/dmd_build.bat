@echo off
setlocal EnableDelayedExpansion
set "files="
for %%i in (win32\*.d) do set files=!files! %%i
dmd -I. -version=Unicode -version=WindowsXP -lib -ofdmd_win32_x32.lib %files%
