@echo off
setlocal EnableDelayedExpansion
FOR /F "tokens=*" %%i in ('where gdc') do SET gdc=true
FOR /F "tokens=*" %%i in ('where dmd') do SET dmd=true

if defined gdc (
set "compile=gdmd -IWindowsAPI -m32 -version=Unicode -version=WindowsXP build.d gdc_win32.lib -ofbuild.exe"
)

if defined dmd (
set "compile=dmd -IWindowsAPI -m32 -version=Unicode -version=WindowsXP build.d dmd_win32.lib -ofbuild.exe"
)

%compile%
